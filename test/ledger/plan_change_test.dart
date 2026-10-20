import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/tax.dart';

/// A raise from November: the plan changes from next month, October keeps
/// its own. Salary of 26 October is November's money.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);
  const nov = Period(2026, 11);
  const dec = Period(2026, 12);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String n) => ledger.categories.values.firstWhere((c) => c.name == n).id;
  int fund(String n) => ledger.funds.values.firstWhere((f) => f.name == n).id;
  int account(String n) => ledger.accounts.values.firstWhere((a) => a.name == n).id;

  AllocationPlan plan(Poisha salary, Poisha savings) => AllocationPlan(
    categoryId: category('Salary'),
    incomes: [
      IncomeSource(
        categoryId: category('Salary'),
        amount: salary,
        day: 26,
        accountId: account('Bank'),
        forNextMonth: true,
      ),
    ],
    items: [AllocationItem(fundId: fund('Monthly Savings'), amount: savings)],
  );
  Poisha budget(Period p, String name) => ledger
      .categoryLines(p, CategoryKind.expense, withMoves: false)
      .expand((l) => [l, ...l.children])
      .firstWhere((l) => l.category.name == name)
      .budget;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
    await repo.setSetting(AllocationPlan.settingKey, plan(taka(85000), taka(20000)).encode());
    // The raise, set up in October to start in November.
    await repo.setSetting(Ledger.planKeyFrom(nov), plan(taka(100000), taka(30000)).encode());
    await repo.setBudget(nov, category('Ration'), taka(16000));
    await reload();
  });
  tearDown(() => db.close());

  test('each month has its own plan and budgets', () {
    expect(ledger.planChanges, [nov]);
    expect(ledger.planFor(oct).plannedIncome, taka(85000));
    expect(ledger.planFor(nov).plannedIncome, taka(100000));
    expect(ledger.planFor(dec).plannedIncome, taka(100000));
    expect(ledger.planFor(const Period(2026, 7)).plannedIncome, taka(85000));
    expect(ledger.latestPlan.plannedIncome, taka(100000));
    expect(budget(oct, 'Ration'), taka(14000), reason: 'October is untouched');
    expect(budget(nov, 'Ration'), taka(16000));
    expect(budget(dec, 'Ration'), taka(16000));
  });

  test('the salary of 26 October is split with November\'s plan', () async {
    await repo.incomeForNextMonth(
      DateTime(2026, 10, 26),
      taka(100000),
      categoryId: category('Salary'),
      account: account('Bank'),
    );
    final before = (await Ledger.load(db)).fundBalance(fund('Monthly Savings'));
    final result = await repo.releaseHeldIncome(DateTime(2026, 11, 1));
    await reload();
    expect(result.released, taka(100000));
    expect(result.setAside, taka(30000));
    expect(ledger.fundBalance(fund('Monthly Savings')), before + taka(30000));
  });

  test('the reminder expects the new amount from November', () {
    final due = ledger.incomesDue(DateTime(2026, 11, 27)).single;
    expect(due.amount, taka(100000));
    expect(ledger.planFor(oct).sourceFor(category('Salary'))!.amount, taka(85000));
  });

  test('the raised salary arriving on 26 October is expected at the new amount', () {
    final october = ledger.planFor(oct).sourceFor(category('Salary'))!;
    expect(october.amount, taka(85000));
    // It is November's money, so November's plan says what to expect.
    expect(ledger.expectedIncome(october, oct).amount, taka(100000));
    expect(ledger.expectedIncome(october, oct).forNextMonth, isTrue);
    // An income spent in the month it arrives keeps its own month's amount.
    final sameMonth = IncomeSource(categoryId: category('Salary'), amount: taka(85000), day: 1);
    expect(ledger.expectedIncome(sameMonth, oct).amount, taka(85000));
  });

  test('tax: old salary until October, new from November', () {
    final app = TaxFromApp.of(ledger, const IncomeYear(2026), DateTime(2026, 10, 8));
    var expected = 0;
    for (var p = const Period(2026, 7); p.compareTo(const Period(2027, 6)) <= 0; p = p.next) {
      final recorded = ledger.entries
          .where(
            (e) =>
                e.type == EntryType.income &&
                e.categoryId == category('Salary') &&
                p.contains(e.date),
          )
          .fold<Poisha>(0, (t, e) => t + e.amount);
      expected += recorded > 0 ? recorded : (p.compareTo(nov) < 0 ? taka(85000) : taka(100000));
    }
    expect(app.salary, expected);
  });

  test('cancelling puts November back on the October plan', () async {
    await repo.deleteSetting(Ledger.planKeyFrom(nov));
    await repo.deleteBudgetsOf(nov);
    await reload();
    expect(ledger.planChanges, isEmpty);
    expect(ledger.planFor(nov).plannedIncome, taka(85000));
    expect(budget(nov, 'Ration'), taka(14000));
  });

  test('a plan first made as a change also covers earlier months', () async {
    await repo.deleteSetting(AllocationPlan.settingKey);
    await reload();
    expect(ledger.planFor(const Period(2026, 7)).plannedIncome, taka(100000));
  });
}
