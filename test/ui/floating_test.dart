import 'package:drift/drift.dart' hide isNull, isNotNull;
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
import 'package:my_fin_tracker/features/quick_add/quick_add_sheet.dart';
import 'package:my_fin_tracker/features/save/save_screen.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Quick add sends income to Floating; Floating can be used from Save.
void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget home) async {
    final ledger = await tester.runAsync(() => Ledger.load(db));
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
        child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('income not in the plan goes to Floating, with no next-month option', (tester) async {
    await pump(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showQuickAdd(context, mode: QuickAddMode.income),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('For November'), findsNothing);
    await tester.tap(find.text('5').last);
    await tester.tap(find.text('0').last);
    await tester.tap(find.text('Bonus'));
    await tester.pumpAndSettle();
    final save = find.textContaining('Save ৳50');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(save);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    final after = await tester.runAsync(() => Ledger.load(db));
    expect(after!.unplannedFund?.name, 'Floating');
    expect(after.unplannedMoney, taka(50));
  });

  testWidgets('Floating shows on Save and offers use and move', (tester) async {
    await tester.runAsync(() async {
      final l = await Ledger.load(db);
      await LedgerRepository(db).receiveIncome(
        DateTime(2026, 10, 7),
        taka(5000),
        categoryId: l.categories.values.firstWhere((c) => c.name == 'Bonus').id,
        account: l.accounts.values.firstWhere((a) => a.name == 'Bank').id,
        to: IncomeTo.unplanned,
      );
    });
    await pump(tester, const Scaffold(body: SaveScreen()));
    await tester.tap(find.textContaining('Floating', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Use money'), findsOneWidget);
    expect(find.text('Move to a section'), findsOneWidget);
    expect(find.text('Deposit'), findsNothing);
    expect(find.text('Borrow'), findsNothing);
    await tester.tap(find.text('Move to a section'));
    await tester.pumpAndSettle();
    expect(find.text('TO SECTION'), findsOneWidget);
  });
}
