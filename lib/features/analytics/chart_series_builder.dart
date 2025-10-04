import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../dashboard/models/index_score.dart';

class ChartSeries {
  const ChartSeries({
    required this.type,
    required this.color,
    required this.spots,
  });

  final indexType type;
  final Color color;
  final List<FlSpot> spots;
}

class ChartSeriesBuilder {
  const ChartSeriesBuilder._();

  static List<ChartSeries> build(List<IndexScore> scores) {
    final groups = <indexType, List<IndexScore>>{};
    for (final score in scores) {
      groups.putIfAbsent(score.type, () => []).add(score);
    }

    return groups.entries.map((entry) {
      final sorted = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final spots = sorted
          .map(
            (score) => FlSpot(
              score.timestamp.millisecondsSinceEpoch.toDouble(),
              score.value,
            ),
          )
          .toList();

      return ChartSeries(type: entry.key, color: entry.key.color, spots: spots);
    }).toList();
  }
}
