import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Paying a loan back out of Spending takes it from a category's budget,
/// so the budgets still add up to the money you have.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);
  final day = DateTime(2026, 10, 10);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;
  Poisha budgetOf(String name) => ledger
      .categoryLines(oct, CategoryKind.expense)
      .expand((l) => [l, ...l.children])
      .firstWhere((l) => l.category.name == name)
      .budget;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  Future<int> borrow() => repo.borrowFromFund(
    day,
    taka(250),
    sourceFund: fund('Monthly Savings'),
    intoFund: ledger.spendingFund.id,
    account: account('Bank'),
  );

  test('borrowing adds money not in any budget', () async {
    final before = ledger.summary(oct);
    await borrow();
    await reload();
    final after = ledger.summary(oct);
    expect(after.leftToSpend - before.leftToSpend, taka(250));
    expect(after.unplanned - before.unplanned, taka(250));
    expect(after.budgetLeft, before.budgetLeft, reason: 'budgets do not change');
  });

  test('paying back from a budget lowers that budget for the month', () async {
    final random = budgetOf('Random');
    final before = ledger.summary(oct);
    final loan = await borrow();
    await repo.repayOwnLoan(
      loan,
      day,
      taka(250),
      from: (account: account('Bank'), fund: ledger.spendingFund.id),
      budgetCategoryId: category('Random'),
    );
    await reload();
    expect(budgetOf('Random'), random - taka(250));
    final after = ledger.summary(oct);
    expect(after.leftToSpend, before.leftToSpend);
    expect(after.budgetLeft, before.budgetLeft - taka(250));
    expect(ledger.budgetDeltas(oct.next)[category('Random')], isNull);
  });

  test('paying back without a budget leaves the budgets as they were', () async {
    final before = ledger.summary(oct);
    final loan = await borrow();
    await repo.repayOwnLoan(
      loan,
      day,
      taka(250),
      from: (account: account('Bank'), fund: ledger.spendingFund.id),
    );
    await reload();
    final after = ledger.summary(oct);
    expect(after.budgetLeft, before.budgetLeft);
    expect(after.unplanned, before.unplanned);
  });

  test('deleting the repayment gives the budget back', () async {
    final random = budgetOf('Random');
    final loan = await borrow();
    final paid = await repo.repayOwnLoan(
      loan,
      day,
      taka(250),
      from: (account: account('Bank'), fund: ledger.spendingFund.id),
      budgetCategoryId: category('Random'),
    );
    await repo.deleteEntry(paid);
    await reload();
    expect(budgetOf('Random'), random);
  });
}
