import 'package:flutter/material.dart';
import '../constants/assets.dart';
import '../constants/strings.dart';

/// Top-level navigation bar shared across the authenticated shell.
class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.onBrandTap,
    this.onDashboardTap,
    required this.onAboutTap,
    required this.onContactTap,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  final VoidCallback onBrandTap;
  final VoidCallback? onDashboardTap;
  final VoidCallback onAboutTap;
  final VoidCallback onContactTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBrandTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.primary,
                          alignment: Alignment.center,
                          child: Text(
                            'USI',
                            style: textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(AppStrings.tagline, style: textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Expose dashboard navigation when supplied by the page.
          if (onDashboardTap != null)
            _HeaderAction(
              label: AppStrings.navDashboard,
              onTap: onDashboardTap!,
            ),
          _HeaderAction(label: AppStrings.navAbout, onTap: onAboutTap),
          _HeaderAction(label: AppStrings.navContact, onTap: onContactTap),
          _HeaderAction(label: AppStrings.navProfile, onTap: onProfileTap),
          _HeaderAction(label: AppStrings.navLogout, onTap: onLogoutTap),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: TextButton(onPressed: onTap, child: Text(label)),
    );
  }
}
