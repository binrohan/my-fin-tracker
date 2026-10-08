import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/cash/cash_screen.dart';
import 'package:my_fin_tracker/features/home/home_screen.dart';
import 'package:my_fin_tracker/features/loans/loans_screen.dart';
import 'package:my_fin_tracker/features/save/fund_screen.dart';
import 'package:my_fin_tracker/features/more/more_screen.dart';
import 'package:my_fin_tracker/features/save/save_screen.dart';
import 'package:my_fin_tracker/features/spend/spend_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Draws each tab at Galaxy S24 size (384 × 832 dp) with the example data.
/// A layout overflow or exception fails the test.
void main() {
  late Ledger sample;
  late Ledger empty;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
    empty = await Ledger.load(db);
    await loadSampleData(db);
    sample = await Ledger.load(db);
    await db.close();
  });

  Future<void> pump(WidgetTester tester, Widget screen, Ledger ledger,
      {Brightness brightness = Brightness.light, bool fullScreen = false}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
        todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness),
        home: fullScreen ? screen : Scaffold(body: screen),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      testWidgets('Home shows the October figures', (tester) async {
        await pump(tester, const HomeScreen(), sample, brightness: brightness);
        expect(find.text('October 2026'), findsOneWidget);
        expect(find.text('৳24,420'), findsWidgets);
        expect(find.text('≈ ৳1,018 a day for 24 days'), findsOneWidget);
        expect(find.text('৳1,23,970'), findsOneWidget);
        expect(find.text('৳1,32,920'), findsNWidgets(2));
        expect(find.text('✓ Balanced'), findsOneWidget);
        expect(find.text('September 2026 is over'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('৳4,28,770'), 300);
        expect(find.text('৳4,28,770'), findsOneWidget);
      });

      testWidgets('Spend shows budget against actual', (tester) async {
        await pump(tester, const SpendScreen(), sample, brightness: brightness);
        expect(find.text('৳32,700'), findsOneWidget);
        expect(find.text('of ৳54,280'), findsOneWidget);
        expect(find.text('Fixed'), findsOneWidget);
        expect(find.text('due 15 Oct'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Pay 2 remaining fixed bills · ৳4,000'), 300);
        expect(find.text('Pay 2 remaining fixed bills · ৳4,000'), findsOneWidget);
      });

      testWidgets('Save shows goals and loans', (tester) async {
        await pump(tester, const SaveScreen(), sample, brightness: brightness);
        expect(find.text('৳68,000'), findsOneWidget);
        expect(find.text('৳2,250 owed back'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
        expect(find.text('On track'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Lent to Karim'), 300);
        expect(find.text('Lent to Karim'), findsOneWidget);
      });

      testWidgets('More lists setup and backup', (tester) async {
        await pump(tester, const MoreScreen(), sample, brightness: brightness);
        expect(find.text('Backup & restore'), findsOneWidget);
        expect(find.text('No backup yet'), findsOneWidget);
        expect(find.text('Starting balances'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('5% of the amount'), 300);
        expect(find.text('5% of the amount'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Load example'), 300);
        expect(find.text('Load example'), findsOneWidget);
      });
    });
  }

  group('Phase 3 screens', () {
    int fund(String name) => sample.funds.values.firstWhere((f) => f.name == name).id;

    for (final brightness in Brightness.values) {
      testWidgets('goal screen (${brightness.name})', (tester) async {
        await pump(tester, FundScreen(fundId: fund('New Laptop')), sample,
            brightness: brightness, fullScreen: true);
        expect(find.text('New Laptop'), findsOneWidget);
        expect(find.text('৳26,500'), findsWidgets);
        expect(find.text('Buy it'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
      });

      testWidgets('savings screen (${brightness.name})', (tester) async {
        await pump(tester, FundScreen(fundId: fund('Monthly Savings')), sample,
            brightness: brightness, fullScreen: true);
        expect(find.text('৳2,250 borrowed, to be paid back'), findsOneWidget);
        expect(find.text('Borrow'), findsOneWidget);
      });

      testWidgets('loans, both tabs (${brightness.name})', (tester) async {
        await pump(tester, const LoansScreen(), sample, brightness: brightness, fullScreen: true);
        expect(find.text('From Monthly Savings'), findsOneWidget);
        await tester.tap(find.text('People'));
        await tester.pumpAndSettle();
        expect(find.text('Lent to Karim'), findsOneWidget);
        expect(find.text('Borrowed from Brother'), findsOneWidget);
        expect(find.text('৳6,000'), findsWidgets);
        expect(find.text('৳10,000'), findsWidgets);
      });

      testWidgets('one loan (${brightness.name})', (tester) async {
        final own = sample.loans.firstWhere((l) => l.personAccountId == null);
        await pump(tester, LoanScreen(loanId: own.id), sample,
            brightness: brightness, fullScreen: true);
        expect(find.text('Pay back'), findsOneWidget);
        expect(find.text('Charge 5%'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('TIMELINE'), 300);
        expect(find.text('TIMELINE'), findsOneWidget);
      });

      testWidgets('cash drawer (${brightness.name})', (tester) async {
        await pump(tester, const CashScreen(), sample, brightness: brightness, fullScreen: true);
        expect(find.text('৳7,300'), findsOneWidget);
        expect(find.text('Motorbike'), findsOneWidget);
        expect(find.text('Count cash'), findsOneWidget);
        await tester.tap(find.text('Count cash'));
        await tester.pumpAndSettle();
        expect(find.text('৳1000'), findsOneWidget);
      });
    }
  });

  testWidgets('Home before any entries', (tester) async {
    await pump(tester, const HomeScreen(), empty);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Enter starting balances'), findsOneWidget);
  });
}
