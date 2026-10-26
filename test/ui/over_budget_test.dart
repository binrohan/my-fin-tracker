import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/quick_add/quick_add_sheet.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// An expense that would go over its budget asks to move budget first.
void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
  });
  tearDown(() => db.close());

  Future<Ledger> open(WidgetTester tester, String amount) async {
    final ledger = (await tester.runAsync(() => Ledger.load(db)))!;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showQuickAdd(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final key in amount.split('')) {
      await tester.tap(find.text(key).last);
    }
    await tester.tap(find.text('Ration'));
    await tester.pumpAndSettle();
    final save = find.textContaining('to Ration');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    return ledger;
  }

  int leftInRation(Ledger l) => l
      .budgetRoom(
        l.categories.values.firstWhere((c) => c.name == 'Ration').id,
        const Period(2026, 10),
      )!
      .left;

  testWidgets('over budget: asks, and Move opens the move sheet', (tester) async {
    final ledger = await open(tester, '99999');
    expect(leftInRation(ledger), lessThan(9999900));
    expect(find.text('Over the Ration budget'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Move ৳90,349'));
    await tester.pumpAndSettle();
    expect(find.text('Move budget · October 2026'), findsOneWidget);
    // Nothing recorded yet.
    final after = await tester.runAsync(() => Ledger.load(db));
    expect(after!.entries.length, ledger.entries.length);
  });

  testWidgets('Record anyway saves it', (tester) async {
    final ledger = await open(tester, '99999');
    await tester.tap(find.text('Record anyway'));
    await tester.pumpAndSettle();
    final after = await tester.runAsync(() => Ledger.load(db));
    expect(after!.entries.length, ledger.entries.length + 1);
    expect(after.entries.first.type, EntryType.expense);
  });

  testWidgets('within budget: no question', (tester) async {
    final ledger = await open(tester, '10');
    expect(find.text('Over the Ration budget'), findsNothing);
    final after = await tester.runAsync(() => Ledger.load(db));
    expect(after!.entries.length, ledger.entries.length + 1);
  });
}
