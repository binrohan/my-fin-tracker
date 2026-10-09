import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/money.dart';

/// Fonts embedded in every report. IBM Plex has no ৳, so Hind Siliguri
/// (which covers Bengali) is the fallback for it.
class ReportFonts {
  const ReportFonts({
    required this.regular,
    required this.bold,
    required this.fallback,
    required this.fallbackBold,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font fallback;
  final pw.Font fallbackBold;

  static Future<ReportFonts> load() async {
    Future<pw.Font> font(String file) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
    return ReportFonts(
      regular: await font('IBMPlexSans-Regular.ttf'),
      bold: await font('IBMPlexSans-Bold.ttf'),
      fallback: await font('HindSiliguri-Regular.ttf'),
      fallbackBold: await font('HindSiliguri-Bold.ttf'),
    );
  }

  pw.ThemeData theme() =>
      pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        fontFallback: [fallback, fallbackBold],
      ).copyWith(
        defaultTextStyle: pw.TextStyle(font: regular, fontSize: 9, color: ReportColors.ink),
      );
}

/// The palette of the example report.
abstract final class ReportColors {
  static final ink = PdfColor.fromHex('#1A1F1C');
  static final muted = PdfColor.fromHex('#66706B');
  static final line = PdfColor.fromHex('#D9DFDB');
  static final soft = PdfColor.fromHex('#EEF4F1');
  static final accent = PdfColor.fromHex('#0D6A55');
  static final good = PdfColor.fromHex('#1D7A4B');
  static final bad = PdfColor.fromHex('#B3322B');

  /// Expenses, savings, goals, investments, unspent.
  static final allocation = [
    PdfColor.fromHex('#B85C38'),
    PdfColor.fromHex('#0D6A55'),
    PdfColor.fromHex('#4E9C86'),
    PdfColor.fromHex('#8DB8AB'),
    PdfColor.fromHex('#C9D3CE'),
  ];
}

/// Amounts in tables: lakh grouping, no ৳ (the header says BDT).
String amt(Poisha value) => formatTaka(value, symbol: false);

String signedAmt(Poisha value) => formatTaka(value, symbol: false, showPlus: true);

String pct(num value) => '${value.toStringAsFixed(1)}%';

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');
String dayMonth(DateTime d) => _dayMonth.format(d);
String dayMonthYear(DateTime d) => _dayMonthYear.format(d);

pw.Widget reportHeader({required String title, required String subtitle}) => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 8),
  margin: const pw.EdgeInsets.only(bottom: 12),
  decoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: ReportColors.accent, width: 3)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: pw.TextStyle(fontSize: 8.5, color: ReportColors.muted)),
          ],
        ),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'MY FIN TRACKER',
            style: pw.TextStyle(fontSize: 7.5, color: ReportColors.muted, letterSpacing: 1),
          ),
          pw.Text(
            'Amounts in BDT (৳)',
            style: pw.TextStyle(fontSize: 7.5, color: ReportColors.muted),
          ),
        ],
      ),
    ],
  ),
);

pw.Widget reportFooter(pw.Context context, String label) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 8),
  padding: const pw.EdgeInsets.only(top: 5),
  decoration: pw.BoxDecoration(
    border: pw.Border(top: pw.BorderSide(color: ReportColors.line)),
  ),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 7, color: ReportColors.muted)),
      pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 7, color: ReportColors.muted),
      ),
    ],
  ),
);

/// A row of headline figures; the last one is shaded.
pw.Widget kpiRow(List<(String, String)> items) => pw.Container(
  decoration: pw.BoxDecoration(border: pw.Border.all(color: ReportColors.line)),
  child: pw.Row(
    children: [
      for (final (i, (label, value)) in items.indexed)
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: pw.BoxDecoration(
              color: i == items.length - 1 ? ReportColors.soft : null,
              border: i == items.length - 1
                  ? null
                  : pw.Border(right: pw.BorderSide(color: ReportColors.line)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label.toUpperCase(),
                  style: pw.TextStyle(fontSize: 6, color: ReportColors.muted, letterSpacing: .6),
                ),
                pw.SizedBox(height: 2),
                pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ),
    ],
  ),
);

