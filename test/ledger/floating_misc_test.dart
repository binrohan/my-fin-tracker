import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/default_data.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Floating money, the Misc section, and using pots directly.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);
  final day = DateTime(2026, 10, 10);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String n) => ledger.categories.values.firstWhere((c) => c.name == n).id;
  int fund(String n) => ledger.funds.values.firstWhere((f) => f.name == n).id;
  int account(String n) => ledger.accounts.values.firstWhere((a) => a.name == n).id;
  CategoryLine line(String n, [Period p = oct]) => ledger
      .categoryLines(p, CategoryKind.expense)
      .expand((l) => [l, ...l.children])
      .firstWhere((l) => l.category.name == n);

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  Future<void> planExpenses(Poisha target) async {
    await repo.setSetting(
      AllocationPlan.settingKey,
      AllocationPlan(categoryId: category('Salary'), expenseTarget: target).encode(),
    );
    await reload();
  }

  test('Misc takes what the sections leave, and comes last', () async {
    final sections = ledger.summary(oct).budget;
    await planExpenses(sections + taka(3000));
    expect(line('Misc').budget, taka(3000));
    expect(ledger.summary(oct).budget, sections + taka(3000));
    expect(ledger.categoryLines(oct, CategoryKind.expense).last.category.name, 'Misc');
  });

  test('Misc has nothing when the sections take it all', () async {
    await planExpenses(taka(100));
    expect(line('Misc').budget, 0);
  });

  test('moving budget out of a section does not grow Misc', () async {
    await planExpenses(ledger.summary(oct).budget + taka(3000));
    await repo.moveBudget(
      oct,
      from: category('Ration'),
      to: category('Random'),
      amount: taka(500),
      date: day,
    );
    await reload();
    expect(line('Misc').budget, taka(3000));
  });

  test('income beyond the plan floats, not tied to a month', () async {
    await repo.receiveIncome(
      day,
      taka(5000),
      categoryId: category('Bonus'),
      account: account('Bank'),
      to: IncomeTo.unplanned,
    );
    await reload();
    expect(ledger.funds[ledger.unplannedFund!.id]!.name, 'Floating');
    expect(ledger.unplannedMoney, taka(5000));
    expect(ledger.fundBalance(ledger.unplannedFund!.id, before: oct.next.end), taka(5000));
  });

  test('using a pot directly leaves every budget and this month alone', () async {
    final before = ledger.summary(oct);
    final pot = ledger.fundBalance(fund('Monthly Savings'));
    final bank = ledger.accountBalance(account('Bank'));
    final lines = line('Random').actual;
    await repo.usePot(day, taka(3000), (
      account: account('Bank'),
      fund: fund('Monthly Savings'),
    ), 'Tax paid');
    await reload();
    final after = ledger.summary(oct);
    expect(ledger.fundBalance(fund('Monthly Savings')), pot - taka(3000));
    expect(ledger.accountBalance(account('Bank')), bank - taka(3000));
    expect(after.leftToSpend, before.leftToSpend);
    expect(after.budget, before.budget);
    expect(after.budgetLeft, before.budgetLeft);
    expect(after.spendingExpenses, before.spendingExpenses);
    expect(line('Random').actual, lines);
    expect(ledger.isBalanced, isTrue);
  });

  test('moving pot money to a section grows its budget this month only', () async {
    final random = line('Random').budget;
    final left = ledger.summary(oct).leftToSpend;
    final bank = ledger.accountBalance(account('Bank'));
    final id = await repo.moveToSection(
      day,
      taka(2000),
      from: (account: account('Bank'), fund: fund('Monthly Savings')),
      categoryId: category('Random'),
      spendingFund: ledger.spendingFund.id,
    );
    await reload();
    expect(line('Random').budget, random + taka(2000));
    expect(line('Random', oct.next).budget, random);
    expect(ledger.summary(oct).leftToSpend, left + taka(2000));
    expect(ledger.accountBalance(account('Bank')), bank);
    expect(ledger.savedDuring(oct), isEmpty, reason: 'not a save to a pot');

    await repo.deleteEntry(id);
    await reload();
    expect(line('Random').budget, random);
    expect(ledger.summary(oct).leftToSpend, left);
  });

  group('upgrading a version 7 database', () {
    late AppDatabase old;

    setUp(() {
      final schema = File('test/fixtures/schema_v7.sql').readAsStringSync();
      old = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(
            setup: (raw) {
              raw.execute(schema);
              raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
              raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
              raw.execute("INSERT INTO funds (name, kind) VALUES ('Unplanned', 'unplanned')");
              raw.execute("INSERT INTO funds (name, kind) VALUES ('My Pot', 'savings')");
              raw.execute("INSERT INTO categories (name, kind) VALUES ('Ration', 'expense')");
              raw.execute(
                'INSERT INTO budgets (year, month, category_id, amount) '
                'VALUES (2026, 10, 1, 1400000)',
              );
              raw.execute(
                "INSERT INTO settings (key, value) VALUES ('allocation_plan', "
                "'{\"expenses\":2000000}')",
              );
              raw.execute(
                "INSERT INTO entries (date, type, amount, note) "
                "VALUES (1791331200, 'opening', 5000000, '')",
              );
              raw.execute(
                'INSERT INTO postings (entry_id, account_id, fund_id, amount) '
                'VALUES (1, 1, 1, 5000000)',
              );
              raw.execute('PRAGMA user_version = 7');
            },
          ),
          closeStreamsSynchronously: true,
        ),
      );
    });
    tearDown(() => old.close());

    test('keeps the money, renames, and adds Misc from this month', () async {
      final l = await Ledger.load(old);
      expect(l.liquidTotal(), taka(50000));
      expect(l.spendingFund.name, 'This month');
      expect(l.funds.values.map((f) => f.name), containsAll(['Floating', 'My Pot']));
      expect(l.miscCategory?.name, 'Misc');
      expect(l.settings[miscFromSetting], Period.current().toString());
      expect(
        l
            .categoryLines(oct, CategoryKind.expense)
            .firstWhere((x) => x.category.name == 'Misc')
            .budget,
        0,
        reason: 'months before the upgrade stay as they were',
      );
      final version = await old.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, old.schemaVersion);
    });

    test('setting up twice changes nothing', () async {
      await Ledger.load(old);
      final count = (await old.select(old.categories).get()).length;
      await setupFloatingAndMisc(old, DateTime(2030));
      expect((await old.select(old.categories).get()).length, count);
      final l = await Ledger.load(old);
      expect(l.settings[miscFromSetting], Period.current().toString());
    });
  });
}
