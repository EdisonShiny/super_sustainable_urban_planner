import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/strings.dart';
import '../../../core/widgets/header_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/data/city_repository.dart';
import '../../dashboard/presentation/overlays/contact_overlay.dart';

/// Authenticated landing page that introduces the portal and links to key actions.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Signs the user out and returns them to the login flow.
  Future<void> _handleLogout(BuildContext context) async {
    final router = GoRouter.of(context);
    CityRepository.instance.clearSelection();
    await AuthRepository.instance.signOut();
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              // Brand tap keeps the user on the informational page.
              onBrandTap: () => context.go('/about'),
              // Provide a quick hop into the analytics workspace.
              onDashboardTap: () => context.go('/dashboard'),
              // Already here, so no-op.
              onAboutTap: () {},
              onContactTap: () => ContactOverlay.show(context),
              // Profile actions live inside the dashboard for now.
              onProfileTap: () => context.go('/dashboard'),
              onLogoutTap: () => _handleLogout(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.aboutTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        Text(
                          'INTRODUCTION:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'We developed the Sustainable Urban Planner Portal, an interactive dashboard that integrates NASA Earth observation data with community-reported insights to guide smarter, people and planet-conscious urban planning. The portal addresses the challenge of limited access to real-time, global-scale information that city leaders need to balance human well-being with environmental sustainability in fast-growing cities. At its core is the Urban Sustainability Index (USI), a holistic score standardized on a 0–100% scale. It is derived from three specialized indexes: the Green Coverage Index (GCI), which evaluates vegetation and housing balance; the Climate Resilience Index (CRI), which measures drought and flood risks; and the Health Index (HI), which reflects air quality and land surface temperature. The portal features map views and graph views that make trends easy to explore, compare, and communicate. Beyond data visualization, it enables two-way interaction where residents can submit concerns and feedback, while city leaders can respond with actions and updates. By combining NASA Earth science, intuitive visualization, and civic engagement, the project empowers cities to design growth strategies that safeguard ecosystems, strengthen climate resilience, and improve the quality of life for urban residents.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        
                        const SizedBox(height: 12),
                        Text(
                          'VISION:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'To create a world where data-driven urban planning leads to sustainable, resilient, and healthy cities — powered by NASA Earth observation science and community collaboration.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        
                        const SizedBox(height: 12),
                        Text(
                          'MISSION:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'To connect NASA satellite intelligence with community insight, transforming scientific data into actionable knowledge that empowers residents, city leaders, and policymakers to make informed, sustainable planning decisions.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        
                        const SizedBox(height: 12),
                        Text(
                          'OBJECTIVES:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Integrate Science and Society: Bridge NASA Earth observation data with local community feedback to form a unified understanding of urban well-being.\nSimplify Complex Data: Translate satellite and model-based datasets into intuitive, visual sustainability indexes accessible to everyone.\nEnable Smarter Decisions: Provide city leaders with evidence-based tools for monitoring, comparing, and improving urban sustainability.\nEmpower Residents: Encourage citizen participation by allowing community members to share real-world observations and concerns.\nAdvance Global Goals: Support the UN Sustainable Development Goals (SDGs) by promoting sustainable cities, climate resilience, and public health awareness.',
                          style: theme.textTheme.bodyLarge,
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'NASA DATA:',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Vegetation/Green Coverage Resource:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const _BulletItem(
                          text:
                              'Satellite: Terra satellite, using the MODIS instrument',
                        ),
                        Text(
                          'Population / Housing Density Resource:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const _BulletItem(
                          text:
                              'Not satellite-derived directly — produced by CIESIN (Columbia University) using national census data, modeled and gridded to 30 arc-second (~1 km) resolution.',
                        ),
                        Text(
                          'Drought/ Dryness Index Resource:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const _BulletItem(
                          text:
                              'Not a direct satellite sensor. It is a NASA/NOAA land data assimilation model, which blends satellite rainfall/evapotranspiration products with land surface models.',
                        ),
                        Text(
                          'Flood occurrence Probability Resource:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const _BulletItem(
                          text:
                              'Not a direct satellite dataset — derived from multiple hydrological and historical flood event data sources (global hazard modeling).',
                        ),
                        Text(
                          'Land surface temperature (LST) Resource:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const _BulletItem(
                          text:
                              'Suomi NPP satellite, VIIRS instrument',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'OTHER DATA:',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Air quality (PM2.5) Resource:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const _BulletItem(
                          text:
                              'Not direct satellite only — based on numerical weather & air quality models (ECMWF, DWD, NOAA) that assimilate ground and satellite observations.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Simple bullet row used for the key capability list.
class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}