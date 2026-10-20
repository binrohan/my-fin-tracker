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
import 'package:my_fin_tracker/ledger/ledger.dart';

/// The two Homes and folding sections, at Galaxy S24 size.
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
        child: MaterialApp(
          theme: buildTheme(brightness),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('After bills: free to spend with the sum (${brightness.name})', (tester) async {
      await pump(tester, settings: {homeStyleSetting: homeAfterBills}, brightness: brightness);
      // Left to spend ৳24,420 − bills ৳4,000.
      expect(find.text('FREE TO SPEND'), findsOneWidget);
      expect(find.text('৳20,420'), findsWidgets);
      expect(find.text('Bills still to pay'), findsOneWidget);
      expect(find.text('−৳4,000'), findsOneWidget);
      expect(find.text('BILLS TO PAY'), findsOneWidget);
      expect(find.text('Pay all · ৳4,000'), findsOneWidget);
      // Bills are listed once, not again under Needs attention.
      expect(find.text('Water & Service due in 2 days'), findsNothing);
    });
  }

  testWidgets('Standard Home keeps left to spend first', (tester) async {
    await pump(tester);
    expect(find.text('LEFT TO SPEND'), findsOneWidget);
    expect(find.text('FREE TO SPEND'), findsNothing);
    expect(find.text('Water & Service due in 2 days'), findsOneWidget);
  });

  testWidgets('folded sections show a summary and stay folded', (tester) async {
    await pump(tester, settings: {homeCollapsedSetting: 'attention,month'});
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(find.text('Water & Service due in 2 days'), findsNothing);
    await tester.scrollUntilVisible(find.text('THIS MONTH'), 300);
    expect(find.text('Carried forward'), findsNothing);

    await tester.tap(find.text('THIS MONTH'));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(
      () async => (await Ledger.load(db)).settings[homeCollapsedSetting],
    );
    expect(saved, 'attention', reason: 'This month opened again');
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
    await pump(tester);
    await tester.scrollUntilVisible(
      find.text('Also received: Other income ৳5,000 → Monthly Savings'),
      300,
    );
    // Left to spend is unchanged by it.
    expect(find.text('৳24,420'), findsWidgets);
    expect(find.text('Other income'), findsNothing, reason: 'not a row of the sum');
  });
}
