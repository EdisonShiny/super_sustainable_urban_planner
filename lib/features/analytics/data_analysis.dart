import '../../core/widgets/emoji_status_badge.dart';
import '../dashboard/models/index_breakdown.dart';
import '../dashboard/models/index_score.dart';
import '../dashboard/models/index_definitions.dart';

class DataAnalysis {
  const DataAnalysis._();

  // Overall city mood
  static CityStatusMood deriveCityMood(List<IndexScore> scores) {
    if (scores.isEmpty) return CityStatusMood.stable;
    final avg = scores.map((e) => e.value).reduce((a, b) => a + b) / scores.length;
    return _mapValueToMood(avg);
  }

  static CityStatusMood moodForValue(double value) => _mapValueToMood(value);

  static String moodLabel(CityStatusMood mood) {
    switch (mood) {
      case CityStatusMood.critical:
        return 'Critical Attention Needed';
      case CityStatusMood.concern:
        return 'Areas of Concern';
      case CityStatusMood.stable:
        return 'Stable Conditions';
      case CityStatusMood.thriving:
        return 'Thriving Performance';
    }
  }

  // Helpers (scale only; never re-normalize)
  static double _scalePct(double v) => (v <= 1.0 ? v * 100.0 : v).clamp(0.0, 100.0);

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  // Map of normalized aliases -> canonical label used in IndexDefinition
  static const Map<String, String> _kFactorAliases = {
    // Flood aliases → "Flood Occurrence Probability"
    'floodhazard': 'Flood Occurrence Probability',
    'floodhazards': 'Flood Occurrence Probability',
    'floodrisk': 'Flood Occurrence Probability',
    'floodoccurrenceprobability': 'Flood Occurrence Probability',

    // Drought aliases → "Drought / Dryness Index"
    'droughtindex': 'Drought / Dryness Index',
    'droughtdrynessindex': 'Drought / Dryness Index',
  };

  static String _canonicalLabel(String s) {
    final key = _norm(s);
    return _kFactorAliases[key] ?? s;
  }

  static List<IndexBreakdown> _scaled(List<IndexBreakdown> list) => list
      .map((e) => IndexBreakdown(
            factor: _canonicalLabel(e.factor),
            percentage: _scalePct(e.percentage),
          ))
      .toList();

  /// Reorder drivers for display:
  /// - USI: fixed GCI, CRI, HI order
  /// - Others: follow IndexDefinition.factors order
  static List<IndexBreakdown> _reorderForDisplay(
    indexType type,
    List<IndexBreakdown> items, {
    IndexDefinition? def,
  }) {
    final src = _scaled(items);
    if (src.isEmpty) return src;

    final byKey = <String, IndexBreakdown>{};
    for (final e in src) {
      byKey[_norm(_canonicalLabel(e.factor))] = e;
    }

    final ordered = <IndexBreakdown>[];

    if (type == indexType.usi) {
      const desired = [
        'Green Coverage Index',
        'Climate Resilience Index',
        'Health Index',
      ];
      for (final name in desired) {
        final hit = byKey[_norm(name)];
        if (hit != null) ordered.add(hit);
      }
      // Append any leftovers in original sequence
      for (final e in src) {
        if (!ordered.contains(e)) ordered.add(e);
      }
      return ordered;
    }

    if (def != null) {
      for (final fg in def.factors) {
        final hit = byKey[_norm(fg.title)];
        if (hit != null) ordered.add(hit);
      }
      for (final e in src) {
        if (!ordered.contains(e)) ordered.add(e);
      }
      return ordered;
    }

    return src;
  }