/// A shaded box with a coloured left rule.
pw.Widget noteBox(pw.Widget child, {PdfColor? rule}) => pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  decoration: pw.BoxDecoration(
    color: ReportColors.soft,
    border: pw.Border(left: pw.BorderSide(color: rule ?? ReportColors.good, width: 3)),
  ),
  child: child,
);

pw.Widget sectionTitle(String title, {String? note}) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 12, bottom: 4),
  padding: const pw.EdgeInsets.only(bottom: 2),
  decoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: ReportColors.ink, width: 1.2)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      if (note != null) pw.Text(note, style: pw.TextStyle(fontSize: 7, color: ReportColors.muted)),
    ],
  ),
);

enum RowStyle { normal, sub, total }

/// One table row: text cells, how it looks, and optional cell colours.
class ReportRow {
  const ReportRow(this.cells, {this.style = RowStyle.normal, this.colors = const {}});

  final List<String> cells;
  final RowStyle style;

  /// Cell index → text colour.
  final Map<int, PdfColor> colors;
}

/// A report table. Columns after the first are right-aligned numbers
/// unless listed in [textColumns].
pw.Widget table({
  List<String>? headers,
  required List<ReportRow> rows,
  Map<int, pw.TableColumnWidth>? widths,
  Set<int> textColumns = const {0},
  Map<int, pw.Widget Function(ReportRow row)> custom = const {},
}) {
  pw.Widget cell(String text, int index, ReportRow? row, {bool header = false}) {
    final style = row?.style ?? RowStyle.normal;
    final right = !textColumns.contains(index);
    return pw.Container(
      alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      padding: pw.EdgeInsets.fromLTRB(index == 0 && style == RowStyle.sub ? 12 : 4, 2.5, 4, 2.5),
      child: pw.Text(
        header ? text.toUpperCase() : text,
        style: pw.TextStyle(
          fontSize: header ? 6.5 : 8.5,
          letterSpacing: header ? .5 : 0,
          color: header
              ? ReportColors.muted
              : row?.colors[index] ??
                    (style == RowStyle.sub ? ReportColors.muted : ReportColors.ink),
          fontWeight: style == RowStyle.total ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  return pw.Table(
    columnWidths: widths,
    border: pw.TableBorder(horizontalInside: pw.BorderSide(color: ReportColors.line, width: .5)),
    children: [
      if (headers != null)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: ReportColors.ink, width: .8)),
          ),
          children: [for (final (i, h) in headers.indexed) cell(h, i, null, header: true)],
        ),
      for (final row in rows)
        pw.TableRow(
          decoration: row.style == RowStyle.total
              ? pw.BoxDecoration(
                  color: ReportColors.soft,
                  border: pw.Border(top: pw.BorderSide(color: ReportColors.ink, width: .6)),
                )
              : null,
          children: [
            for (final (i, text) in row.cells.indexed)
              if (custom[i] != null)
                pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                  child: custom[i]!(row),
                )
              else
                cell(text, i, row),
          ],
        ),
    ],
  );
}

/// A small horizontal progress bar with its percentage.
pw.Widget progress(double value, {bool over = false}) => pw.Row(
  mainAxisSize: pw.MainAxisSize.min,
  children: [
    pw.Container(
      width: 46,
      height: 4,
      color: ReportColors.line,
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 46 * value.clamp(0, 1),
        height: 4,
        color: over ? ReportColors.bad : ReportColors.accent,
      ),
    ),
    pw.SizedBox(width: 4),
    pw.Text(
      '${(value * 100).round()}%',
      style: pw.TextStyle(fontSize: 8, color: over ? ReportColors.bad : ReportColors.ink),
    ),
  ],
);

/// Two blocks side by side.
pw.Widget twoColumns(pw.Widget left, pw.Widget right) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Expanded(child: left),
    pw.SizedBox(width: 14),
    pw.Expanded(child: right),
  ],
);

pw.Widget muted(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 3),
  child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, color: ReportColors.muted)),
);
