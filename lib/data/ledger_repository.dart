import 'package:drift/drift.dart';

import '../core/money.dart';
import '../core/period.dart';
import '../ledger/allocation.dart';
import '../ledger/enums.dart';
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
    String note = '',
  }) {
    assert(amount >= 0, 'Entry amounts are positive; postings carry the sign');
    return db.transaction(() async {
      final entryId = await db.into(db.entries).insert(EntriesCompanion.insert(
            date: dateOnly(date),
            type: type,
            amount: amount,
            categoryId: Value(categoryId),
            loanId: Value(loanId),
            note: Value(note),
          ));
      for (final (pot, value) in postings) {
        await db.into(db.postings).insert(PostingsCompanion.insert(
              entryId: entryId,
              accountId: pot.account,
              fundId: pot.fund,
              amount: value,
            ));
      }
      return entryId;
    });
  }

  /// A starting balance when you begin using the app. Negative amounts are
  /// allowed (an overdrawn account).
  Future<int> openingBalance(DateTime date, Pot pot, Poisha amount,
          {String note = 'Opening balance'}) =>
      _write(
        date: date,
        type: EntryType.opening,
        amount: amount.abs(),
        postings: [(pot, amount)],
        note: note,
      );

  Future<int> income(DateTime date, Poisha amount,
          {required int categoryId, required Pot to, String note = ''}) =>
      _write(
        date: date,
        type: EntryType.income,
        amount: amount,
        categoryId: categoryId,
        postings: [(to, amount)],
        note: note,
      );

  Future<int> expense(DateTime date, Poisha amount,
          {required int categoryId, required Pot from, String note = ''}) =>
      _write(
        date: date,
        type: EntryType.expense,
        amount: amount,
        categoryId: categoryId,
        postings: [(from, -amount)],
        note: note,
      );

  /// Set aside to savings, withdraw cash, pay a DPS instalment: anything that
  /// changes where money is or what it is for without leaving your hands.
  Future<int> move(DateTime date, Poisha amount,
          {required Pot from, required Pot to, String note = ''}) =>
      _write(
        date: date,
        type: EntryType.move,
        amount: amount,
        postings: [(from, -amount), (to, amount)],
        note: note,
      );

  /// A correction: matching your bank app's balance, or updating an
  /// investment's current value.
  Future<int> adjust(DateTime date, Pot pot, Poisha delta, {String note = ''}) =>
      _write(
        date: date,
        type: EntryType.adjust,
        amount: delta.abs(),
        postings: [(pot, delta)],
        note: note,
      );

  // ---------------------------------------------------------------- loans

  static Poisha chargeFor(Poisha principal, int rateBp) =>
      (principal * rateBp / 10000).round();

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
  }) =>
      db.into(db.loans).insert(LoansCompanion.insert(
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
          ));

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
  }) =>
      db.transaction(() async {
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
  Future<int> repayOwnLoan(int loanId, DateTime date, Poisha amount,
      {required Pot from, int? toAccount, String note = ''}) async {
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
  }) =>
      db.transaction(() async {
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
          postings: [
            (from, -amount),
            ((account: person, fund: from.fund), amount),
          ],
          note: note,
        );
        await _personCharge(loanId, date, person, from.fund,
            chargeFor(amount, chargeRateBp));
        return loanId;
      });

  Future<int> collectFromPerson(int loanId, DateTime date, Poisha amount,
      {required int toAccount, String note = ''}) async {
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
  }) =>
      db.transaction(() async {
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
          postings: [
            (to, amount),
            ((account: person, fund: to.fund), -amount),
          ],
          note: note,
        );
        await _personCharge(
            loanId, date, person, to.fund, -chargeFor(amount, chargeRateBp));
        return loanId;
      });

  Future<int> repayPerson(int loanId, DateTime date, Poisha amount,
      {required int fromAccount, String note = ''}) async {
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
  Future<void> _personCharge(
      int loanId, DateTime date, int person, int fund, Poisha signed) async {
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
  }) =>
      db.transaction(() async {
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
        final open =
            principal + chargeFor(principal, chargeRateBp) - alreadyRepaid;
        if (kind != LoanKind.ownSavings && open != 0) {
          await _write(
            date: openingDate,
            type: EntryType.opening,
            amount: open,
            loanId: loanId,
            postings: [
              (
                (account: person!, fund: fundId),
                kind == LoanKind.lent ? open : -open
              ),
            ],
            note: 'Open loan when starting',
          );
        }
        return loanId;
      });

  Future<Loan> _loan(int id) =>
      (db.select(db.loans)..where((l) => l.id.equals(id))).getSingle();

  // -------------------------------------------------------------- budgets

  Future<void> setBudget(Period period, int categoryId, Poisha amount) =>
      db.into(db.budgets).insert(
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
          await move(date, item.amount,
              from: from,
              to: (account: item.accountId ?? from.account, fund: item.fundId),
              note: 'Salary plan');
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
    return adjust(date, pot, delta,
        note: note ?? 'Matched to real balance (${formatTaka(delta, showPlus: true)})');
  }

  /// Closes a month. With [sweepTo], the Spending money left in each
  /// account moves to that fund on the month's last day; otherwise it is
  /// carried forward as it is.
  Future<void> closeMonth(
    Period period, {
    int? spendingFund,
    int? sweepTo,
    List<({int account, Poisha amount})> leftovers = const [],
    Poisha? confirmedBank,
  }) =>
      db.transaction(() async {
        final lastDay = period.end.subtract(const Duration(days: 1));
        if (sweepTo != null && spendingFund != null) {
          for (final l in leftovers) {
            if (l.amount > 0) {
              await move(lastDay, l.amount,
                  from: (account: l.account, fund: spendingFund),
                  to: (account: l.account, fund: sweepTo),
                  note: 'Leftover from ${period.label}');
            }
          }
        }
        await db.into(db.monthCloses).insertOnConflictUpdate(MonthClosesCompanion.insert(
              year: period.year,
              month: period.month,
              closedAt: DateTime.now(),
              confirmedBank: Value(confirmedBank),
            ));
      });

  Future<void> reopenMonth(Period period) => (db.delete(db.monthCloses)
        ..where((c) => c.year.equals(period.year) & c.month.equals(period.month)))
      .go();

  /// Starting balances for the day you begin. They are dated the day
  /// before, so they show as the opening position of [startDate].
  Future<void> setStartingBalances(DateTime startDate, List<(Pot, Poisha)> balances) =>
      db.transaction(() async {
        final date = dateOnly(startDate).subtract(const Duration(days: 1));
        for (final (pot, amount) in balances) {
          if (amount != 0) await openingBalance(date, pot, amount);
        }
      });

  // ------------------------------------------------------------ settings

  Future<void> setSetting(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
