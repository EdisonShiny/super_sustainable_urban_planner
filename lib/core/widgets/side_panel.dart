import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import 'divider_line.dart';
import 'dot_legend_item.dart';
import 'emoji_status_badge.dart';
import 'primary_button.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({
    super.key,
    required this.username,
    required this.accessLevelLabel,
    required this.cityRegion,
    required this.statusMood,
    required this.statusLabel,
    required this.onPrimaryAction,
    this.departmentAgencies,
    this.isCityLeader = false,
  });

  final String username;
  final String accessLevelLabel;
  final String? departmentAgencies;
  final String cityRegion;
  final CityStatusMood statusMood;
  final String statusLabel;
  final bool isCityLeader;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.profileTitle, style: titleStyle),
                const SizedBox(height: 16),
                _ProfileDetail(label: 'Username', value: username),
                const SizedBox(height: 12),
                _ProfileDetail(label: 'Access Level', value: accessLevelLabel),
                if (departmentAgencies != null &&
                    departmentAgencies!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ProfileDetail(
                      label: 'Department Agencies',
                      value: departmentAgencies!,
                    ),
                  ),
                const SizedBox(height: 12),
                _ProfileDetail(label: 'City / Region', value: cityRegion),
                const DividerLine(),
                Text(AppStrings.legendTitle, style: titleStyle),
                const SizedBox(height: 16),
                const DotLegendItem(
                  color: AppColors.usi,
                  label: 'USI Urban Sustainability Index',
                ),
                const SizedBox(height: 12),
                const DotLegendItem(
                  color: AppColors.gci,
                  label: 'GCI Green Coverage Index',
                ),
                const SizedBox(height: 12),
                const DotLegendItem(
                  color: AppColors.cri,
                  label: 'CRI Climate Resilience Index',
                ),
                const SizedBox(height: 12),
                const DotLegendItem(
                  color: AppColors.hi,
                  label: 'HI Health Index',
                ),
                const DividerLine(),
                Text(AppStrings.statusTitle, style: titleStyle),
                const SizedBox(height: 16),
                EmojiStatusBadge(mood: statusMood, label: statusLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: isCityLeader
                ? AppStrings.viewFeedback
                : AppStrings.shareConcern,
            onPressed: onPrimaryAction,
          ),
        ],
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
