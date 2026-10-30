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

/// The Monthly plan is a blueprint used when income arrives: pots are
/// filled at once, the spending part is parked (or spent now), the rest
/// goes to Unplanned.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const nov = Period(2026, 11);
  final arrived = DateTime(2026, 10, 26);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String n) => ledger.categories.values.firstWhere((c) => c.name == n).id;
  int fund(String n) => ledger.funds.values.firstWhere((f) => f.name == n).id;
  int account(String n) => ledger.accounts.values.firstWhere((a) => a.name == n).id;
  late AllocationPlan plan;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
    plan = AllocationPlan(
      categoryId: category('Salary'),
      incomes: [
        IncomeSource(
          categoryId: category('Salary'),
          amount: taka(90000),
          day: 26,
          accountId: account('Bank'),
          forNextMonth: true,
        ),
      ],
      items: [
        AllocationItem(fundId: fund('Monthly Savings'), amount: taka(20000)),
        AllocationItem(fundId: fund('New Laptop'), amount: taka(8000)),
      ],
      expenseTarget: taka(60000),
    );
    await repo.setSetting(AllocationPlan.settingKey, plan.encode());
    await reload();
  });
  tearDown(() => db.close());

  test('salary for next month: pots now, spending part parked, rest to Unplanned', () async {
    final savings = ledger.fundBalance(fund('Monthly Savings'));
    final laptop = ledger.fundBalance(fund('New Laptop'));
    final bank = ledger.accountBalance(account('Bank'));
    final october = ledger.summary(const Period(2026, 10)).leftToSpend;

    await repo.receiveIncome(
      arrived,
      taka(100000),
      categoryId: category('Salary'),
      account: account('Bank'),
      to: IncomeTo.nextMonth,
      split: plan,
    );
    await reload();

    expect(ledger.fundBalance(fund('Monthly Savings')), savings + taka(20000));
    expect(ledger.fundBalance(fund('New Laptop')), laptop + taka(8000));
    expect(ledger.heldForNextMonth, taka(60000), reason: 'only the spending part is parked');
    expect(ledger.unplannedMoney, taka(12000), reason: '1,00,000 − 28,000 − 60,000');
    expect(ledger.accountBalance(account('Bank')), bank + taka(100000));
    expect(
      ledger.summary(const Period(2026, 10)).leftToSpend,
      october,
      reason: 'October unchanged',
    );
    expect(ledger.isBalanced, isTrue);

    // On the 1st only the parked part is released; nothing is split again.
    final result = await repo.releaseHeldIncome(DateTime(2026, 11, 1));
    await reload();
    expect((result.released, result.setAside), (taka(60000), 0));
    expect(ledger.fundBalance(fund('Monthly Savings')), savings + taka(20000));
    expect(ledger.summary(nov).released, taka(60000));
  });

  test('a salary below the plan fills pots first, parks what is left', () async {
    await repo.receiveIncome(
      arrived,
      taka(70000),
      categoryId: category('Salary'),
      account: account('Bank'),
      to: IncomeTo.nextMonth,
      split: plan,
    );
    await reload();
    expect(ledger.heldForNextMonth, taka(42000));
    expect(ledger.unplannedMoney, 0);
  });

  test('a bonus goes where you choose, whole', () async {
    final before = ledger.fundBalance(fund('Monthly Savings'));
    await repo.receiveIncome(
      arrived,
      taka(30000),
      categoryId: category('Bonus'),
      account: account('Bank'),
      to: IncomeTo.pot,
      potFund: fund('Monthly Savings'),
    );
    await repo.receiveIncome(
      arrived,
      taka(5000),
      categoryId: category('Bonus'),
      account: account('Bank'),
      to: IncomeTo.unplanned,
    );
    await reload();
    expect(ledger.fundBalance(fund('Monthly Savings')), before + taka(30000));
    expect(ledger.unplannedMoney, taka(5000));
    expect(ledger.heldForNextMonth, 0);
  });

  test('catch-up: a salary held whole under the old rules is split once', () async {
    final savings = ledger.fundBalance(fund('Monthly Savings'));
    await repo.incomeForNextMonth(
      arrived,
      taka(100000),
      categoryId: category('Salary'),
      account: account('Bank'),
    );
    await reload();
    expect(ledger.heldForNextMonth, taka(100000));

    final split = await repo.splitHeldSalary(DateTime(2026, 10, 30));
    await reload();
    expect(split, (setAside: taka(28000), unplanned: taka(12000)));
    expect(ledger.heldForNextMonth, taka(60000));
    expect(ledger.fundBalance(fund('Monthly Savings')), savings + taka(20000));
    expect(ledger.unplannedMoney, taka(12000));
    expect(await repo.splitHeldSalary(DateTime(2026, 10, 31)), isNull, reason: 'only once');

    final result = await repo.releaseHeldIncome(DateTime(2026, 11, 1));
    expect((result.released, result.setAside), (taka(60000), 0));
  });

  test('overspending is counted on its own', () async {
    expect(ledger.overBudget(const Period(2026, 10)), 0);
    final ration = ledger
        .categoryLines(const Period(2026, 10), CategoryKind.expense)
        .firstWhere((l) => l.category.name == 'Ration');
    await repo.expense(
      DateTime(2026, 10, 7),
      ration.remaining + taka(1500),
      categoryId: category('Ration'),
      from: (account: account('Bank'), fund: ledger.spendingFund.id),
    );
    await reload();
    expect(ledger.overBudget(const Period(2026, 10)), taka(1500));
  });
}
