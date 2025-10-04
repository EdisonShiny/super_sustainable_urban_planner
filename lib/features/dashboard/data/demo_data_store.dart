import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../auth/models/access_level.dart';
import '../../auth/models/user_profile.dart';
import '../models/city_region.dart';
import '../models/feedback.dart';
import '../models/index_breakdown.dart';
import '../models/index_score.dart';
import '../models/leader_reply.dart';

/// Demo datastore that reads daily values from a CSV and computes
/// GCI/CRI/HI/USI for a small list of cities.
/// CSV header (8 cols):
/// date,city,ndvi,housing_density,flood_decile,drought_anomaly,pm25,lst_celsius
class DemoDataStore {
  DemoDataStore._() {
    for (final city in _cities) {
      _citiesById[city.id] = city;
      _feedbackByCity[city.displayName] = <FeedbackEntry>[];
    }
    _seedFeedback(); // empty by design for demo
  }

  static final DemoDataStore instance = DemoDataStore._();

  // Use the one you actually ship. We try primary, then fallback.
  static const String _csvAssetPathPrimary = 'assets/data/NASA_Urban_Planner_Demo.csv';
  static const String _csvAssetPathFallback = 'assets/data/NASA_Urban_Planner_DATA_Demo.csv';

  /// Cities included in the demo. displayName = "Name, Region • Country"
  final List<CityRegion> _cities = const [
    CityRegion(
      id: 'demo-kuching',
      name: 'Kuching',
      region: 'Sarawak',
      country: 'Malaysia',
      latitude: 1.5533,
      longitude: 110.3592,
    ),
    CityRegion(
      id: 'demo-sibu',
      name: 'Sibu',
      region: 'Sarawak',
      country: 'Malaysia',
      latitude: 2.2879,
      longitude: 111.8307,
    ),
    CityRegion(
      id: 'demo-miri',
      name: 'Miri',
      region: 'Sarawak',
      country: 'Malaysia',
      latitude: 4.3990,
      longitude: 113.9914,
    ),
    CityRegion(
      id: 'demo-london',
      name: 'London',
      region: 'England',
      country: 'United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
    ),
    CityRegion(
      id: 'demo-south-africa',
      name: 'South Africa',
      region: 'Southern Africa',
      country: 'South Africa',
      latitude: -25.7479,
      longitude: 28.2293,
    ),
  ];

  final Map<String, CityRegion> _citiesById = <String, CityRegion>{};
  final Map<String, List<FeedbackEntry>> _feedbackByCity = <String, List<FeedbackEntry>>{};
  final Map<String, List<_CityDataRow>> _rowsByCity = <String, List<_CityDataRow>>{};

  bool _csvLoaded = false;

  final UserProfile _demoProfile = const UserProfile(
    id: 'demo-user-01',
    username: 'Avery Lee',
    email: 'avery.lee@example.com',
    accessLevel: AccessLevel.cityLeader,
    cityRegion: 'demo-kuching',
    departmentAgencies: 'Sustainability Office',
  );

  UserProfile get demoProfile => _demoProfile;

  // ----------------------------- CSV LOADING ------------------------------

  Future<void> _ensureCsvLoaded() async {
    if (_csvLoaded) return;

    String raw;
    try {
      raw = await rootBundle.loadString(_csvAssetPathPrimary);
    } catch (_) {
      // Fallback filename (you mentioned another actual name earlier)
      raw = await rootBundle.loadString(_csvAssetPathFallback);
    }

    final lines = const LineSplitter().convert(raw);
    if (lines.length <= 1) {
      _csvLoaded = true;
      return;
    }

    // Expecting header at line 0. Parse from line 1 onward.
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Simple CSV split; if your city names contain commas, switch to a CSV parser.
      final parts = line.split(',');
      if (parts.length < 8) continue;

      final dateStr = parts[0].trim();
      final cityNameRaw = parts[1].trim();

      final cityId = _cityIdForName(cityNameRaw);
      if (cityId == null) continue;

      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }

