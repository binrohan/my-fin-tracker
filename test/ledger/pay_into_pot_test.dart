import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/data/setup_repository.dart';
import 'package:my_fin_tracker/features/quick_add/quick_add_sheet.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/free_to_spend.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

/// A bill paid into a pot (the Cycle instalment put aside as cash in the
/// "Cycle parked" pot): it counts as paid, and the money stays in the pot.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late SetupRepository setup;
  late Ledger ledger;
  late int cycle;
  late int parked;
  const oct = Period(2026, 10);
  const nov = Period(2026, 11);
  final today = DateTime(2026, 10, 8);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  Map<String, Poisha> bills(Period p) => {
    for (final b in ledger.unpaidFixedBills(p)) b.category.name: b.remaining,
  };
  CategoryLine line(String name, [Period p = oct]) => ledger
      .categoryLines(p, CategoryKind.expense)
      .expand((l) => [l, ...l.children])
      .firstWhere((l) => l.category.name == name);

  Future<int> pay(Poisha amount, {String from = 'Bank', String into = 'Cash'}) async {
    final id = await repo.payIntoPot(
      categoryId: cycle,
      categoryName: 'Cycle',
      fromAccount: account(from),
      spendingFund: ledger.spendingFund.id,
      toAccount: account(into),
      fundId: parked,
      amount: amount,
      date: today,
    );
    await reload();
    return id;
  }

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    setup = SetupRepository(db);
    await loadSampleData(db);
    parked = await setup.addFund('Cycle parked', FundKind.savings);
    cycle = await setup.addCategory(
      'Cycle',
      CategoryKind.expense,
      isFixed: true,
      dueDay: 10,
      savingsFundId: parked,
    );
    await repo.setBudget(oct, cycle, taka(3000));
    await reload();
  });
  tearDown(() => db.close());

  test('counts as paid, and the money moves to the pot in another account', () async {
    expect(bills(oct)['Cycle'], taka(3000));
    final before = FreeToSpend.of(ledger, today);
    final s = ledger.summary(oct);
    final cashBefore = ledger.accountBalance(account('Cash'));

    await pay(taka(3000));

    expect(bills(oct), isNot(contains('Cycle')));
    expect(line('Cycle').budget, taka(3000));
    expect(line('Cycle').actual, taka(3000));
    expect(ledger.cell(account('Cash'), parked), taka(3000));
    expect(ledger.accountBalance(account('Cash')), cashBefore + taka(3000));
    final after = ledger.summary(oct);
    expect(after.leftToSpend, s.leftToSpend - taka(3000));
    expect(after.budgetLeft, s.budgetLeft - taka(3000));
    expect(after.unplanned, s.unplanned);
    // Not money gone: liquid total and spent-from-accounts stay the same.
    expect(after.expenses, s.expenses);
    expect(ledger.liquidTotal(), before.summary.closingLiquid);
    // What is free to spend was already net of the bill.
    expect(FreeToSpend.of(ledger, today).free, before.free);
    expect(ledger.isBalanced, isTrue);
  });

  test('part of a bill leaves the rest to pay', () async {
    await pay(taka(1000), into: 'Bank');
    expect(bills(oct)['Cycle'], taka(2000));
    expect(ledger.cell(account('Bank'), parked), taka(1000));
  });

  test('month close does not save it again', () async {
    await pay(taka(3000));
    expect(ledger.unusedBudgetMoves(oct).where((m) => m.category.id == cycle), isEmpty);
    expect(ledger.savedAtCloseIn(oct), isNot(contains(cycle)));
    expect(ledger.savedDuring(oct), isNot(contains(cycle)));
    expect(ledger.paidToPots(oct), {cycle: taka(3000)});
    expect(ledger.paidToPots(nov), isEmpty);
  });

  test('deleting it brings the bill back', () async {
    final id = await pay(taka(3000));
    await repo.deleteEntry(id);
    await reload();
    expect(bills(oct)['Cycle'], taka(3000));
    expect(ledger.cell(account('Cash'), parked), 0);
  });

  test('moves tied to a budget are not edited in Quick add', () async {
    final paid = await pay(taka(1000));
    final saved = await repo.saveBudgetToPot(
      categoryId: category('Random'),
      categoryName: 'Random',
      account: account('Bank'),
      spendingFund: ledger.spendingFund.id,
      fundId: parked,
      amount: taka(500),
      date: today,
    );
    final plain = await repo.move(
      today,
      taka(100),
      from: (account: account('Bank'), fund: ledger.spendingFund.id),
      to: (account: account('Cash'), fund: ledger.spendingFund.id),
    );
    await reload();
    Entry entry(int id) => ledger.entries.firstWhere((e) => e.id == id);
    expect(canEditInQuickAdd(entry(paid)), isFalse);
    expect(canEditInQuickAdd(entry(saved)), isFalse);
    expect(canEditInQuickAdd(entry(plain)), isTrue);
  });

  test('backups keep it', () async {
    await pay(taka(3000));
    final copy = memoryDb();
    await Backup.restore(copy, Backup.read(await Backup.export(db)));
    final restored = await Ledger.load(copy);
    expect(restored.paidToPots(oct), {cycle: taka(3000)});
    expect(restored.unpaidFixedBills(oct).map((b) => b.category.name), isNot(contains('Cycle')));
    await copy.close();
  });

  group('budget lists follow the month as it began', () {
    Iterable<String> names(Period p) => ledger.budgetCategoriesIn(p).map((c) => c.name);

    setUp(() async {
      await repo.ensureMonthSnapshot(oct);
      await reload();
    });

    test('a category that gets subsections mid-month stays movable this month', () async {
      await setup.addCategory('Abbu', CategoryKind.expense, parentId: category('Random'));
      await reload();
      expect(names(oct), contains('Random'));
      expect(names(oct), isNot(contains('Abbu')));
      expect(names(nov), containsAll(['Abbu']));
      expect(names(nov), isNot(contains('Random')));
      expect(ledger.movableFrom(category('Random'), oct), line('Random').remaining);
    });

    test('an archived category stays until the month ends; a new one waits', () async {
      await setup.updateCategory(category('Random'), archived: true);
      await repo.setSetting(Ledger.archivedFromKey(category('Random')), nov.toString());
      await setup.addCategory('Abbu 2', CategoryKind.expense);
      await reload();
      expect(names(oct), contains('Random'));
      expect(names(oct), isNot(contains('Abbu 2')));
      expect(names(nov), isNot(contains('Random')));
      expect(names(nov), contains('Abbu 2'));
    });

    test('quick add offers the old and the new until the month ends', () async {
      await setup.updateCategory(category('Random'), archived: true);
      await repo.setSetting(Ledger.archivedFromKey(category('Random')), nov.toString());
      await setup.addCategory('Abbu', CategoryKind.expense, parentId: category('Ration'));
      await reload();
      Iterable<String> quick(Period p) =>
          ledger.leafCategories(CategoryKind.expense, month: p).map((c) => c.name);
      expect(quick(oct), containsAll(['Random', 'Ration', 'Abbu']));
      expect(quick(oct).where((n) => n == 'Random'), hasLength(1));
      expect(quick(nov), contains('Abbu'));
      expect(quick(nov), isNot(contains('Random')));
      expect(quick(nov), isNot(contains('Ration')));
    });

    test('no slots, no sections', () async {
      expect(names(oct), isNot(contains('Fixed')));
      expect(names(oct), containsAll(['House Rent', 'Ration', 'Random', 'Cycle']));
    });
  });

  test('a version 8 database upgrades with its data intact', () async {
    final schema = File('test/fixtures/schema_v8.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schema);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('This month', 'spending')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Floating', 'unplanned')");
            raw.execute("INSERT INTO categories (name, kind) VALUES ('Ration', 'expense')");
            raw.execute(
              "INSERT INTO entries (date, type, amount, note) "
              "VALUES (1791331200, 'opening', 5000000, '')",
            );
            raw.execute(
              'INSERT INTO postings (entry_id, account_id, fund_id, amount) '
              'VALUES (1, 1, 1, 5000000)',
            );
            raw.execute(
              "INSERT INTO entries (date, type, amount, category_id, note, budget_save) "
              "VALUES (1791331200, 'move', 100000, 1, 'Saved', 1)",
            );
            raw.execute('PRAGMA user_version = 8');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    final l = await Ledger.load(old);
    expect(old.schemaVersion, 9);
    expect(l.entries, hasLength(2));
    expect(l.liquidTotal(), taka(50000));
    expect(l.entries.map((e) => e.paidToPot), everyElement(isNull));
    expect(l.entries.where((e) => e.budgetSave == true), hasLength(1));
    await old.close();
  });
}