  // -----------------------
  // Index-level insights (actual values, ordered)
  // -----------------------
  static List<String> generateInsights(
    IndexScore score,
    List<IndexBreakdown> breakdown,
  ) {
    if (breakdown.isEmpty) {
      return [
        '${score.type.description} is at ${score.value.toStringAsFixed(0)}%. Continue monitoring to maintain performance.',
      ];
    }

    final def = findIndexDefinition(score.type);
    final items = _reorderForDisplay(score.type, breakdown, def: def);

    // Show ALL available drivers, in the desired order (no sorting/renorm)
    final drivers = items
        .map((f) => '${f.factor} (${f.percentage.toStringAsFixed(0)}%)')
        .join(', ');

    return [
      '${score.type.description} recorded ${score.value.toStringAsFixed(0)}%. '
          'Leading drivers: $drivers.',
      if (score.value < 50)
        'Focus on resilience actions for ${score.type.description.toLowerCase()} to offset declining indicators.',
      if (score.value >= 75)
        'Maintain funding and partnerships to sustain this positive trend.',
    ];
  }

  static String buildReportIntro(String cityName, CityStatusMood mood) {
    final tone = moodLabel(mood);
    return '$cityName currently shows $tone across urban performance metrics.';
  }

  static CityStatusMood _mapValueToMood(double value) {
    if (value < 25) return CityStatusMood.critical;
    if (value < 50) return CityStatusMood.concern;
    if (value < 75) return CityStatusMood.stable;
    return CityStatusMood.thriving;
  }

  // Factor band helpers + advice builder (use actual values)
  static const List<String> _kBandLabels = ['0-24%', '25-49%', '50-74%', '75-100%'];

  static int bandIndexFor(double value) {
    if (value < 25) return 0;
    if (value < 50) return 1;
    if (value < 75) return 2;
    return 3;
  }

  static String bandLabelForValue(double value) => _kBandLabels[bandIndexFor(value)];

  static List<String> buildFactorAdvicePoints(
    IndexScore score,
    List<IndexBreakdown> breakdown,
    IndexDefinition? definition,
  ) {
    if (definition == null || breakdown.isEmpty) return const [];

    final items = _reorderForDisplay(score.type, breakdown, def: definition);

    final points = <String>[];
    for (final f in items) {
      final fCanon = _canonicalLabel(f.factor);

      // Find matching group by title (relaxed matching), canonicalized
      FactorGroup? group;
      for (final g in definition.factors) {
        final gt = _norm(g.title);
        final ft = _norm(fCanon);
        if (gt == ft || gt.contains(ft) || ft.contains(gt)) {
          group = g;
          break;
        }
      }

      if (group == null || group.categories.length != 4) {
        points.add('$fCanon: ${f.percentage.toStringAsFixed(0)}% — continue monitoring.');
        continue;
      }

      final band = bandIndexFor(f.percentage);
      final bandLabel = bandLabelForValue(f.percentage);
      final advice = group.categories[band];

      points.add('$fCanon ($bandLabel): ${advice.problem}');
      points.add('Solution: ${advice.solution}');
    }
    return points;
  }

  // USI driver synthesis (only when USI has no breakdown)
  static List<IndexBreakdown> synthesizeUsiBreakdown(List<IndexScore> allScores) {
    IndexScore? get(indexType t) {
      for (final s in allScores) {
        if (s.type == t) return s;
      }
      return null;
    }

    final gci = get(indexType.gci);
    final cri = get(indexType.cri);
    final hi  = get(indexType.hi);

    final parts = <_Part>[];
    if (gci != null) parts.add(_Part('Green Coverage Index', 0.3 * gci.value));
    if (cri != null) parts.add(_Part('Climate Resilience Index', 0.3 * cri.value));
    if (hi  != null) parts.add(_Part('Health Index', 0.4 * hi.value));

    final total = parts.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) return const [];

    // These are shares of USI and will sum to 100% by design.
    return parts
        .map((p) => IndexBreakdown(
              factor: p.name,
              percentage: (p.value / total) * 100.0,
            ))
        .toList();
  }
}

class _Part {
  final String name;
  final double value;
  _Part(this.name, this.value);
}