      final row = _CityDataRow(
        date: DateTime(date.year, date.month, date.day),
        ndvi: _parseDouble(parts[2]),
        housingDensity: _parseDouble(parts[3]),
        floodDecile: _parseDouble(parts[4]),
        droughtAnomaly: _parseDouble(parts[5]),
        pm25: _parseDouble(parts[6]),
        lstCelsius: _parseDouble(parts[7]),
      );

      _rowsByCity.putIfAbsent(cityId, () => <_CityDataRow>[]).add(row);
    }

    // Sort each city's rows by date ascending
    for (final rows in _rowsByCity.values) {
      rows.sort((a, b) => a.date.compareTo(b.date));
    }

    _csvLoaded = true;
  }

  // ----------------------------- PUBLIC API ------------------------------

  List<CityRegion> get cities => List.unmodifiable(_cities);

  bool hasCity(String cityId) => _citiesById.containsKey(cityId);

  CityRegion? matchCity(String query) {
    final lower = query.toLowerCase();
    for (final city in _cities) {
      if (city.id.toLowerCase() == lower ||
          city.displayName.toLowerCase().contains(lower) ||
          city.name.toLowerCase() == lower) {
        return city;
      }
    }
    return null;
  }

  List<CityRegion> searchCities(String query) {
    final lower = query.toLowerCase();
    return _cities
        .where((city) => city.displayName.toLowerCase().contains(lower))
        .toList();
  }

  Future<List<IndexScore>> latestScoresFor(String cityId) async {
    await _ensureCsvLoaded();
    final normalized = _normalizeCityId(cityId);
    final rows = _rowsByCity[normalized];
    final today = DateTime.now();

    if (rows == null || rows.isEmpty) {
      return _zeroScores(today);
    }

    final snapshot = _snapshotForDate(rows, normalized, today);
    return _scoresFromSnapshot(snapshot);
  }

  Future<Map<indexType, List<IndexBreakdown>>> breakdownsFor(String cityId) async {
    await _ensureCsvLoaded();
    final normalized = _normalizeCityId(cityId);
    final rows = _rowsByCity[normalized];

    if (rows == null || rows.isEmpty) {
      return {
        for (final type in indexType.values) type: const <IndexBreakdown>[],
      };
    }

    final snapshot = _snapshotForDate(rows, normalized, DateTime.now());
    return _buildBreakdowns(snapshot);
  }

  Future<List<IndexScore>> seriesFor(String cityId, DateTime from) async {
    await _ensureCsvLoaded();
    final normalized = _normalizeCityId(cityId);
    final rows = _rowsByCity[normalized];

    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime.now();
    if (start.isAfter(end)) return const [];

    final results = <IndexScore>[];

    if (rows == null || rows.isEmpty) {
      for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
        results.addAll(_zeroScores(date));
      }
      return results;
    }

    for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
      final snapshot = _snapshotForDate(rows, normalized, date);
      results.addAll(_scoresFromSnapshot(snapshot));
    }

    return results;
  }

  List<FeedbackEntry> feedbackForCity(String cityDisplayName) {
    final entries = _feedbackByCity[cityDisplayName];
    if (entries == null) return const [];
    final sorted = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  FeedbackEntry addFeedback({
    required UserProfile author,
    required String cityDisplayName,
    required String description,
    required int rating,
  }) {
    final entry = FeedbackEntry(
      id: 'demo-feedback-${DateTime.now().microsecondsSinceEpoch}',
      userId: author.id,
      username: author.username,
      accessLevel: author.accessLevel,
      city: cityDisplayName,
      text: description,
      rating: rating,
      createdAt: DateTime.now(),
    );
    _feedbackByCity.putIfAbsent(cityDisplayName, () => []).add(entry);
    return entry;
  }

  LeaderReply addReply({
    required String feedbackId,
    required UserProfile leader,
    required String replyText,
  }) {
    final reply = LeaderReply(
      id: 'demo-reply-${DateTime.now().microsecondsSinceEpoch}',
      feedbackId: feedbackId,
      username: leader.username,
      text: replyText,
      createdAt: DateTime.now(),
    );

    for (final entries in _feedbackByCity.values) {
      final index = entries.indexWhere((entry) => entry.id == feedbackId);
      if (index != -1) {
        final target = entries[index];
        final updated = target.copyWith(replies: [...target.replies, reply]);
        entries[index] = updated;
        break;
      }
    }

    return reply;
  }

  /// For demo we just surface "now"; your UI already shows "current".
  DateTime? latestTimestamp(String cityId) => DateTime.now();

  // ----------------------------- CORE COMPUTE -----------------------------

  String _normalizeCityId(String cityIdOrName) {
    // Accept id ("demo-kuching") or human names ("Kuching", "kuching")
    final lower = cityIdOrName.toLowerCase();

    // Direct id match
    if (_citiesById.containsKey(lower)) return lower;
    if (_citiesById.containsKey(cityIdOrName)) return cityIdOrName;

    // Try by id case-insensitive
    for (final id in _citiesById.keys) {
      if (id.toLowerCase() == lower) return id;
    }

    // Try by name/display name
    for (final c in _cities) {
      if (c.name.toLowerCase() == lower ||
          c.displayName.toLowerCase() == lower ||
          c.displayName.toLowerCase().contains(lower)) {
        return c.id;
      }
    }
    // Fallback to original (may not exist in _rowsByCity — callers handle empties)
    return cityIdOrName;
  }

  _IndexSnapshot _snapshotForDate(
    List<_CityDataRow> rows,
    String cityId,
    DateTime target,
  ) {
    final row = _rowForDate(rows, target);
    final timestamp = DateTime(target.year, target.month, target.day);

    // Factor scores (0–100)
    final vegetation = _scoreNdvi(row.ndvi);
    final housing = _scoreHousingDensity(row.housingDensity);
    final drought = _scoreDrought(row.droughtAnomaly);
    final flood = _scoreFlood(row.floodDecile);
    final airQuality = _scorePm25(row.pm25);
    final landSurfaceTemp = _scoreLst(row.lstCelsius);
    final feedbackScore = _feedbackScoreFor(cityId);

    // Index rollups (0–100)
    final gci = (vegetation * 0.5) + (housing * 0.5);
    final cri = (drought * 0.5) + (flood * 0.5);
    final hi = (airQuality * 0.4) + (landSurfaceTemp * 0.4) + (feedbackScore * 0.2);
    final usi = (gci * 0.3) + (cri * 0.3) + (hi * 0.4);

    return _IndexSnapshot(
      timestamp: timestamp,
      indexValues: {
        indexType.usi: usi,
        indexType.gci: gci,
        indexType.cri: cri,
        indexType.hi: hi,
      },
      factors: _FactorScores(
        vegetation: vegetation,
        housing: housing,
        drought: drought,
        flood: flood,
        airQuality: airQuality,
        landSurfaceTemp: landSurfaceTemp,
        feedback: feedbackScore,
      ),
    );
  }

  _CityDataRow _rowForDate(List<_CityDataRow> rows, DateTime target) {
    if (rows.isEmpty) return _CityDataRow.empty();
    final base = rows.first.date;
    final normalizedTarget = DateTime(target.year, target.month, target.day);
    var diff = normalizedTarget.difference(base).inDays;
    final length = rows.length;
    if (length == 0) return rows.first;

    // Cycle through available rows for any date (demo "365-day rolling" behavior)
    if (diff < 0) {
      final mod = (-diff) % length;
      diff = (length - mod) % length;
    }
    final index = diff % length;
    return rows[index];
  }

  List<IndexScore> _scoresFromSnapshot(_IndexSnapshot snapshot) {
    return indexType.values
        .map(
          (type) => IndexScore(
            type: type,
            value: snapshot.indexValues[type] ?? 0,
            timestamp: snapshot.timestamp,
          ),
        )
        .toList();
  }

  Map<indexType, List<IndexBreakdown>> _buildBreakdowns(_IndexSnapshot snapshot) {
    final factors = snapshot.factors;

    List<IndexBreakdown> build(List<_Contribution> contributions) {
      final total = contributions.fold<double>(0, (sum, item) => sum + item.value);
      if (total <= 0) {
        return contributions.map((item) => IndexBreakdown(factor: item.label, percentage: 0)).toList();
      }
      return contributions
          .map((item) => IndexBreakdown(
                factor: item.label,
                percentage: (item.value / total * 100).clamp(0, 100),
              ))
          .toList();
    }

    return {
      indexType.usi: build([
        _Contribution('Green Coverage Index', snapshot.indexValues[indexType.gci]! * 0.3),
        _Contribution('Climate Resilience Index', snapshot.indexValues[indexType.cri]! * 0.3),
        _Contribution('Health Index', snapshot.indexValues[indexType.hi]! * 0.4),
      ]),
      indexType.gci: build([
        _Contribution('Vegetation / Green Coverage', factors.vegetation * 0.5),
        _Contribution('Population & Housing Density', factors.housing * 0.5),
      ]),
      indexType.cri: build([
        _Contribution('Drought / Dryness', factors.drought * 0.5),
        _Contribution('Flood Hazard', factors.flood * 0.5),
      ]),
      indexType.hi: build([
        _Contribution('Air Quality (PM2.5)', factors.airQuality * 0.4),
        _Contribution('Land Surface Temperature', factors.landSurfaceTemp * 0.4),
        _Contribution('Resident Feedback', factors.feedback * 0.2),
      ]),
    };
  }

  List<IndexScore> _zeroScores(DateTime timestamp) {
    return indexType.values
        .map((type) => IndexScore(type: type, value: 0, timestamp: timestamp))
        .toList();
  }

  /// FULL marks (100) when city has **zero** resident comments.
  double _feedbackScoreFor(String cityId) {
    final display = _citiesById[cityId]?.displayName;
    if (display == null) return 100;

    final entries = _feedbackByCity[display];
    if (entries == null || entries.isEmpty) {
      return 100; // <-- your requested behavior
    }
    final average = entries.fold<double>(0, (sum, e) => sum + e.rating) / entries.length;
    return (average / 5.0) * 100;
  }

  // ----------------------------- SCORING MAPS -----------------------------

  double _scoreNdvi(double ndvi) {
    final value = ndvi.clamp(-1.0, 1.0);
    if (value <= 0.15) {
      return _lerp(value, -0.1, 0.15, 0, 24);
    }
    if (value <= 0.30) {
      return _lerp(value, 0.15, 0.30, 25, 49);
    }
    if (value <= 0.55) {
      return _lerp(value, 0.30, 0.55, 50, 74);
    }
    return _lerp(value, 0.55, 1.0, 75, 100);
  }

  double _scoreHousingDensity(double density) {
    if (density <= 0) return 0;
    if (density <= 100) return _lerp(density, 0, 100, 0, 20);
    if (density <= 1000) return 100;   // sweet-spot urban density
    if (density <= 10000) return 60;   // crowded
    return 20;                         // extreme crowding
  }

  double _scoreDrought(double anomaly) {
    // Score by absolute departure from normal; closer to 0 is better.
    final absValue = anomaly.abs();
    if (absValue <= 0.5) return _lerp(absValue, 0, 0.5, 100, 75);
    if (absValue <= 1.0) return _lerp(absValue, 0.5, 1.0, 75, 50);
    if (absValue <= 1.5) return _lerp(absValue, 1.0, 1.5, 49, 25);
    return _lerp(absValue.clamp(1.5, 3.0), 1.5, 3.0, 24, 0);
  }

  double _scoreFlood(double decile) {
    // decile range 1 (low hazard) to 10 (high hazard).
    if (decile <= 3) return _lerp(decile, 1, 3, 100, 75);
    if (decile <= 6) return _lerp(decile, 4, 6, 74, 50);
    if (decile <= 8) return _lerp(decile, 7, 8, 49, 25);
    return _lerp(decile.clamp(9, 10), 9, 10, 24, 0);
  }

  double _scorePm25(double value) {
    // US EPA-style breakpoints, inverted to a 0–100 "goodness" score.
    if (value <= 12) return _lerp(value, 0, 12, 100, 75);
    if (value <= 35.4) return _lerp(value, 12.1, 35.4, 74, 50);
    if (value <= 55.4) return _lerp(value, 35.5, 55.4, 49, 25);
    return _lerp(value.clamp(55.5, 150), 55.5, 150, 24, 0);
  }

  double _scoreLst(double tempC) {
    // Favor a comfortable LST band ~22.5°C; degrade as it moves away.
    final value = tempC;
    if (value >= 15 && value <= 30) {
      final distance = (value - 22.5).abs();
      return (100 - (distance / 7.5) * 25).clamp(75, 100);
    }
    if (value >= 10 && value < 15) return _lerp(value, 10, 15, 50, 75);
    if (value > 30 && value <= 35) return _lerp(value, 30, 35, 75, 50);
    if (value >= 5 && value < 10) return _lerp(value, 5, 10, 25, 49);
    if (value > 35 && value <= 40) return _lerp(value, 35, 40, 49, 25);
    return _lerp(value < 5 ? value : value.clamp(40, 50), value < 5 ? -10 : 40, value < 5 ? 5 : 50, 0, 24);
  }

  // ----------------------------- UTILITIES -------------------------------

  String? _cityIdForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kuching')) return 'demo-kuching';
    if (lower.contains('sibu')) return 'demo-sibu';
    if (lower.contains('miri')) return 'demo-miri';
    if (lower.contains('london')) return 'demo-london';
    if (lower.contains('south africa') || lower.contains('southern africa')) {
      return 'demo-south-africa';
    }
    return null;
  }

  double _parseDouble(String source) => double.tryParse(source.trim()) ?? 0;

  double _lerp(double value, double inMin, double inMax, double outMin, double outMax) {
    if ((inMax - inMin).abs() < 1e-9) return outMin;
    final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
    return outMin + (outMax - outMin) * t;
  }

  void _seedFeedback() {
    // Intentionally empty for demo (so cities start with zero comments)
  }
}

