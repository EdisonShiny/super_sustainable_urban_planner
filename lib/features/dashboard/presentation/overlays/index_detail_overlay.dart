import 'package:flutter/material.dart';
import '../../models/index_breakdown.dart';
import '../../models/index_definitions.dart';
import '../../models/index_score.dart';

/// Category range labels mapped to 4 standard bands.
const _kCategoryRanges = ['0–24%', '25–49%', '50–74%', '75–100%'];

/// Displays a modal with detailed breakdown and sourcing info for an index.
class IndexDetailOverlay extends StatelessWidget {
  const IndexDetailOverlay({
    super.key,
    required this.score,
    required this.breakdown,
    this.definition,
  });

  final IndexScore score;
  final List<IndexBreakdown> breakdown;
  final IndexDefinition? definition;

  /// Helper for presenting the overlay for a selected index box.
  static Future<void> show(
    BuildContext context, {
    required IndexScore score,
    required List<IndexBreakdown> breakdown,
  }) {
    final def = findIndexDefinition(score.type);
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: IndexDetailOverlay(
          score: score,
          breakdown: breakdown,
          definition: def,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final valueStr = score.value.toStringAsFixed(1);
    // Always show only the current value (no "Last Updated").
    final currentValueText = 'Current value: $valueStr%';

    return SizedBox(
      width: 520,
      height: 560,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${score.type.description} Details',
                    style: theme.textTheme.headlineSmall),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BodyText(currentValueText),
            const SizedBox(height: 24),

            // Scrollable body
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Contributing factors'),
                      const SizedBox(height: 12),
                      _FactorProgressList(breakdown: breakdown),
                      const SizedBox(height: 24),

                      if (score.type == indexType.usi)
                        _buildUSISection(theme)
                      else if (definition != null)
                        _DefinitionSection(definition: definition!)
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _SectionTitle('Definition unavailable'),
                            SizedBox(height: 8),
                            _BodyText(
                              'No detailed definition found for this index type.',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUSISection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle('Introduction'),
        _BodyText(
          "The Urban Sustainability Index (USI) captures a city’s overall sustainability by integrating three key dimensions:",
        ),
        SizedBox(height: 8),
        _Bullet('Green Coverage Index (GCI): environmental quality & land use.'),
        _Bullet('Climate Resilience Index (CRI): resilience to climate risks.'),
        _Bullet('Health Index (HI): air quality, surface temperature, well-being.'),
        SizedBox(height: 12),
        _SectionTitle('Formula'),
        _BodyTextStrong('USI = (0.3 × GCI) + (0.3 × CRI) + (0.4 × HI)'),
        SizedBox(height: 12),
        _Bullet('USI = Urban Sustainability Index'),
        _Bullet('GCI = Green Coverage Index'),
        _Bullet('CRI = Climate Resilience Index'),
        _Bullet('HI = Health Index'),
        SizedBox(height: 12),
        _BodyText(
          'Health-related factors carry the greatest weight (40%); '
          'environmental land use and climate resilience contribute 30% each.',
        ),
      ],
    );
  }
}

/// Definition-driven rendering (intro, formula, factors list).
class _DefinitionSection extends StatelessWidget {
  const _DefinitionSection({required this.definition});
  final IndexDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Introduction'),
        _BodyText(definition.introText),
        const SizedBox(height: 15),
        const _SectionTitle('Formula'),
        _BodyTextStrong(definition.formulaText),
        const SizedBox(height: 16),

        // Render any number of factor groups (2 for GCI/CRI, 3 for HI, etc.)
        ...definition.factors.map((fg) => _FactorGroupSection(group: fg)),
      ],
    );
  }
}

/// Renders a single factor group (title, 4 category bands, data support).
class _FactorGroupSection extends StatelessWidget {
  const _FactorGroupSection({required this.group});
  final FactorGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(group.title),
          const SizedBox(height: 6),
          for (int i = 0; i < group.categories.length; i++) ...[
            _CategoryBlock(
              label: '${_kCategoryRanges[i]}\nProblem Statement',
              text: group.categories[i].problem,
            ),
            _CategoryBlock(
              label: 'Solution for Sustainable Urban Planning',
              text: group.categories[i].solution,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          const _SectionTitleSmall('Data Support'),
          _BodyTextSmall(group.dataSupport),
        ],
      ),
    );
  }
}

/// Progress list for contributing factors
class _FactorProgressList extends StatelessWidget {
  const _FactorProgressList({required this.breakdown});
  final List<IndexBreakdown> breakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: breakdown.map((f) {
        final progress = (f.percentage.clamp(0, 100)) / 100.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyTextStrong(f.factor),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress, minHeight: 6),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ----------------------
// Tiny UI helpers
// ----------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      );
}

class _SectionTitleSmall extends StatelessWidget {
  const _SectionTitleSmall(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall,
      );
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}

class _BodyTextStrong extends StatelessWidget {
  const _BodyTextStrong(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      );
}

class _BodyTextSmall extends StatelessWidget {
  const _BodyTextSmall(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodySmall);
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text('- $text', style: Theme.of(context).textTheme.bodyMedium);
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

