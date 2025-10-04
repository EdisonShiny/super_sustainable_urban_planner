import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/strings.dart';
import '../../../core/widgets/header_bar.dart';
import '../../../core/widgets/side_panel.dart';
import '../../../core/widgets/emoji_status_badge.dart';
import '../../analytics/chart_series_builder.dart';
import '../../analytics/data_analysis.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/models/access_level.dart';
import '../../profile/presentation/profile_overlay.dart';
import '../data/city_repository.dart';
import '../data/demo_data_store.dart';
import '../data/feedback_repository.dart';
import '../data/indices_repository.dart';
import '../models/city_region.dart';
import '../models/feedback.dart';
import '../models/index_breakdown.dart';
import '../models/index_score.dart';
import '../models/leader_reply.dart';
import '../presentation/overlays/contact_overlay.dart';
import '../presentation/overlays/index_detail_overlay.dart';
import '../presentation/overlays/leader_reply_sheet.dart';
import '../presentation/overlays/resident_feedback_sheet.dart';
import '../presentation/views/graph_view.dart';
import '../presentation/views/map_view.dart';
import '../presentation/views/report_view.dart';
import '../presentation/widgets/city_search_bar.dart';
import '../presentation/widgets/index_summary_grid.dart';
import '../presentation/widgets/top_controls.dart';
import '../../export/report_exporter.dart';
import '../models/index_definitions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _indexPanelWidth = 420;
  static const double _bottomPanelHeight = 420;

  static const Map<indexType, double> _fallbackIndexValues = {
    indexType.usi: 68.0,
    indexType.gci: 62.0,
    indexType.cri: 58.0,
    indexType.hi: 65.0,
  };

  final AuthRepository _authRepository = AuthRepository.instance;
  final CityRepository _cityRepository = CityRepository.instance;
  final IndicesRepository _indicesRepository = IndicesRepository.instance;
  final FeedbackRepository _feedbackRepository = FeedbackRepository.instance;

  final DateFormat _feedbackTimestampFormat = DateFormat('MMM d, yyyy - h:mm a');

  UserProfile? _profile;
  CityRegion? _selectedCity;
  CityRegion? _homeCity;
  CityStatusMood _cityMood = CityStatusMood.stable;
  String _statusLabel = 'Stable Conditions';
  ChartRange _chartRange = ChartRange.month;
  bool _showMap = true;
  bool _isLoading = true;
  String? _error;

  List<IndexScore> _latestScores = const [];
  Map<indexType, List<IndexBreakdown>> _breakdowns = const {};
  List<ChartSeries> _chartSeries = const [];
  List<ReportSection> _reportSections = const [];
  List<FeedbackEntry> _feedbackEntries = const [];
  List<CityRegion> _searchResults = const [];
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      final profile = await _authRepository.fetchCurrentProfile();
      if (!mounted) return;

      final usingDemo = profile == null;
      final effectiveProfile = profile ?? DemoDataStore.instance.demoProfile;

      final city = await _cityRepository.loadDefaultCity(effectiveProfile);
      if (!mounted) return;
      setState(() {
        _profile = effectiveProfile;
        _selectedCity = city;
        _homeCity = city;
        _error = null;
      });

      if (city != null) {
        await _refreshCityData(city, includeInfoMessage: usingDemo);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load dashboard data. Configure Supabase and try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCityData(
    CityRegion city, {
    bool includeInfoMessage = false,
  }) async {
    try {
      var scores = await _indicesRepository.fetchLatestScores(city.id);
      final breakdowns = <indexType, List<IndexBreakdown>>{};
      for (final score in scores) {
        breakdowns[score.type] = await _indicesRepository.fetchBreakdown(
          city.id,
          score.type,
        );
      }

      final fromDate = _resolveStartDate(_chartRange);
      var seriesScores = await _indicesRepository.fetchSeries(city.id, fromDate);
      final feedback = await _feedbackRepository.listFeedback(city.displayName);

      final now = DateTime.now();
      final hadScores = scores.isNotEmpty;
      final hadSeries = seriesScores.isNotEmpty;

      if (!hadScores) {
        scores = _buildZeroScores(now);
      }
      scores = _normalizeScores(scores, now);

      for (final type in indexType.values) {
        breakdowns.putIfAbsent(type, () => const []);
      }

      if (!hadSeries) {
        seriesScores = _buildBaselineSeries(scores, fromDate);
      } else {
        seriesScores = _normalizeSeries(seriesScores, scores, fromDate);
      }

      final chartSeries = ChartSeriesBuilder.build(seriesScores);
      final mood = DataAnalysis.deriveCityMood(scores);
      final statusLabel = DataAnalysis.moodLabel(mood);

      // Build report with the freshly computed mood so report == UI mood
      final sections = _buildReportSections(city, scores, breakdowns, mood);

      final latestTimestamp = scores
          .map((s) => s.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      setState(() {
        _latestScores = scores;
        _breakdowns = breakdowns;
        _chartSeries = chartSeries;
        _cityMood = mood;
        _statusLabel = statusLabel;
        _reportSections = sections;
        _feedbackEntries = feedback;
        _lastUpdated = latestTimestamp;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to refresh city data. Ensure database tables are configured.';
      });
    }
  }

  DateTime _resolveStartDate(ChartRange range) {
    final now = DateTime.now();
    switch (range) {
      case ChartRange.month:
        return now.subtract(const Duration(days: 30));
      case ChartRange.year:
        return now.subtract(const Duration(days: 365));
    }
  }

  /// Uses fresh [mood]; injects USI driver shares when USI lacks breakdown.
  List<ReportSection> _buildReportSections(
    CityRegion city,
    List<IndexScore> scores,
    Map<indexType, List<IndexBreakdown>> breakdowns,
    CityStatusMood mood,
  ) {
    final sections = <ReportSection>[];

    // City Overview
    sections.add(
      ReportSection(
        title: 'City Overview',
        summary: DataAnalysis.buildReportIntro(city.displayName, mood),
      ),
    );

    // Per-index sections
    for (final score in scores) {
      // Use live breakdown; for USI, synthesize drivers if needed
      List<IndexBreakdown> drivers = breakdowns[score.type] ?? const [];
      if (score.type == indexType.usi && drivers.isEmpty) {
        drivers = DataAnalysis.synthesizeUsiBreakdown(scores);
      }

      final insights = DataAnalysis.generateInsights(score, drivers);

      final summary = insights.isNotEmpty
          ? insights.first
          : '${score.type.description} is at ${score.value.toStringAsFixed(0)}%.';

      // Factor advice only for indices that have a definition (GCI/CRI/HI)
      final def = findIndexDefinition(score.type);
      final factorPoints = DataAnalysis.buildFactorAdvicePoints(
        score,
        breakdowns[score.type] ?? const [],
        def,
      );

      final extraPoints = insights.length > 1
          ? insights.skip(1)
          : const Iterable<String>.empty();

      sections.add(
        ReportSection(
          title: score.type.description,
          summary: summary,
          points: [
            ...factorPoints, 
            ...extraPoints, 
          ],
        ),
      );
    }

    return sections;
  }

  Future<void> _handleLogout() async {
    _cityRepository.clearSelection();
    await _authRepository.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _handleProfileEdit() async {
    final profile = _profile;
    if (profile == null) return;

    UserProfile? updatedProfile;
    await ProfileOverlay.show(
      context,
      profile: profile,
      onUpdated: (value) => updatedProfile = value,
    );

    if (!mounted || updatedProfile == null) return;

    _cityRepository.clearSelection();
    final city = await _cityRepository.loadDefaultCity(updatedProfile!);
    if (!mounted) return;

    setState(() {
      _profile = updatedProfile;
      _selectedCity = city;
      _homeCity = city;
    });

    if (city != null) {
      await _refreshCityData(city);
    }
  }

  Future<void> _handleShareConcern() async {
    final profile = _profile;
    final city = _selectedCity;
    if (profile == null || city == null) return;
    if (!_canInteractWithSelectedCity(profile)) {
      _showViewOnlyNotice();
      return;
    }
    await ResidentFeedbackSheet.show(
      context,
      profile: profile,
      cityName: city.displayName,
      onSubmitted: (_) async => _refreshCityData(city),
    );
  }

  Future<void> _handleLeaderReply() async {
    final profile = _profile;
    final city = _selectedCity;
    if (profile == null || city == null) return;
    if (!_canInteractWithSelectedCity(profile)) {
      _showViewOnlyNotice();
      return;
    }
    await LeaderReplySheet.show(
      context,
      leader: profile,
      feedbackEntries: _feedbackEntries,
      onReplyCreated: (_) async => _refreshCityData(city),
    );
  }

  Future<void> _handleIndexTap(indexType type) async {
    final city = _selectedCity;
    if (city == null) return;
    final score = _latestScores.firstWhere((s) => s.type == type);
    final breakdown = _breakdowns[type] ?? const [];
    await IndexDetailOverlay.show(context, score: score, breakdown: breakdown);
  }

  Future<void> _handleExportReport() async {
    final city = _selectedCity;
    if (city == null) return;
    final bytes = await ReportExporter.buildPdf(
      cityName: city.displayName,
      generatedAt: DateTime.now(),
      sections: _reportSections,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'usi_report.pdf');
  }

  Future<void> _handleCityQuery(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    final results = await _cityRepository.searchCities(query);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  Future<void> _handleCitySubmit(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final results = await _cityRepository.searchCities(trimmed);
    if (!mounted) return;
    if (results.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    await _handleCitySelection(results.first);
  }

  Future<void> _handleCitySelection(CityRegion city) async {
    _cityRepository.selectCity(city);
    setState(() {
      _selectedCity = city;
      _searchResults = const [];
    });
    await _refreshCityData(city);
  }

  bool _canInteractWithSelectedCity(UserProfile profile) {
    final selected = _selectedCity;
    final home = _homeCity;
    if (selected == null) return false;
    if (home == null) return true;
    return selected.id == home.id;
  }

  void _showViewOnlyNotice() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Feedback can only be submitted for your profile city.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              onBrandTap: () {
                final city = _selectedCity;
                if (city != null) {
                  _refreshCityData(city);
                }
              },
              onAboutTap: () => context.go('/about'),
              onContactTap: () => ContactOverlay.show(context),
              onProfileTap: _handleProfileEdit,
              onLogoutTap: _handleLogout,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      final theme = Theme.of(context);
      return Center(
        child: Text(
          _error!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    final profile = _profile;
    final city = _selectedCity;
    final homeCity = _homeCity ?? city;
    if (profile == null || city == null || homeCity == null) {
      return const Center(child: Text('No city selected.'));
    }
    final canContribute = _canInteractWithSelectedCity(profile);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1200;

        if (isCompact) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SidePanel(
                  username: profile.username,
                  accessLevelLabel: profile.accessLevel.label,
                  cityRegion: homeCity.displayName,
                  departmentAgencies: profile.departmentAgencies,
                  statusMood: _cityMood,
                  statusLabel: _statusLabel,
                  isCityLeader: profile.isCityLeader,
                  onPrimaryAction: profile.isCityLeader
                      ? (canContribute ? _handleLeaderReply : _showViewOnlyNotice)
                      : (canContribute ? _handleShareConcern : _showViewOnlyNotice),
                ),
                const SizedBox(height: 24),
                _buildTopSection(profile, city),
                const SizedBox(height: 32),
                _buildBottomPanels(profile, isCompact: true),
                const SizedBox(height: 24),
                _buildIndexPanel(),
                const SizedBox(height: 40),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SidePanel(
                      username: profile.username,
                      accessLevelLabel: profile.accessLevel.label,
                      cityRegion: homeCity.displayName,
                      departmentAgencies: profile.departmentAgencies,
                      statusMood: _cityMood,
                      statusLabel: _statusLabel,
                      isCityLeader: profile.isCityLeader,
                      onPrimaryAction: profile.isCityLeader
                          ? (canContribute ? _handleLeaderReply : _showViewOnlyNotice)
                          : (canContribute ? _handleShareConcern : _showViewOnlyNotice),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTopSection(profile, city)),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: _indexPanelWidth,
                      child: _buildIndexPanel(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildBottomPanels(profile, isCompact: false),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSection(UserProfile profile, CityRegion city) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TopControls(
          showMap: _showMap,
          lastUpdated: _lastUpdated,
          onToggle: (value) => setState(() => _showMap = value),
        ),
        const SizedBox(height: 16),
        _buildCitySearchSection(city),
        const SizedBox(height: 24),
        _buildVisualizationCard(city),
      ],
    );
  }

  Widget _buildBottomPanels(UserProfile profile, {required bool isCompact}) {
    final selectedCity = _selectedCity;
    final homeCity = _homeCity;
    final canContribute =
        selectedCity != null && homeCity != null ? selectedCity.id == homeCity.id : true;

    final feedbackPanel = SizedBox(
      height: _bottomPanelHeight,
      child: _buildFeedbackSection(profile, canContribute: canContribute),
    );
    final reportPanel = SizedBox(
      height: _bottomPanelHeight,
      child: ReportView(
        sections: _reportSections,
        onExport: _handleExportReport,
        enableScroll: true,
        maxContentHeight: _bottomPanelHeight - 96,
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [feedbackPanel, const SizedBox(height: 24), reportPanel],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: feedbackPanel),
        const SizedBox(width: 24),
        Expanded(child: reportPanel),
      ],
    );
  }

  Widget _buildCitySearchSection(CityRegion city) {
    const fieldHeight = 56.0;
    final results = _searchResults;
    return SizedBox(
      height: fieldHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CitySearchBar(
              onQueryChanged: _handleCityQuery,
              onSubmitted: _handleCitySubmit,
              initialValue: city.displayName,
            ),
          ),
          if (results.isNotEmpty)
            Positioned(
              top: fieldHeight + 8,
              left: 0,
              right: 0,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        title: Text(result.displayName),
                        subtitle: Text(
                          [result.region, result.country]
                              .whereType<String>()
                              .where((value) => value.isNotEmpty)
                              .join(', '),
                        ),
                        onTap: () => _handleCitySelection(result),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVisualizationCard(CityRegion city) {
    if (_showMap) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: MapView(city: city, mood: _cityMood),
      );
    }

    return GraphView(
      key: ValueKey('graph-${city.id}-${_chartRange.name}'),
      series: _chartSeries,
      range: _chartRange,
      onRangeChanged: (value) async {
        setState(() => _chartRange = value);
        final selectedCity = _selectedCity;
        if (selectedCity != null) await _refreshCityData(selectedCity);
      },
    );
  }

  Widget _buildIndexPanel() {
    if (_latestScores.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No index data available yet. Once Supabase tables are populated, live analytics will appear here.',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Index Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          IndexSummaryGrid(
            scores: _latestScores,
            breakdowns: _breakdowns,
            onIndexTap: _handleIndexTap,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(
    UserProfile profile, {
    required bool canContribute,
  }) {
    final entries = _visibleFeedbackEntries(profile);
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.feedbackFeedTitle, style: titleStyle),
              if (!canContribute)
                Tooltip(
                  message: 'Feedback can only be submitted for your profile city.',
                  child: Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
            ],
          ),
          if (!canContribute) ...[
            const SizedBox(height: 12),
            Text(
              'Viewing feedback only. Switch back to your profile city to participate.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: entries.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: canContribute
                        ? Text(
                            profile.isCityLeader ? AppStrings.feedbackEmptyLeader : AppStrings.feedbackEmptyResident,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          )
                        : const SizedBox.shrink(),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _FeedbackEntryCard(
                        entry: entries[index],
                        dateFormat: _feedbackTimestampFormat,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<FeedbackEntry> _visibleFeedbackEntries(UserProfile profile) {
    if (profile.isCityLeader) return _feedbackEntries;
    //return _feedbackEntries.where((e) => e.userId == profile.id).toList();
    return _feedbackEntries;
  }

  List<IndexScore> _buildZeroScores(DateTime timestamp) {
    return indexType.values
        .map((type) => IndexScore(
              type: type,
              value: _fallbackIndexValues[type] ?? 60,
              timestamp: timestamp,
            ))
        .toList();
  }

  List<IndexScore> _normalizeScores(
    List<IndexScore> scores,
    DateTime fallbackTimestamp,
  ) {
    final byType = <indexType, IndexScore>{};
    for (final score in scores) {
      byType[score.type] = score;
    }

    return indexType.values
        .map(
          (type) => byType[type] ??
              IndexScore(
                type: type,
                value: _fallbackIndexValues[type] ?? 60,
                timestamp: fallbackTimestamp,
              ),
        )
        .toList();
  }

  List<IndexScore> _normalizeSeries(
    List<IndexScore> series,
    List<IndexScore> latest,
    DateTime start,
  ) {
    final scoresByType = <indexType, List<IndexScore>>{};
    for (final point in series) {
      scoresByType.putIfAbsent(point.type, () => []).add(point);
    }

    final normalized = <IndexScore>[];
    for (final type in indexType.values) {
      final list = scoresByType[type];
      if (list == null || list.isEmpty) {
        final fallbackValue = latest
            .firstWhere(
              (score) => score.type == type,
              orElse: () => IndexScore(
                type: type,
                value: _fallbackIndexValues[type] ?? 60,
                timestamp: start,
              ),
            )
            .value;
        normalized.addAll(_buildBaselineSeriesForType(type, fallbackValue, start));
      } else {
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        normalized.addAll(list);
      }
    }

    return normalized;
  }

  List<IndexScore> _buildBaselineSeries(
    List<IndexScore> latestScores,
    DateTime start,
  ) {
    return [
      for (final score in latestScores)
        ..._buildBaselineSeriesForType(score.type, score.value, start),
    ];
  }

  List<IndexScore> _buildBaselineSeriesForType(
    indexType type,
    double value,
    DateTime start,
  ) {
    const points = 5;
    final now = DateTime.now();
    final totalDays = now.difference(start).inDays;
    var stepDays = totalDays <= 0 ? 1 : (totalDays / (points - 1)).ceil();
    if (stepDays < 1) stepDays = 1;
    if (stepDays > 90) stepDays = 90;

    final baseValue = value <= 0 ? (_fallbackIndexValues[type] ?? 60) : value;
    final amplitude = math.max(3, baseValue * 0.08);

    return List<IndexScore>.generate(points, (index) {
      final progress = points <= 1 ? 0.0 : index / (points - 1);
      final wave = math.sin(progress * math.pi) * amplitude;
      final adjustedValue = (baseValue + wave - amplitude / 2).clamp(40.0, 95.0);
      final candidate = start.add(Duration(days: stepDays * index));
      final timestamp = candidate.isAfter(now) ? now : candidate;
      return IndexScore(type: type, value: adjustedValue, timestamp: timestamp);
    });
  }
}

class _FeedbackEntryCard extends StatelessWidget {
  const _FeedbackEntryCard({required this.entry, required this.dateFormat});

  final FeedbackEntry entry;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final timestamp = dateFormat.format(entry.createdAt.toLocal());
    final ratingText = '${AppStrings.feedbackRatingLabel}: ${entry.rating}/5';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.username, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(entry.accessLevel.label, style: metadataStyle),
              const SizedBox(width: 8),
              Text(timestamp, style: metadataStyle),
            ],
          ),
          const SizedBox(height: 12),
          Text(entry.text, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(ratingText, style: metadataStyle),
          if (entry.replies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.feedbackReplyLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < entry.replies.length; i++) ...[
                    _FeedbackReplyRow(reply: entry.replies[i], dateFormat: dateFormat),
                    if (i < entry.replies.length - 1) const Divider(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackReplyRow extends StatelessWidget {
  const _FeedbackReplyRow({required this.reply, required this.dateFormat});
  final LeaderReply reply;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('City Leader: ${reply.username}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(dateFormat.format(reply.createdAt.toLocal()), style: metadataStyle),
        const SizedBox(height: 8),
        Text(reply.text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