// --------------------------- INTERNAL MODELS ----------------------------

class _CityDataRow {
  const _CityDataRow({
    required this.date,
    required this.ndvi,
    required this.housingDensity,
    required this.floodDecile,
    required this.droughtAnomaly,
    required this.pm25,
    required this.lstCelsius,
  });

  factory _CityDataRow.empty() => _CityDataRow(
        date: DateTime.now(),
        ndvi: 0,
        housingDensity: 0,
        floodDecile: 10,
        droughtAnomaly: 0,
        pm25: 0,
        lstCelsius: 0,
      );

  final DateTime date;
  final double ndvi;
  final double housingDensity;
  final double floodDecile;
  final double droughtAnomaly;
  final double pm25;
  final double lstCelsius;
}

class _IndexSnapshot {
  const _IndexSnapshot({
    required this.timestamp,
    required this.indexValues,
    required this.factors,
  });

  final DateTime timestamp;
  final Map<indexType, double> indexValues;
  final _FactorScores factors;
}

class _FactorScores {
  const _FactorScores({
    required this.vegetation,
    required this.housing,
    required this.drought,
    required this.flood,
    required this.airQuality,
    required this.landSurfaceTemp,
    required this.feedback,
  });

  final double vegetation;
  final double housing;
  final double drought;
  final double flood;
  final double airQuality;
  final double landSurfaceTemp;
  final double feedback;
}

class _Contribution {
  const _Contribution(this.label, this.value);
  final String label;
  final double value;
}

