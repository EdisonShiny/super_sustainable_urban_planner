import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportSection {
  const ReportSection({
    required this.title,
    required this.summary,
    this.points = const [],
  });

  final String title;
  final String summary;
  final List<String> points;
}

class ReportExporter {
  const ReportExporter._();

  static Future<Uint8List> buildPdf({
    required String cityName,
    required DateTime generatedAt,
    required List<ReportSection> sections,
  }) async {
    final doc = pw.Document();
    final formatter = DateFormat.yMMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Sustainable Urban Planner Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('City / Region: $cityName'),
            pw.Text('Generated: ${formatter.format(generatedAt)}'),
            pw.SizedBox(height: 24),
            ...sections.map((section) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    section.title,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(section.summary),
                  if (section.points.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: section.points
                          .map((point) => pw.Bullet(text: point))
                          .toList(),
                    ),
                  ],
                  pw.SizedBox(height: 18),
                ],
              );
            }),
          ];
        },
      ),
    );

    return doc.save();
  }
}
