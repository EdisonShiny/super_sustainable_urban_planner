import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/emoji_status_badge.dart';
import '../../models/index_breakdown.dart';
import '../../models/index_score.dart';

class IndexBox extends StatelessWidget {
  const IndexBox({
    super.key,
    required this.score,
    required this.breakdown,
    required this.onTap,
  });

  final IndexScore score;
  final List<IndexBreakdown> breakdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = score.type.color;
    final mood = _mapValueToMood(score.value);
    final subtitle = breakdown.take(3).map((e) => e.factor).join(' - ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.type.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${score.value.toStringAsFixed(0)}%',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: color),
                    ),
                  ],
                ),
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (score.value.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  CityStatusMood _mapValueToMood(double value) {
    if (value < 25) return CityStatusMood.critical;
    if (value < 50) return CityStatusMood.concern;
    if (value < 75) return CityStatusMood.stable;
    return CityStatusMood.thriving;
  }
}
