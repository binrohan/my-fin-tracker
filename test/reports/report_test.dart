import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/reports/annual_report.dart';
import 'package:my_fin_tracker/reports/csv_export.dart';
import 'package:my_fin_tracker/reports/monthly_report.dart';
import 'package:my_fin_tracker/reports/pdf_kit.dart';

/// Set REPORT_OUT to a folder to keep the generated PDFs for a look.
final outDir = Platform.environment['REPORT_OUT'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Ledger ledger;
  late ReportFonts fonts;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await loadSampleData(db);
    await LedgerRepository(db).closeMonth(const Period(2026, 9), confirmedBank: 7492000);
    ledger = await Ledger.load(db);
    await db.close();
    fonts = await ReportFonts.load();
  });

  Future<void> keep(String name, List<int> bytes) async {
    if (outDir != null) await File('$outDir/$name').writeAsBytes(bytes);
  }

  test('September monthly report', () async {
    final bytes = await buildMonthlyReport(
      ledger,
      const Period(2026, 9),
      fonts: fonts,
      generatedAt: DateTime(2026, 10, 1, 8, 15),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    await keep('monthly-2026-09.pdf', bytes);
  });

  test('October (month in progress) monthly report', () async {
    final bytes = await buildMonthlyReport(
      ledger,
      const Period(2026, 10),
      fonts: fonts,
      generatedAt: DateTime(2026, 10, 8, 21),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    await keep('monthly-2026-10.pdf', bytes);
  });

  test('annual report 2026', () async {
    expect(reportMonths(ledger, 2026, DateTime(2026, 10, 8)), [
      const Period(2026, 9),
      const Period(2026, 10),
    ]);
    final bytes = await buildAnnualReport(
      ledger,
      2026,
      fonts: fonts,
      generatedAt: DateTime(2026, 10, 8, 21),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    await keep('annual-2026.pdf', bytes);
  });

  test('annual report for a year without entries', () async {
    final bytes = await buildAnnualReport(
      ledger,
      2025,
      fonts: fonts,
      generatedAt: DateTime(2026, 10, 8),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('CSV export', () async {
    final bytes = entriesCsv(ledger, year: 2026);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final lines = String.fromCharCodes(bytes.skip(3)).split('\r\n');
    expect(lines.first, 'Date,Type,Category,Amount,From,To,Note,Tracker,Loan');
    final text = utf8.decode(bytes.skip(3).toList());
    expect(text, contains('2026-09-01,income,Salary,85000.00,,Bank · Spending,,,'));
    expect(
      text,
      contains('2026-09-18,expense,Mine,-1250.00,Bank · Spending,,Desk lamp,Home Office Setup,'),
    );
    expect(text, contains('2026-09-14,borrow,,5000.00,Bank · Monthly Savings,Bank · Spending,'));
    expect(text, contains('"Vegetables, Karwan Bazar"'));
    await keep('entries-2026.csv', bytes);
  });
}
