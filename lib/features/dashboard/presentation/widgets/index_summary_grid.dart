import 'package:flutter/material.dart';
import '../../models/index_breakdown.dart';
import '../../models/index_score.dart';
import 'index_box.dart';

class IndexSummaryGrid extends StatelessWidget {
  const IndexSummaryGrid({
    super.key,
    required this.scores,
    required this.breakdowns,
    required this.onIndexTap,
  });

  final List<IndexScore> scores;
  final Map<indexType, List<IndexBreakdown>> breakdowns;
  final ValueChanged<indexType> onIndexTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < scores.length; i++) ...[
          IndexBox(
            score: scores[i],
            breakdown: breakdowns[scores[i].type] ?? const [],
            onTap: () => onIndexTap(scores[i].type),
          ),
          if (i < scores.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
