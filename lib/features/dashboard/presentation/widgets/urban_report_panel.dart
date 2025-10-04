
/*
import 'package:flutter/material.dart';
import '../../../export/report_exporter.dart';

class UrbanReportPanel extends StatelessWidget {
  const UrbanReportPanel({super.key, required this.sections});

  final List<ReportSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          _ReportSectionCard(section: sections[i]),
          if (i < sections.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({required this.section});

  final ReportSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(section.summary, style: theme.textTheme.bodyMedium),
        if (section.points.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: section.points
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('â€¢ '),
                        Expanded(
                          child: Text(point, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

*/
import 'package:flutter/material.dart';
import '../../../export/report_exporter.dart';

class UrbanReportPanel extends StatelessWidget {
  const UrbanReportPanel({super.key, required this.sections});

  final List<ReportSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          _ReportSectionCard(section: sections[i]),
          if (i < sections.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({required this.section});

  final ReportSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(section.summary, style: theme.textTheme.bodyMedium),
        if (section.points.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: section.points
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('- '), // fixed bullet glyph
                        Expanded(
                          child: Text(point, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

