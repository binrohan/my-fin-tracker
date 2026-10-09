import 'package:drift/drift.dart';

import '../core/money.dart';
import '../core/period.dart';
import '../ledger/allocation.dart';
import '../ledger/enums.dart';
import '../ledger/ledger.dart';
import 'database.dart';

/// One side of a posting: an (account, fund) pair.
typedef Pot = ({int account, int fund});

/// Writes user actions as an entry plus balanced postings. Every write runs
/// in a transaction, so an entry never exists without its postings.
class LedgerRepository {
  LedgerRepository(this.db);

  final AppDatabase db;

  Future<int> _write({
    required DateTime date,
    required EntryType type,
    required Poisha amount,
    required List<(Pot, Poisha)> postings,
    int? categoryId,
    int? loanId,
    int? trackerId,
    String note = '',
  }) {
    assert(amount >= 0, 'Entry amounts are positive; postings carry the sign');
    return db.transaction(() async {
      final entryId = await db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              date: dateOnly(date),
              type: type,
              amount: amount,
              categoryId: Value(categoryId),
              loanId: Value(loanId),
              trackerId: Value(trackerId),
              note: Value(note),
            ),
          );
      for (final (pot, value) in postings) {
        await db
            .into(db.postings)
            .insert(
              PostingsCompanion.insert(
                entryId: entryId,
                accountId: pot.account,
                fundId: pot.fund,
                amount: value,
              ),
            );
      }
      return entryId;
    });
  }

  /// A starting balance when you begin using the app. Negative amounts are
  /// allowed (an overdrawn account).
  Future<int> openingBalance(
    DateTime date,
    Pot pot,
    Poisha amount, {
    String note = 'Opening balance',
  }) => _write(
    date: date,
    type: EntryType.opening,
    amount: amount.abs(),
    postings: [(pot, amount)],
    note: note,
  );

  Future<int> income(
    DateTime date,
    Poisha amount, {
    required int categoryId,
    required Pot to,
    String note = '',
    int? trackerId,
  }) => _write(
    date: date,
    type: EntryType.income,
    amount: amount,
    categoryId: categoryId,
    trackerId: trackerId,
    postings: [(to, amount)],
    note: note,
  );

  Future<int> expense(
    DateTime date,
    Poisha amount, {
    required int categoryId,
    required Pot from,
    String note = '',
    int? trackerId,
  }) => _write(
    date: date,
    type: EntryType.expense,
    amount: amount,
    categoryId: categoryId,
    trackerId: trackerId,
    postings: [(from, -amount)],
    note: note,
  );

  /// Set aside to savings, withdraw cash, pay a DPS instalment: anything that
  /// changes where money is or what it is for without leaving your hands.
  Future<int> move(
    DateTime date,
    Poisha amount, {
    required Pot from,
    required Pot to,
    String note = '',
  }) => _write(
    date: date,
    type: EntryType.move,
    amount: amount,
    postings: [(from, -amount), (to, amount)],
    note: note,
  );

  /// A correction: matching your bank app's balance, or updating an
  /// investment's current value.
  Future<int> adjust(DateTime date, Pot pot, Poisha delta, {String note = ''}) => _write(
    date: date,
    type: EntryType.adjust,
    amount: delta.abs(),
    postings: [(pot, delta)],
    note: note,
  );

  // ---------------------------------------------------------------- loans

  static Poisha chargeFor(Poisha principal, int rateBp) => (principal * rateBp / 10000).round();

  Future<int> _insertLoan({
    required LoanKind kind,
    required int fundId,
    required Poisha principal,
    required int chargeRateBp,
    required DateTime date,
    int? personAccountId,
    DateTime? dueDate,
    Poisha openingRepaid = 0,
    String note = '',
  }) => db
      .into(db.loans)
      .insert(
        LoansCompanion.insert(
          kind: kind,
          personAccountId: Value(personAccountId),
          fundId: fundId,
          principal: principal,
          chargeRateBp: Value(chargeRateBp),
          charge: Value(chargeFor(principal, chargeRateBp)),
          openingRepaid: Value(openingRepaid),
          date: dateOnly(date),
          dueDate: Value(dueDate == null ? null : dateOnly(dueDate)),
          note: Value(note),
        ),
      );

  /// Borrow from Monthly Savings or a goal. The money moves to [intoFund] in
  /// the same account; the charge is added to what you owe the source fund.
  Future<int> borrowFromFund(
    DateTime date,
    Poisha amount, {
    required int sourceFund,
    required int intoFund,
    required int account,
    int chargeRateBp = 500,
    String note = '',
  }) => db.transaction(() async {
    final loanId = await _insertLoan(
      kind: LoanKind.ownSavings,
      fundId: sourceFund,
      principal: amount,
      chargeRateBp: chargeRateBp,
      date: date,
      note: note,
    );
    await _write(
      date: date,
      type: EntryType.borrow,
      amount: amount,
      loanId: loanId,
      postings: [
        ((account: account, fund: sourceFund), -amount),
        ((account: account, fund: intoFund), amount),
      ],
      note: note,
    );
    return loanId;
  });

  /// Pay back an own-savings loan. The money returns to the fund it was
  /// borrowed from.
  Future<int> repayOwnLoan(
    int loanId,
    DateTime date,
    Poisha amount, {
    required Pot from,
    int? toAccount,
    String note = '',
  }) async {
    final loan = await _loan(loanId);
    assert(loan.kind == LoanKind.ownSavings);
    return _write(
      date: date,
      type: EntryType.repay,
      amount: amount,
      loanId: loanId,
      postings: [
        (from, -amount),
        ((account: toAccount ?? from.account, fund: loan.fundId), amount),
      ],
      note: note,
    );
  }

  /// Lend to a person. The money keeps its fund while the person holds it,
  /// so it goes back to the same fund when they pay you.
  Future<int> lendToPerson(
    DateTime date,
    Poisha amount, {
    required int person,
    required Pot from,
    int chargeRateBp = 0,
    DateTime? dueDate,
    String note = '',
  }) => db.transaction(() async {
    final loanId = await _insertLoan(
      kind: LoanKind.lent,
      personAccountId: person,
      fundId: from.fund,
      principal: amount,
      chargeRateBp: chargeRateBp,
      date: date,
      dueDate: dueDate,
      note: note,
    );
    await _write(
      date: date,
      type: EntryType.lend,
      amount: amount,
      loanId: loanId,
      postings: [(from, -amount), ((account: person, fund: from.fund), amount)],
      note: note,
    );
    await _personCharge(loanId, date, person, from.fund, chargeFor(amount, chargeRateBp));
    return loanId;
  });

  Future<int> collectFromPerson(
    int loanId,
    DateTime date,
    Poisha amount, {
    required int toAccount,
    String note = '',
  }) async {
    final loan = await _loan(loanId);
    assert(loan.kind == LoanKind.lent);
    return _write(
      date: date,
      type: EntryType.collect,
      amount: amount,
      loanId: loanId,
      postings: [
        ((account: loan.personAccountId!, fund: loan.fundId), -amount),
        ((account: toAccount, fund: loan.fundId), amount),
      ],
      note: note,
    );
  }

  Future<int> borrowFromPerson(
    DateTime date,
    Poisha amount, {
    required int person,
    required Pot to,
    int chargeRateBp = 0,
    DateTime? dueDate,
    String note = '',
  }) => db.transaction(() async {
    final loanId = await _insertLoan(
      kind: LoanKind.borrowed,
      personAccountId: person,
      fundId: to.fund,
      principal: amount,
      chargeRateBp: chargeRateBp,
      date: date,
      dueDate: dueDate,
      note: note,
    );
    await _write(
      date: date,
      type: EntryType.borrow,
      amount: amount,
      loanId: loanId,
      postings: [(to, amount), ((account: person, fund: to.fund), -amount)],
      note: note,
    );
    await _personCharge(loanId, date, person, to.fund, -chargeFor(amount, chargeRateBp));
    return loanId;
  });

  Future<int> repayPerson(
    int loanId,
    DateTime date,
    Poisha amount, {
    required int fromAccount,
    String note = '',
  }) async {
    final loan = await _loan(loanId);
    assert(loan.kind == LoanKind.borrowed);
    return _write(
      date: date,
      type: EntryType.repay,
      amount: amount,
      loanId: loanId,
      postings: [
        ((account: fromAccount, fund: loan.fundId), -amount),
        ((account: loan.personAccountId!, fund: loan.fundId), amount),
      ],
      note: note,
    );
  }

  /// The charge on a loan with a person changes what they owe you (or what
  /// you owe them), so it is posted on the person's account.
  Future<void> _personCharge(int loanId, DateTime date, int person, int fund, Poisha signed) async {
    if (signed == 0) return;
    await _write(
      date: date,
      type: EntryType.charge,
      amount: signed.abs(),
      loanId: loanId,
      postings: [((account: person, fund: fund), signed)],
      note: 'Loan charge',
    );
  }

  /// A loan that already exists when you start using the app. Only the
  /// amount still open is posted.
  Future<int> openExistingLoan({
    required LoanKind kind,
    required int fundId,
    required Poisha principal,
    required DateTime date,
    required DateTime openingDate,
    int? person,
    Poisha alreadyRepaid = 0,
    int chargeRateBp = 0,
    DateTime? dueDate,
    String note = '',
  }) => db.transaction(() async {
    assert(kind == LoanKind.ownSavings || person != null);
    final loanId = await _insertLoan(
      kind: kind,
      personAccountId: person,
      fundId: fundId,
      principal: principal,
      chargeRateBp: chargeRateBp,
      date: date,
      dueDate: dueDate,
      openingRepaid: alreadyRepaid,
      note: note,
    );
    final open = principal + chargeFor(principal, chargeRateBp) - alreadyRepaid;
    if (kind != LoanKind.ownSavings && open != 0) {
      await _write(
        date: openingDate,
        type: EntryType.opening,
        amount: open,
        loanId: loanId,
        postings: [((account: person!, fund: fundId), kind == LoanKind.lent ? open : -open)],
        note: 'Open loan when starting',
      );
    }
    return loanId;
  });

  Future<Loan> _loan(int id) => (db.select(db.loans)..where((l) => l.id.equals(id))).getSingle();

  // -------------------------------------------------------------- budgets

  Future<void> setBudget(Period period, int categoryId, Poisha amount) => db
      .into(db.budgets)
      .insert(
        BudgetsCompanion.insert(
          year: period.year,
          month: period.month,
          categoryId: categoryId,
          amount: amount,
        ),
        onConflict: DoUpdate(
          (_) => BudgetsCompanion(amount: Value(amount)),
          target: [db.budgets.year, db.budgets.month, db.budgets.categoryId],
        ),
      );

  Future<void> deleteEntry(int entryId) =>
      (db.delete(db.entries)..where((e) => e.id.equals(entryId))).go();

  /// Edits an entry by replacing it in one transaction: the old version is
  /// removed only if the new one is written.
  Future<int> replaceEntry(int oldEntryId, Future<int> Function() writeNew) =>
      db.transaction(() async {
        await deleteEntry(oldEntryId);
        return writeNew();
      });

  // ------------------------------------------------------- monthly tasks

  /// Sets money aside as the plan says, taking it from where the salary
  /// arrived.
  Future<void> applyAllocation(AllocationPlan plan, DateTime date, Pot from) =>
      db.transaction(() async {
        for (final item in plan.items) {
          await move(
            date,
            item.amount,
            from: from,
            to: (account: item.accountId ?? from.account, fund: item.fundId),
            note: 'Salary plan',
          );
        }
      });

  /// Pays several fixed bills at once.
  Future<void> payBills(List<({int categoryId, Poisha amount})> bills, DateTime date, Pot from) =>
      db.transaction(() async {
        for (final bill in bills) {
          await expense(date, bill.amount, categoryId: bill.categoryId, from: from);
        }
      });

  /// Records the difference between the app's balance and the real one
  /// (your bank app, or the counted cash) as an adjustment.
  Future<int?> matchBalance({
    required DateTime date,
    required Pot pot,
    required Poisha appBalance,
    required Poisha realBalance,
    String? note,
  }) async {
    final delta = realBalance - appBalance;
    if (delta == 0) return null;
    return adjust(
      date,
      pot,
      delta,
      note: note ?? 'Matched to real balance (${formatTaka(delta, showPlus: true)})',
    );
  }

  /// Closes a month. The leftover in Spending can be split: each of
  /// [leftoverTo] moves that much to a pot or goal (with [sweepTo], all of
  /// it goes to one fund); the rest is carried forward. Money is taken
  /// from [leftovers], the Spending money per account in the order given,
  /// and stays in its account; only its purpose changes.
  Future<void> closeMonth(
    Period period, {
    int? spendingFund,
    int? sweepTo,
    List<({int fund, Poisha amount})> leftoverTo = const [],
    List<({int account, Poisha amount})> leftovers = const [],
    Poisha? confirmedBank,
  }) => db.transaction(() async {
    final lastDay = period.end.subtract(const Duration(days: 1));
    final available = [
      for (final l in leftovers)
        if (l.amount > 0) l,
    ];
    final total = available.fold<Poisha>(0, (t, l) => t + l.amount);
    final targets = [
      ...leftoverTo.where((t) => t.amount > 0),
      if (sweepTo != null) (fund: sweepTo, amount: total),
    ];
    if (spendingFund != null && targets.isNotEmpty) {
      final left = {for (final l in available) l.account: l.amount};
      for (final target in targets) {
        var need = target.amount;
        for (final l in available) {
          if (need <= 0) break;
          final take = need < left[l.account]! ? need : left[l.account]!;
          if (take <= 0) continue;
          await move(
            lastDay,
            take,
            from: (account: l.account, fund: spendingFund),
            to: (account: l.account, fund: target.fund),
            note: 'Leftover from ${period.label}',
          );
          left[l.account] = left[l.account]! - take;
          need -= take;
        }
      }
    }
    await db
        .into(db.monthCloses)
        .insertOnConflictUpdate(
          MonthClosesCompanion.insert(
            year: period.year,
            month: period.month,
            closedAt: DateTime.now(),
            confirmedBank: Value(confirmedBank),
          ),
        );
  });

  /// Saves the unused budget of linked categories to their pots, dated the
  /// month's last day. Each move is marked with its category, so the same
  /// budget is never saved twice.
  Future<void> moveUnusedBudgets(Period period, int spendingFund, List<UnusedBudgetMove> moves) =>
      db.transaction(() async {
        final lastDay = period.end.subtract(const Duration(days: 1));
        for (final m in moves) {
          for (final part in m.parts) {
            await _write(
              date: lastDay,
              type: EntryType.move,
              amount: part.amount,
              categoryId: m.category.id,
              postings: [
                ((account: part.account, fund: spendingFund), -part.amount),
                ((account: part.account, fund: m.fund.id), part.amount),
              ],
              note: 'Unused ${m.category.name} budget, ${period.label}',
            );
          }
        }
      });

  Future<void> reopenMonth(Period period) => (db.delete(
    db.monthCloses,
  )..where((c) => c.year.equals(period.year) & c.month.equals(period.month))).go();

  /// Starting balances for the day you begin. They are dated the day
  /// before, so they show as the opening position of [startDate].
  Future<void> setStartingBalances(DateTime startDate, List<(Pot, Poisha)> balances) =>
      db.transaction(() async {
        final date = dateOnly(startDate).subtract(const Duration(days: 1));
        for (final (pot, amount) in balances) {
          if (amount != 0) await openingBalance(date, pot, amount);
        }
      });

  /// Deletes a loan together with its borrowing, repayments and charges.
  Future<void> deleteLoan(int loanId) => db.transaction(() async {
    await (db.delete(db.entries)..where((e) => e.loanId.equals(loanId))).go();
    await (db.delete(db.loans)..where((l) => l.id.equals(loanId))).go();
  });

  // --------------------------------------------------------------- goals

  Future<void> setGoalAchieved(int fundId, DateTime? date) =>
      (db.update(db.funds)..where((f) => f.id.equals(fundId))).write(
        FundsCompanion(achievedAt: Value(date == null ? null : dateOnly(date))),
      );

  /// Buys the thing a goal was for. The goal's money is gathered into the
  /// paying account first (e.g. its cash part is counted as deposited);
  /// anything above the goal's balance comes from Spending. The goal is
  /// then marked achieved.
  Future<int> buyGoal({
    required int goalId,
    required int spendingFund,
    required int payFromAccount,
    required List<({int account, Poisha amount})> goalMoney,
    required DateTime date,
    required Poisha price,
    required int categoryId,
    String note = '',
  }) => db.transaction(() async {
    final available = goalMoney.fold<Poisha>(0, (t, g) => t + g.amount);
    final fromGoal = price < available ? price : available;
    var stillNeeded =
        fromGoal -
        goalMoney.where((g) => g.account == payFromAccount).fold<Poisha>(0, (t, g) => t + g.amount);
    for (final g in goalMoney) {
      if (stillNeeded <= 0) break;
      if (g.account == payFromAccount || g.amount <= 0) continue;
      final take = g.amount < stillNeeded ? g.amount : stillNeeded;
      await move(
        date,
        take,
        from: (account: g.account, fund: goalId),
        to: (account: payFromAccount, fund: goalId),
        note: 'Gathered for purchase',
      );
      stillNeeded -= take;
    }
    final extra = price - fromGoal;
    final entryId = await _write(
      date: date,
      type: EntryType.expense,
      amount: price,
      categoryId: categoryId,
      postings: [
        if (fromGoal > 0) ((account: payFromAccount, fund: goalId), -fromGoal),
        if (extra > 0) ((account: payFromAccount, fund: spendingFund), -extra),
      ],
      note: note,
    );
    await setGoalAchieved(goalId, date);
    await addPurchase(
      item: note.isEmpty ? 'Purchase' : note,
      date: date,
      amount: price,
      entryId: entryId,
    );
    return entryId;
  });

  // --------------------------------------------------------- investments

  /// Adds an investment account with its details. [currentValue] is what
  /// it is worth on [asOf] (already paid in before using the app).
  Future<int> addInvestment({
    required String name,
    required InvestmentKind kind,
    DateTime? startDate,
    DateTime? maturityDate,
    int? rateBp,
    Poisha? instalment,
    int? totalInstalments,
    int openingInstalments = 0,
    Poisha currentValue = 0,
    required DateTime asOf,
    required int investmentFund,
    String note = '',
  }) => db.transaction(() async {
    final accountId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name.trim(),
            type: AccountType.investment,
            sortOrder: const Value(50),
          ),
        );
    await db
        .into(db.investmentDetails)
        .insert(
          InvestmentDetailsCompanion.insert(
            accountId: Value(accountId),
            kind: kind,
            startDate: Value(startDate),
            maturityDate: Value(maturityDate),
            rateBp: Value(rateBp),
            instalment: Value(instalment),
            totalInstalments: Value(totalInstalments),
            openingInstalments: Value(openingInstalments),
            note: Value(note),
          ),
        );
    if (currentValue != 0) {
      await openingBalance(
        asOf,
        (account: accountId, fund: investmentFund),
        currentValue,
        note: 'Value when added',
      );
    }
    return accountId;
  });

  Future<void> saveInvestmentDetails(InvestmentDetailsCompanion details) =>
      db.into(db.investmentDetails).insertOnConflictUpdate(details);

  /// Records a new current value (profit added, or a market price change).
  Future<int?> updateInvestmentValue({
    required int accountId,
    required int investmentFund,
    required Poisha currentValue,
    required Poisha newValue,
    required DateTime date,
  }) async {
    final delta = newValue - currentValue;
    if (delta == 0) return null;
    return adjust(
      date,
      (account: accountId, fund: investmentFund),
      delta,
      note: 'Value update (${formatTaka(delta, showPlus: true)})',
    );
  }

  // ------------------------------------------------------------ purchases

  Future<int> addPurchase({
    required String item,
    required DateTime date,
    required Poisha amount,
    int? entryId,
    String shop = '',
    DateTime? warrantyUntil,
    String note = '',
  }) => db
      .into(db.purchases)
      .insert(
        PurchasesCompanion.insert(
          item: item.trim(),
          date: dateOnly(date),
          amount: amount,
          entryId: Value(entryId),
          shop: Value(shop.trim()),
          warrantyUntil: Value(warrantyUntil),
          note: Value(note),
        ),
      );

  Future<void> updatePurchase(int id, PurchasesCompanion changes) =>
      (db.update(db.purchases)..where((p) => p.id.equals(id))).write(changes);

  Future<void> deletePurchase(int id) =>
      (db.delete(db.purchases)..where((p) => p.id.equals(id))).go();

  // ------------------------------------------------------------- trackers

  Future<int> addTracker({
    required String name,
    required TrackerKind kind,
    required DateTime startDate,
    DateTime? endDate,
    Poisha? budget,
    Poisha openingSpent = 0,
  }) => db
      .into(db.trackers)
      .insert(
        TrackersCompanion.insert(
          name: name.trim(),
          kind: kind,
          startDate: dateOnly(startDate),
          endDate: Value(endDate == null ? null : dateOnly(endDate)),
          budget: Value(budget),
          openingSpent: Value(openingSpent),
        ),
      );

  Future<void> updateTracker(int id, TrackersCompanion changes) =>
      (db.update(db.trackers)..where((t) => t.id.equals(id))).write(changes);

  /// Tags (or untags, with null) an entry for a project or countdown.
  Future<void> setEntryTracker(int entryId, int? trackerId) => (db.update(
    db.entries,
  )..where((e) => e.id.equals(entryId))).write(EntriesCompanion(trackerId: Value(trackerId)));

  // ------------------------------------------------------------ settings

  Future<void> setSetting(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
