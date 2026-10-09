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
import 'package:my_fin_tracker/features/quick_add/quick_add_sheet.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Records what quick add asks the repository to write.
class RecordingRepository extends LedgerRepository {
  RecordingRepository(super.db);

  final expenses =
      <({DateTime date, Poisha amount, int categoryId, Pot from, String note, int? trackerId})>[];
  final purchases = <({String item, Poisha amount, int? entryId})>[];
  final settingsWritten = <String, String>{};

  @override
  Future<int> expense(
    DateTime date,
    Poisha amount, {
    required int categoryId,
    required Pot from,
    String note = '',
    int? trackerId,
  }) async {
    expenses.add((
      date: date,
      amount: amount,
      categoryId: categoryId,
      from: from,
      note: note,
      trackerId: trackerId,
    ));
    return 41;
  }

  @override
  Future<int> addPurchase({
    required String item,
    required DateTime date,
    required Poisha amount,
    int? entryId,
    String shop = '',
    DateTime? warrantyUntil,
    String note = '',
  }) async {
    purchases.add((item: item, amount: amount, entryId: entryId));
    return 1;
  }

  @override
  Future<void> setSetting(String key, String value) async => settingsWritten[key] = value;
}

void main() {
  late AppDatabase db;
  late Ledger sample;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    sample = await Ledger.load(db);
  });

  tearDownAll(() => db.close());

  testWidgets('an expense in three taps: amount, category, save', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    final repo = RecordingRepository(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(sample)),
          repositoryProvider.overrideWithValue(repo),
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

    // Most used first; nothing chosen yet, so save is disabled.
    expect(find.text('Ration'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Cash · Spending'), findsOneWidget);

    for (final key in ['3', '5', '0']) {
      await tester.tap(find.text(key).last);
    }
    await tester.tap(find.text('Ration'));
    await tester.pumpAndSettle();
    expect(find.text('Save ৳350 to Ration'), findsOneWidget);

    await tester.tap(find.text('Save ৳350 to Ration'));
    await tester.pumpAndSettle();

    final ration = sample.categories.values.firstWhere((c) => c.name == 'Ration');
    expect(repo.expenses, hasLength(1));
    expect(repo.expenses.single.amount, taka(350));
    expect(repo.expenses.single.categoryId, ration.id);
    expect(repo.expenses.single.date, DateTime(2026, 10, 8));
    expect(repo.settingsWritten.keys, contains('last_expense_pot'));
    expect(find.text('Saved ৳350 · Ration'), findsOneWidget);
  });

  testWidgets('number pad limits decimals to poisha', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(sample)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: QuickAddSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in ['1', '2', '5', '0', '0', '.', '5', '0', '9']) {
      await tester.tap(find.text(key).last);
    }
    await tester.pump();
    // 1-2-5-0-0 . 5-0, and the third decimal (9) is ignored.
    expect(find.textContaining('12,500.50', findRichText: true), findsOneWidget);
  });

  testWidgets('a major purchase tagged to a tracker', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    final repo = RecordingRepository(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(sample)),
          repositoryProvider.overrideWithValue(repo),
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
    for (final key in ['2', '4', '0', '0']) {
      await tester.tap(find.text(key).last);
    }
    await tester.tap(find.text('Random'));
    await tester.tap(find.text('Major purchase'));
    await tester.tap(find.text('Sylhet Trip'));
    await tester.enterText(find.byType(TextField), 'Bus tickets');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save ৳2,400 to Random'));
    await tester.tap(find.text('Save ৳2,400 to Random'));
    await tester.pumpAndSettle();

    final trip = sample.trackers.values.firstWhere((t) => t.name == 'Sylhet Trip');
    expect(repo.expenses.single.trackerId, trip.id);
    expect(repo.purchases.single, (item: 'Bus tickets', amount: taka(2400), entryId: 41));
  });

  testWidgets('paid-from picker with many accounts and goals fits and scrolls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);

    final big = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await loadSampleData(big);
    for (final name in ['City Bank', 'BRAC Bank', 'Dutch-Bangla Bank', 'EBL', 'Nagad', 'Rocket']) {
      await big
          .into(big.accounts)
          .insert(AccountsCompanion.insert(name: name, type: AccountType.bank));
    }
    for (var i = 1; i <= 10; i++) {
      await big
          .into(big.funds)
          .insert(FundsCompanion.insert(name: 'Goal number $i', kind: FundKind.goal));
    }
    final ledger = await Ledger.load(big);
    await big.close();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
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
    await tester.tap(find.text('Cash · Spending'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'no overflow');
    expect(find.text('Goal number 10'), findsOneWidget);
    expect(find.text('Refrigerator'), findsNothing, reason: 'achieved goals are hidden');
    expect(find.text('Investments'), findsNothing, reason: 'not a place to pay from');
    // The button stays reachable.
    await tester.tap(find.text('City Bank'));
    await tester.pump();
    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();
    expect(find.text('City Bank · Spending'), findsOneWidget);
  });
}
