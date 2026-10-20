import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Salary on the 26th is next month's money: held apart, then released on
/// the 1st with the plan's split.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);
  const nov = Period(2026, 11);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String n) => ledger.categories.values.firstWhere((c) => c.name == n).id;
  int fund(String n) => ledger.funds.values.firstWhere((f) => f.name == n).id;
  int account(String n) => ledger.accounts.values.firstWhere((a) => a.name == n).id;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
    await repo.setSetting(
      AllocationPlan.settingKey,
      AllocationPlan(
        categoryId: category('Salary'),
        incomes: [
          IncomeSource(
            categoryId: category('Salary'),
            amount: taka(85000),
            day: 26,
            accountId: account('Bank'),
            forNextMonth: true,
          ),
        ],
        items: [
          AllocationItem(fundId: fund('Monthly Savings'), amount: taka(20000)),
          AllocationItem(fundId: fund('New Laptop'), amount: taka(8000)),
        ],
      ).encode(),
    );
    await repo.incomeForNextMonth(
      DateTime(2026, 10, 26),
      taka(85000),
      categoryId: category('Salary'),
      account: account('Bank'),
    );
    await reload();
  });
  tearDown(() => db.close());

  test('the plan remembers which income is for next month', () {
    expect(ledger.latestPlan.sourceFor(category('Salary'))!.forNextMonth, isTrue);
    expect(AllocationPlan.parse(ledger.latestPlan.encode()).incomes.single.forNextMonth, isTrue);
  });

  test('held on 26 October: in the bank, not in the October spending', () {
    final s = ledger.summary(oct);
    expect(s.leftToSpend, taka(24420), reason: 'unchanged by the held salary');
    expect(s.heldForNext, taka(85000));
    expect(s.checks, isTrue);
    expect(ledger.heldForNextMonth, taka(85000));
    expect(ledger.accountBalance(account('Bank')), taka(123970 + 85000));
    expect(ledger.isBalanced, isTrue);
    expect(ledger.heldIncomes(oct).single.amount, taka(85000));
    expect(ledger.releaseDue(DateTime(2026, 10, 31)), isEmpty);
    expect(ledger.releaseDue(DateTime(2026, 11, 1)), [
      (account: account('Bank'), amount: taka(85000)),
    ]);
  });

  test('released on 1 November with the planned split', () async {
    final result = await repo.releaseHeldIncome(DateTime(2026, 11, 1));
    expect(result, (released: taka(85000), setAside: taka(28000)));
    await reload();
    final s = ledger.summary(nov);
    expect(s.carriedForward, taka(24420));
    expect(s.released, taka(85000));
    expect(s.monthIncome, taka(85000));
    expect(s.setAside, taka(28000));
    expect(s.leftToSpend, taka(24420 + 85000 - 28000));
    expect(s.checks, isTrue);
    expect(ledger.heldForNextMonth, 0);
    expect(ledger.summary(oct).leftToSpend, taka(24420), reason: 'October is not changed');
    final release = ledger.entries.firstWhere((e) => e.note == 'Income for November 2026');
    expect(release.date, DateTime(2026, 11, 1));

    // Opening the app again later in November releases nothing more.
    final again = await repo.releaseHeldIncome(DateTime(2026, 11, 9));
    expect(again, (released: 0, setAside: 0));
  });

  test('the split can be skipped when recording', () async {
    await repo.setSetting(LedgerRepository.splitOnReleaseKey(nov), 'false');
    await reload();
    final result = await repo.releaseHeldIncome(DateTime(2026, 11, 1));
    expect(result, (released: taka(85000), setAside: 0));
  });

  test('held income opened late (on 3 December) is still released', () async {
    final result = await repo.releaseHeldIncome(DateTime(2026, 12, 3));
    expect(result.released, taka(85000));
    await reload();
    expect(
      ledger.entries.firstWhere((e) => e.note == 'Income for December 2026').date,
      DateTime(2026, 12, 1),
    );
  });
}
