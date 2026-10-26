import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/home/home_screen.dart';
import 'package:my_fin_tracker/features/home/money_details_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Home and its details screen, at Galaxy S24 size.
void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
  });
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    Widget home = const Scaffold(body: HomeScreen()),
    Map<String, String> settings = const {},
    Brightness brightness = Brightness.light,
  }) async {
    final ledger = await tester.runAsync(() async {
      final repo = LedgerRepository(db);
      for (final MapEntry(:key, :value) in settings.entries) {
        await repo.setSetting(key, value);
      }
      return Ledger.load(db);
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger!)),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(theme: buildTheme(brightness), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('history, the main card and its breakdown (${brightness.name})', (tester) async {
      await pump(tester, brightness: brightness);
      // Left to spend ৳24,420 − bills ৳4,000.
      expect(find.text('LEFT TO SPEND AFTER BILLS'), findsOneWidget);
      expect(find.text('৳20,420'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Budget by category'), 300);
      expect(find.text('Left to spend'), findsOneWidget);
      expect(find.textContaining('Bank ৳'), findsWidgets, reason: 'where the spending money is');
      expect(find.text('Bills to pay'), findsOneWidget);

      await tester.ensureVisible(find.text('Budget by category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budget by category'));
      await tester.pumpAndSettle();
      final open = await tester.runAsync(
        () async => (await Ledger.load(db)).settings[homeCollapsedSetting],
      );
      expect(open, contains('breakdown+'));
      await tester.scrollUntilVisible(find.text('RECENT'), 300);
      expect(find.text('See all'), findsOneWidget);
    });
  }

  testWidgets('the breakdown lists each budget and offers Cover when over', (tester) async {
    await tester.runAsync(() async {
      final l = await Ledger.load(db);
      final ration = l.categories.values.firstWhere((c) => c.name == 'Ration').id;
      final bank = l.accounts.values.firstWhere((a) => a.name == 'Bank').id;
      await LedgerRepository(db).expense(
        DateTime(2026, 10, 7),
        taka(20000),
        categoryId: ration,
        from: (account: bank, fund: l.spendingFund.id),
      );
    });
    await pump(tester, settings: {homeCollapsedSetting: 'breakdown+'});
    await tester.scrollUntilVisible(find.text('Hide budget by category'), 300);
    expect(find.text('Ration'), findsWidgets);
    expect(find.text('Cover'), findsWidgets);
  });

  testWidgets('folded sections stay folded', (tester) async {
    await pump(tester, settings: {homeCollapsedSetting: 'attention,history'});
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(find.text('No backup yet'), findsNothing);
    expect(find.text('See all'), findsNothing);
    await tester.scrollUntilVisible(find.text('RECENT'), 300);
    await tester.tap(find.text('RECENT'));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(
      () async => (await Ledger.load(db)).settings[homeCollapsedSetting],
    );
    expect(saved, 'attention', reason: 'Recent opened again');
  });

  testWidgets("What it's for opens the details", (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('WHAT YOUR MONEY IS FOR'), 300);
    await tester.scrollUntilVisible(find.text('Sector'), 300);
    // Sectors down the side, accounts across.
    expect(find.text('Spending'), findsWidgets);
    expect(find.text('Monthly Savings'), findsOneWidget);
    expect(find.text('Bank'), findsWidgets);
    expect(find.text('Cash'), findsWidgets);
    expect(find.text('1,32,920'), findsOneWidget, reason: 'bank + cash + wallets');
    await tester.ensureVisible(find.text('WHAT YOUR MONEY IS FOR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WHAT YOUR MONEY IS FOR'));
    await tester.pumpAndSettle();
    expect(find.text('EVERY POT'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('৳4,28,770'), 300);
    expect(find.textContaining('Net worth', findRichText: true), findsOneWidget);
  });

  testWidgets('income straight into savings is shown apart, not in the sum', (tester) async {
    await tester.runAsync(() async {
      final l = await Ledger.load(db);
      final other = l.categories.values.firstWhere((c) => c.name == 'Other income').id;
      final bank = l.accounts.values.firstWhere((a) => a.name == 'Bank').id;
      final savings = l.funds.values.firstWhere((f) => f.name == 'Monthly Savings').id;
      await LedgerRepository(db).income(
        DateTime(2026, 10, 7),
        taka(5000),
        categoryId: other,
        to: (account: bank, fund: savings),
      );
    });
    await pump(tester, home: const MoneyDetailsScreen());
    await tester.scrollUntilVisible(
      find.text('Also received: Other income ৳5,000 → Monthly Savings'),
      300,
    );
    expect(find.text('Other income'), findsNothing, reason: 'not a row of the sum');
  });
}
