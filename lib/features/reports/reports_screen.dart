import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/period.dart';
import '../../ledger/ledger.dart';
import '../../reports/annual_report.dart';
import '../../reports/csv_export.dart';
import '../../reports/monthly_report.dart';
import '../../reports/pdf_kit.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// Report fonts are loaded once and reused.
final reportFontsProvider = FutureProvider<ReportFonts>((ref) => ReportFonts.load());

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final years = <int>{for (final e in ledger.entries) e.date.year}.toList()
            ..sort((a, b) => b.compareTo(a));
          final months = [for (final y in years) ...reportMonths(ledger, y, today).reversed];
          if (months.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Reports appear once you have entries.',
                  style: TextStyle(color: status.muted),
                ),
              ),
            );
          }
          return PageList(
            children: [
              SectionCard(
                children: [
                  const Label('Monthly report'),
                  for (final p in months.take(24))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(p.label),
                      subtitle: Text(
                        ledger.isClosed(p)
                            ? 'Closed'
                            : p == Period.of(today)
                            ? 'In progress'
                            : 'Not closed yet',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openScreen(context, ReportPreviewScreen.monthly(p)),
                    ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Annual report'),
                  Text(
                    'Month-by-month totals, savings growth, investments, loans and the Buying list.',
                    style: TextStyle(color: status.muted),
                  ),
                  for (final y in years)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.summarize_outlined),
                      title: Text('$y'),
                      subtitle: y == today.year ? const Text('Year so far') : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openScreen(context, ReportPreviewScreen.annual(y)),
                    ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Export for Excel'),
                  Text(
                    'All entries as a CSV file: date, type, category, amount, from, to, note.',
                    style: TextStyle(color: status.muted),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final y in years.take(3))
                        OutlinedButton(
                          onPressed: () => _exportCsv(context, ledger, y),
                          child: Text('$y'),
                        ),
                      OutlinedButton(
                        onPressed: () => _exportCsv(context, ledger, null),
                        child: const Text('Everything'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, Ledger ledger, int? year) async {
    final bytes = entriesCsv(ledger, year: year);
    final name = csvFileName(year);
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SheetBody(
        title: name,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'save'),
            icon: const Icon(Icons.save_alt),
            label: const Text('Save to phone'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'share'),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
        ],
      ),
    );
    if (choice == 'save') {
      final uri = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'text/csv');
      if (uri != null && context.mounted) showSnack(context, 'Saved $name');
    } else if (choice == 'share') {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: name, mimeType: 'text/csv')],
          fileNameOverrides: [name],
        ),
      );
    }
  }
}

/// Shows a report with Android's print and share actions, plus "save to
/// phone".
class ReportPreviewScreen extends ConsumerWidget {
  const ReportPreviewScreen.monthly(Period this.period, {super.key}) : year = null;

  const ReportPreviewScreen.annual(int this.year, {super.key}) : period = null;

  final Period? period;
  final int? year;

  String get _title => period != null ? period!.label : 'Annual $year';

  String get _fileName =>
      period != null ? monthlyReportFileName(period!) : annualReportFileName(year!);

  Future<Uint8List> _build(Ledger ledger, ReportFonts fonts) => period != null
      ? buildMonthlyReport(ledger, period!, fonts: fonts, generatedAt: DateTime.now())
      : buildAnnualReport(ledger, year!, fonts: fonts, generatedAt: DateTime.now());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).value;
    final fonts = ref.watch(reportFontsProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          // Labelled buttons here instead of the preview's own unlabelled
          // print and share bar, so screen readers can name them.
          if (ledger != null && fonts != null) ...[
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () async =>
                  Printing.sharePdf(bytes: await _build(ledger, fonts), filename: _fileName),
            ),
            IconButton(
              tooltip: 'Print',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => Printing.layoutPdf(
                name: _fileName,
                format: PdfPageFormat.a4,
                onLayout: (_) => _build(ledger, fonts),
              ),
            ),
            IconButton(
              tooltip: 'Save to phone',
              icon: const Icon(Icons.save_alt),
              onPressed: () async {
                final bytes = await _build(ledger, fonts);
                final uri = await FilePicker.saveFile(
                  fileName: _fileName,
                  bytes: bytes,
                  mimeType: 'application/pdf',
                );
                if (uri != null && context.mounted) showSnack(context, 'Saved $_fileName');
              },
            ),
          ],
        ],
      ),
      body: ledger == null || fonts == null
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (_) => _build(ledger, fonts),
              initialPageFormat: PdfPageFormat.a4,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              useActions: false,
              pdfFileName: _fileName,
            ),
    );
  }
}
