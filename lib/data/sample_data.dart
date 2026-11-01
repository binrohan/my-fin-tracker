import 'package:drift/drift.dart';

import '../core/money.dart';
import '../core/period.dart';
import '../ledger/enums.dart';
import 'database.dart';
import 'ledger_repository.dart';

/// Replaces all data with the example used in the plan, the screen designs
/// and the example report: opening balances on 31 Aug 2026, all of
/// September, and 1–7 October.
///
/// The tests check every figure in the example report against this data.
Future<void> loadSampleData(AppDatabase db) => db.transaction(() async {
  await db.resetAllData();
  final repo = LedgerRepository(db);

  // --- lookups for the default data ---
  Future<int> accountId(String name) async =>
      (await (db.select(db.accounts)..where((a) => a.name.equals(name))).getSingle()).id;
  Future<int> fundId(String name) async =>
      (await (db.select(db.funds)..where((f) => f.name.equals(name))).getSingle()).id;
  Future<int> categoryId(String name) async =>
      (await (db.select(db.categories)..where((c) => c.name.equals(name))).getSingle()).id;

  final bank = await accountId('Bank');
  final cash = await accountId('Cash');
  final bkash = await accountId('bKash');
  final spending = await fundId('This month');
  final savings = await fundId('Monthly Savings');
  final investments = await fundId('Investments');

  Future<int> addAccount(String name, AccountType type, int order) => db
      .into(db.accounts)
      .insert(AccountsCompanion.insert(name: name, type: type, sortOrder: Value(order)));
  final dps = await addAccount('DPS · Bank', AccountType.investment, 10);
  final certificate = await addAccount('Savings certificate', AccountType.investment, 11);
  final karim = await addAccount('Karim', AccountType.person, 20);
  final brother = await addAccount('Brother', AccountType.person, 21);

  Future<int> addGoal(String name, int target, DateTime by, int order) => db
      .into(db.funds)
      .insert(
        FundsCompanion.insert(
          name: name,
          kind: FundKind.goal,
          targetAmount: Value(taka(target)),
          targetDate: Value(by),
          sortOrder: Value(order),
        ),
      );
  final laptop = await addGoal('New Laptop', 95000, DateTime(2027, 3, 31), 10);
  final motorbike = await addGoal('Motorbike', 150000, DateTime(2029, 12, 31), 11);

  // Investment details for the two investment accounts.
  for (final (account, kind, start, maturity, rate, instalment, total, paid) in [
    (dps, InvestmentKind.dps, DateTime(2025, 4, 1), DateTime(2030, 4, 1), 750, 5000, 60, 17),
    (
      certificate,
      InvestmentKind.savingsCertificate,
      DateTime(2024, 3, 15),
      DateTime(2029, 3, 15),
      1150,
      null,
      null,
      0,
    ),
  ]) {
    await repo.saveInvestmentDetails(
      InvestmentDetailsCompanion.insert(
        accountId: Value(account),
        kind: kind,
        startDate: Value(start),
        maturityDate: Value(maturity),
        rateBp: Value(rate),
        instalment: Value(instalment == null ? null : taka(instalment)),
        totalInstalments: Value(total),
        openingInstalments: Value(paid),
      ),
    );
  }

  // A goal reached before September, and what it bought.
  final fridge = await addGoal('Refrigerator', 62500, DateTime(2026, 6, 30), 12);
  await repo.setGoalAchieved(fridge, DateTime(2026, 6, 14));
  await repo.addPurchase(
    item: 'Refrigerator',
    date: DateTime(2026, 6, 14),
    amount: taka(62500),
    shop: 'Walton Plaza',
    warrantyUntil: DateTime(2031, 6, 14),
  );

  // Trackers that started before the app: what was spent before is opening.
  final office = await repo.addTracker(
    name: 'Home Office Setup',
    kind: TrackerKind.project,
    startDate: DateTime(2026, 3, 1),
    openingSpent: taka(37500),
  );
  await repo.addTracker(
    name: 'Sylhet Trip',
    kind: TrackerKind.countdown,
    startDate: DateTime(2026, 8, 15),
    endDate: DateTime(2026, 12, 18),
    budget: taka(25000),
    openingSpent: taka(4000),
  );

  final rent = await categoryId('House Rent');
  final electricity = await categoryId('Electricity');
  final gas = await categoryId('Gas');
  final internet = await categoryId('Internet');
  final water = await categoryId('Water & Service');
  final ration = await categoryId('Ration');
  final random = await categoryId('Random');
  final mine = await categoryId('Mine');
  final salary = await categoryId('Salary');
  final bonus = await categoryId('Bonus');

  Pot pot(int account, int fund) => (account: account, fund: fund);
  DateTime d(int month, int day) => DateTime(2026, month, day);

  // --- budgets (same for both months) ---
  for (final period in [const Period(2026, 9), const Period(2026, 10)]) {
    for (final (cat, amount) in [
      (rent, 25000),
      (electricity, 2500),
      (gas, 1080),
      (internet, 1200),
      (water, 1500),
      (ration, 14000),
      (random, 5000),
      (mine, 4000),
    ]) {
      await repo.setBudget(period, cat, taka(amount));
    }
  }

  // --- opening balances, 31 Aug 2026 ---
  final open = d(8, 31);
  for (final (p, amount) in [
    (pot(bank, spending), 300),
    (pot(bank, savings), 27500),
    (pot(bank, laptop), 10500),
    (pot(bank, motorbike), 4000),
    (pot(cash, spending), 1700),
    (pot(cash, savings), 2500),
    (pot(cash, motorbike), 2000),
    (pot(bkash, spending), 1500),
    (pot(dps, investments), 89620),
    (pot(certificate, investments), 200000),
  ]) {
    await repo.openingBalance(open, p, taka(amount));
  }
  await repo.openExistingLoan(
    kind: LoanKind.lent,
    person: karim,
    fundId: savings,
    principal: taka(10000),
    alreadyRepaid: taka(4000),
    date: d(8, 2),
    dueDate: d(11, 30),
    openingDate: open,
  );
  await repo.openExistingLoan(
    kind: LoanKind.borrowed,
    person: brother,
    fundId: spending,
    principal: taka(15000),
    alreadyRepaid: taka(5000),
    date: d(7, 10),
    openingDate: open,
  );

  // --- September 2026 ---
  await repo.income(d(9, 1), taka(85000), categoryId: salary, to: pot(bank, spending));
  await _salaryAllocation(
    repo,
    d(9, 1),
    pot(bank, spending),
    savings: pot(bank, savings),
    laptop: pot(bank, laptop),
    motorbike: pot(bank, motorbike),
    dps: pot(dps, investments),
    dpsNote: 'DPS instalment 18 of 60',
  );
  await repo.expense(d(9, 2), taka(25000), categoryId: rent, from: pot(bank, spending));
  await repo.move(
    d(9, 3),
    taka(10000),
    from: pot(bank, spending),
    to: pot(cash, spending),
    note: 'Cash withdrawal',
  );
  await repo.expense(d(9, 3), taka(4800), categoryId: ration, from: pot(cash, spending));
  await repo.move(
    d(9, 4),
    taka(1700),
    from: pot(bank, spending),
    to: pot(bkash, spending),
    note: 'bKash top-up',
  );
  await repo.expense(d(9, 5), taka(1080), categoryId: gas, from: pot(bank, spending));
  await repo.expense(d(9, 5), taka(1200), categoryId: internet, from: pot(bkash, spending));
  await repo.expense(
    d(9, 8),
    taka(1100),
    categoryId: mine,
    from: pot(cash, spending),
    note: 'Haircut, tea',
  );
  await repo.expense(d(9, 10), taka(1500), categoryId: water, from: pot(bank, spending));
  await repo.expense(d(9, 10), taka(3250), categoryId: ration, from: pot(cash, spending));
  final fan = await repo.expense(
    d(9, 12),
    taka(3400),
    categoryId: random,
    from: pot(bank, spending),
    note: 'Ceiling fan',
  );
  await repo.addPurchase(
    item: 'Ceiling fan',
    date: d(9, 12),
    amount: taka(3400),
    entryId: fan,
    shop: 'Walton Plaza',
    warrantyUntil: DateTime(2028, 9, 12),
  );
  await repo.expense(
    d(9, 13),
    taka(2600),
    categoryId: random,
    from: pot(bank, spending),
    note: 'Medicine',
  );
  final ownLoan = await repo.borrowFromFund(
    d(9, 14),
    taka(5000),
    sourceFund: savings,
    intoFund: spending,
    account: bank,
    note: 'Over budget: ceiling fan + medicine',
  );
  await repo.expense(d(9, 15), taka(2180), categoryId: electricity, from: pot(bank, spending));
  await repo.expense(d(9, 17), taka(2900), categoryId: ration, from: pot(cash, spending));
  await repo.move(
    d(9, 18),
    taka(8670),
    from: pot(bank, spending),
    to: pot(cash, spending),
    note: 'Cash withdrawal',
  );
  await repo.expense(
    d(9, 18),
    taka(1250),
    categoryId: mine,
    from: pot(bank, spending),
    note: 'Desk lamp',
    trackerId: office,
  );
  await repo.expense(
    d(9, 20),
    taka(500),
    categoryId: random,
    from: pot(cash, spending),
    note: 'Rickshaw, misc',
  );
  await repo.expense(d(9, 22), taka(800), categoryId: mine, from: pot(cash, spending));
  await repo.expense(d(9, 24), taka(2470), categoryId: ration, from: pot(cash, spending));
  await repo.income(
    d(9, 25),
    taka(10000),
    categoryId: bonus,
    to: pot(bank, spending),
    note: 'Performance bonus',
  );
  await repo.expense(d(9, 26), taka(350), categoryId: random, from: pot(cash, spending));
  await repo.repayOwnLoan(ownLoan, d(9, 28), taka(2000), from: pot(bank, spending));

  // --- October 2026, up to the 7th ---
  await repo.income(d(10, 1), taka(85000), categoryId: salary, to: pot(bank, spending));
  await _salaryAllocation(
    repo,
    d(10, 1),
    pot(bank, spending),
    savings: pot(bank, savings),
    laptop: pot(bank, laptop),
    motorbike: pot(bank, motorbike),
    dps: pot(dps, investments),
    dpsNote: 'DPS instalment 19 of 60',
  );
  await repo.adjust(d(10, 1), pot(dps, investments), taka(230), note: 'DPS profit update');
  await repo.expense(d(10, 2), taka(25000), categoryId: rent, from: pot(bank, spending));
  await repo.move(
    d(10, 3),
    taka(4020),
    from: pot(bank, spending),
    to: pot(cash, spending),
    note: 'Cash withdrawal',
  );
  await repo.expense(d(10, 3), taka(4000), categoryId: ration, from: pot(cash, spending));
  await repo.move(
    d(10, 4),
    taka(850),
    from: pot(bank, spending),
    to: pot(bkash, spending),
    note: 'bKash top-up',
  );
  await repo.expense(d(10, 4), taka(500), categoryId: random, from: pot(cash, spending));
  await repo.expense(d(10, 5), taka(1200), categoryId: internet, from: pot(bkash, spending));
  await repo.expense(d(10, 5), taka(1080), categoryId: gas, from: pot(bank, spending));
  await repo.repayOwnLoan(ownLoan, d(10, 5), taka(1000), from: pot(bank, spending));
  await repo.expense(d(10, 6), taka(450), categoryId: mine, from: pot(cash, spending));
  await repo.expense(
    d(10, 7),
    taka(350),
    categoryId: ration,
    from: pot(cash, spending),
    note: 'Vegetables, Karwan Bazar',
  );
  await repo.expense(
    d(10, 7),
    taka(120),
    categoryId: random,
    from: pot(cash, spending),
    note: 'Rickshaw',
  );
});

Future<void> _salaryAllocation(
  LedgerRepository repo,
  DateTime date,
  Pot from, {
  required Pot savings,
  required Pot laptop,
  required Pot motorbike,
  required Pot dps,
  required String dpsNote,
}) async {
  await repo.move(date, taka(20000), from: from, to: savings, note: 'Monthly saving');
  await repo.move(date, taka(8000), from: from, to: laptop);
  await repo.move(date, taka(4000), from: from, to: motorbike);
  await repo.move(date, taka(5000), from: from, to: dps, note: dpsNote);
}
