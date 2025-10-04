import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum CityStatusMood { critical, concern, stable, thriving }

extension CityStatusMoodX on CityStatusMood {
  String get emoji {
    switch (this) {
      case CityStatusMood.critical:
        return '💀';
      case CityStatusMood.concern:
        return '😢';
      case CityStatusMood.stable:
        return '😶';
      case CityStatusMood.thriving:
        return '😊';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CityStatusMood.critical:
        return AppColors.statusCritical;
      case CityStatusMood.concern:
        return AppColors.statusConcern;
      case CityStatusMood.stable:
        return AppColors.statusStable;
      case CityStatusMood.thriving:
        return AppColors.statusThriving;
    }
  }
}

class EmojiStatusBadge extends StatelessWidget {
  const EmojiStatusBadge({super.key, required this.mood, required this.label});

  final CityStatusMood mood;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: mood.backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

