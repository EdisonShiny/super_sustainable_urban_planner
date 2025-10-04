import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../analytics/chart_series_builder.dart';
import '../../models/index_score.dart';

enum ChartRange { month, year }

extension ChartRangeX on ChartRange {
  String get label {
    switch (this) {
      case ChartRange.month:
        return '1M';
      case ChartRange.year:
        return '1Y';
    }
  }
}

class GraphView extends StatelessWidget {
  const GraphView({
    super.key,
    required this.series,
    required this.range,
    required this.onRangeChanged,
  });

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final List<ChartSeries> series;
  final ChartRange range;
  final ValueChanged<ChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    DateTime? monthAxisStart;
    List<ChartSeries> preparedSeries;

    if (range == ChartRange.year) {
      preparedSeries = _collapseToMonths(series);
    } else {
      final daily = _collapseToDays(series);
      preparedSeries = daily.series;
      monthAxisStart = daily.startDate;
    }

    final allSpots = preparedSeries.expand((s) => s.spots).toList();
    if (allSpots.isEmpty) {
      return Container(
        height: 360,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No data available for the selected period.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    allSpots.sort((a, b) => a.x.compareTo(b.x));

    double minX;
    double maxX;
    double bottomInterval;

    if (range == ChartRange.year) {
      minX = 0;
      maxX = 11;
      bottomInterval = 1;
    } else {
      minX = allSpots.first.x;
      maxX = allSpots.last.x;
      if (minX == maxX) {
        maxX = minX + 1;
      }
      bottomInterval = 1;
    }

    final maxY =
        allSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ChartRange.values.map((option) {
              final selected = option == range;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.label),
                  selected: selected,
                  onSelected: (value) {
                    if (value) onRangeChanged(option);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: true, horizontalInterval: 10),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) =>
                          Text('${value.toInt()}%'),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) =>
                          _buildBottomTitle(value, meta, monthAxisStart),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: preparedSeries
                    .map(
                      (item) => LineChartBarData(
                        spots: item.spots,
                        color: item.color,
                        barWidth: 3,
                        isCurved: true,
                        dotData: const FlDotData(show: false),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta, DateTime? monthStart) {
    if (range == ChartRange.year) {
      final monthIndex = value.round().clamp(0, 11);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_monthLabels[monthIndex]),
      );
    }

    final start = monthStart ?? DateTime.now();
    final day = start.add(Duration(days: value.round()));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('${day.day}'),
    );
  }

  List<ChartSeries> _collapseToMonths(List<ChartSeries> source) {
    return source.map((series) {
      final grouped = <int, List<double>>{};
      for (final spot in series.spots) {
        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
        final monthIndex = date.month - 1;
        grouped.putIfAbsent(monthIndex, () => []).add(spot.y);
      }

      double? lastValue;
      final spots = <FlSpot>[];
      for (var month = 0; month < 12; month++) {
        final values = grouped[month];
        double value;
        if (values != null && values.isNotEmpty) {
          value = values.reduce((a, b) => a + b) / values.length;
          lastValue = value;
        } else if (lastValue != null) {
          value = lastValue;
        } else if (grouped.isNotEmpty) {
          final first = grouped.values.first;
          value = first.reduce((a, b) => a + b) / first.length;
          lastValue = value;
        } else {
          value = 0;
        }
        spots.add(FlSpot(month.toDouble(), value));
      }
      return ChartSeries(type: series.type, color: series.color, spots: spots);
    }).toList();
  }

  _DailySeriesResult _collapseToDays(List<ChartSeries> source) {
    final daySet = <DateTime>{};
    final aggregated = <_SeriesDailyAggregation>[];

    for (final series in source) {
      final grouped = <DateTime, List<double>>{};
      for (final spot in series.spots) {
        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
        final dayKey = DateTime(date.year, date.month, date.day);
        grouped.putIfAbsent(dayKey, () => []).add(spot.y);
        daySet.add(dayKey);
      }
      final averages = <DateTime, double>{
        for (final entry in grouped.entries)
          entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
      };
      aggregated.add(
        _SeriesDailyAggregation(series.type, series.color, averages),
      );
    }

    if (daySet.isEmpty) {
      final today = DateTime.now();
      return _DailySeriesResult(
        source,
        DateTime(today.year, today.month, today.day),
      );
    }

    final sortedDays = daySet.toList()..sort();
    final startDay = sortedDays.first;

    final transformed = <ChartSeries>[];
    for (final entry in aggregated) {
      double? lastValue;
      double? fallback;
      if (entry.values.isNotEmpty) {
        fallback = entry.values.values.first;
      }
      final spots = <FlSpot>[];
      for (final day in sortedDays) {
        final value = entry.values[day];
        double y;
        if (value != null) {
          y = value;
          lastValue = value;
        } else if (lastValue != null) {
          y = lastValue;
        } else if (fallback != null) {
          y = fallback;
          lastValue = y;
        } else {
          y = 0;
        }
        final dayIndex = day.difference(startDay).inDays.toDouble();
        spots.add(FlSpot(dayIndex, y));
      }
      transformed.add(
        ChartSeries(type: entry.type, color: entry.color, spots: spots),
      );
    }

    return _DailySeriesResult(transformed, startDay);
  }
}

class _DailySeriesResult {
  const _DailySeriesResult(this.series, this.startDate);

  final List<ChartSeries> series;
  final DateTime startDate;
}

class _SeriesDailyAggregation {
  const _SeriesDailyAggregation(this.type, this.color, this.values);

  final indexType type;
  final Color color;
  final Map<DateTime, double> values;
}
