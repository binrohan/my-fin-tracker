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
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/reminders.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

/// Saving part of a budget to a pot during the month, e.g. the fixed
/// "Rice Bag" ৳1,000 into a Rice Bag pot.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);
  final today = DateTime(2026, 10, 8);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  CategoryLine line(String name) {
    CategoryLine? found;
    void walk(CategoryLine l) {
      if (l.category.name == name) found = l;
      l.children.forEach(walk);
    }

    ledger.categoryLines(oct, CategoryKind.expense).forEach(walk);
    return found!;
  }

  Future<int> save(String name, Poisha amount, {String pot = 'Monthly Savings'}) async {
    final id = await repo.saveBudgetToPot(
      categoryId: category(name),
      categoryName: name,
      account: ledger.spendingCells(oct).first.account,
      spendingFund: ledger.spendingFund.id,
      fundId: fund(pot),
      amount: amount,
      date: today,
    );
    await reload();
    return id;
  }

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  test('budget and left to spend drop together, so nothing is short', () async {
    final before = ledger.summary(oct);
    final randomBefore = line('Random').budget;
    final savingsBefore = ledger.fundBalance(fund('Monthly Savings'));

    await save('Random', taka(1000));

    final after = ledger.summary(oct);
    expect(line('Random').budget, randomBefore - taka(1000));
    expect(after.leftToSpend, before.leftToSpend - taka(1000));
    expect(after.budgetLeft, before.budgetLeft - taka(1000));
    expect(after.unplanned, before.unplanned);
    expect(ledger.fundBalance(fund('Monthly Savings')), savingsBefore + taka(1000));
    expect(ledger.savedDuring(oct), {category('Random'): taka(1000)});
    expect(ledger.isBalanced, isTrue);
    // The Monthly plan's budget stays as it was.
    final plan = ledger.categoryLines(oct, CategoryKind.expense, withMoves: false);
    expect(plan.firstWhere((l) => l.category.name == 'Random').budget, randomBefore);
  });

  test('a fixed bill saved in full is no longer due', () async {
    final water = line('Water & Service');
    expect(ledger.unpaidFixedBills(oct).map((b) => b.category.name), contains('Water & Service'));
    expect(
      remindersFor(ledger, today).map((r) => r.title),
      contains('Water & Service due in 2 days'),
    );

    await save('Water & Service', water.remaining);

    expect(line('Water & Service').budget, water.budget - water.remaining);
    expect(
      ledger.unpaidFixedBills(oct).map((b) => b.category.name),
      isNot(contains('Water & Service')),
    );
    expect(
      remindersFor(ledger, today).where((r) => r.title.startsWith('Water & Service')),
      isEmpty,
    );
  });

  test('closing the month does not save it again', () async {
    await SetupRepository(db)
        .updateCategory(category('Random'), savingsFundId: Value(fund('Monthly Savings')));
    await reload();
    final unusedBefore = ledger.unusedBudgetMoves(oct).single.amount;

    await save('Random', taka(1000));

    expect(ledger.unusedBudgetMoves(oct).single.amount, unusedBefore - taka(1000));
  });

  test('undo puts the budget and the money back', () async {
    final before = ledger.summary(oct);
    final id = await save('Random', taka(1000));
    await repo.deleteEntry(id);
    await reload();
    expect(ledger.summary(oct).leftToSpend, before.leftToSpend);
    expect(ledger.summary(oct).budget, before.budget);
    expect(ledger.savedDuring(oct), isEmpty);
  });

  test('backups keep it', () async {
    await save('Random', taka(1000));
    final copy = memoryDb();
    await Backup.restore(copy, Backup.read(await Backup.export(db)));
    final restored = await Ledger.load(copy);
    expect(restored.savedDuring(oct), {category('Random'): taka(1000)});
    await copy.close();
  });

  test('a version 5 database upgrades with its data intact', () async {
    final schemaV5 = File('test/fixtures/schema_v5.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schemaV5);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
            raw.execute("INSERT INTO categories (name, kind) VALUES ('Ration', 'expense')");
            raw.execute(
              "INSERT INTO entries (date, type, amount, category_id, note, receipt) "
              "VALUES (1791331200, 'expense', 125000, 1, 'Shwapno', 'receipt-1.jpg')",
            );
            raw.execute(
              'INSERT INTO postings (entry_id, account_id, fund_id, amount) VALUES (1, 1, 1, -125000)',
            );
            raw.execute('PRAGMA user_version = 5');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    final l = await Ledger.load(old);
    expect(l.entries.single.receipt, 'receipt-1.jpg');
    expect(l.entries.single.budgetSave, isNull);
    expect(l.liquidTotal(), -taka(1250));
    final version = await old.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, old.schemaVersion);
    await old.close();
  });
}
