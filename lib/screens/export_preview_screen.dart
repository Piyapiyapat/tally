import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../services/export_service.dart';
import '../theme/app_colors.dart';

/// Renders the generated report inline so the user can review it before
/// deciding to save, print, or share — using [PdfPreview]'s own built-in
/// print/share actions rather than exporting blind.
class ExportPreviewScreen extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final bool includeMoods;
  final bool includeHabits;
  final bool includeJournals;

  const ExportPreviewScreen({
    super.key,
    required this.from,
    required this.to,
    this.includeMoods = true,
    this.includeHabits = true,
    this.includeJournals = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.deep, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview report',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => ExportService.buildReportBytes(
          from: from,
          to: to,
          includeMoods: includeMoods,
          includeHabits: includeHabits,
          includeJournals: includeJournals,
          format: format,
        ),
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'tally_report.pdf',
      ),
    );
  }
}
