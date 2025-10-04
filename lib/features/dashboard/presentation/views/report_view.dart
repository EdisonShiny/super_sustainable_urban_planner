import 'package:flutter/material.dart';
import '../../../export/report_exporter.dart';
import '../widgets/urban_report_panel.dart';

class ReportView extends StatelessWidget {
  const ReportView({
    super.key,
    required this.sections,
    required this.onExport,
    this.enableScroll = false,
    this.maxContentHeight,
  });

  final List<ReportSection> sections;
  final VoidCallback onExport;
  final bool enableScroll;
  final double? maxContentHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSections = sections.isNotEmpty;

    final Widget body = hasSections
        ? UrbanReportPanel(sections: sections)
        : Center(
            child: Text(
              'No report insights yet. Index placeholders will update once data is ingested.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        const headerHeight = 44.0;
        const headerSpacing = 12.0;
        final contentTopInset = headerHeight + headerSpacing;

        double minContentHeight = 0;
        if (constraints.maxHeight.isFinite) {
          minContentHeight = constraints.maxHeight - contentTopInset;
        } else if (maxContentHeight != null) {
          minContentHeight = maxContentHeight!;
        }
        if (!minContentHeight.isFinite || minContentHeight < 0) {
          minContentHeight = 0;
        }

        Widget content = body;
        if (enableScroll) {
          content = Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: body,
              ),
            ),
          );
        } else {
          content = Align(alignment: Alignment.topLeft, child: body);
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(top: contentTopInset, child: content),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Urban Performance Report',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onPressed: onExport,
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                            label: const Text('Export PDF'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: headerSpacing),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
