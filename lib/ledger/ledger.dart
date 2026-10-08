import 'dart:math' as math;

import 'package:drift/drift.dart' show OrderingTerm, innerJoin;

import '../core/money.dart';
import '../core/period.dart';
import '../data/database.dart';
import 'enums.dart';

/// A posting together with the entry it belongs to.
class PostingLine {
  const PostingLine({
    required this.entryId,
    required this.date,
    required this.type,
    required this.accountId,
    required this.fundId,
    required this.amount,
    this.categoryId,
    this.loanId,
  });

  final int entryId;
  final DateTime date;
  final EntryType type;
  final int accountId;
  final int fundId;
  final Poisha amount;
  final int? categoryId;
  final int? loanId;
}

/// Everything in the database at one moment, with every figure the app
/// shows calculated from it. Nothing here is stored: balances are sums of
/// postings, so they cannot disagree with each other.
class Ledger {
  Ledger({
    required List<Account> accounts,
    required List<Fund> funds,
    required List<CategoryRow> categories,
    required this.loans,
    required this.budgets,
    required this.entries,
    required this.lines,
  })  : accounts = {for (final a in accounts) a.id: a},
        funds = {for (final f in funds) f.id: f},
        categories = {for (final c in categories) c.id: c};

  final Map<int, Account> accounts;
  final Map<int, Fund> funds;
  final Map<int, CategoryRow> categories;
  final List<Loan> loans;
  final List<Budget> budgets;
  final List<Entry> entries;
  final List<PostingLine> lines;

  static Future<Ledger> load(AppDatabase db) async {
    final rows = await (db.select(db.postings).join([
      innerJoin(db.entries, db.entries.id.equalsExp(db.postings.entryId)),
    ])).get();
    return Ledger(
      accounts: await (db.select(db.accounts)
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder), (a) => OrderingTerm.asc(a.id)]))
          .get(),
      funds: await (db.select(db.funds)
            ..orderBy([(f) => OrderingTerm.asc(f.sortOrder), (f) => OrderingTerm.asc(f.id)]))
          .get(),
      categories: await (db.select(db.categories)
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.id)]))
          .get(),
      loans: await db.select(db.loans).get(),
      budgets: await db.select(db.budgets).get(),
      entries: await (db.select(db.entries)
            ..orderBy([(e) => OrderingTerm.desc(e.date), (e) => OrderingTerm.desc(e.id)]))
          .get(),
      lines: [
        for (final row in rows)
          () {
            final p = row.readTable(db.postings);
            final e = row.readTable(db.entries);
            return PostingLine(
              entryId: e.id,
              date: e.date,
              type: e.type,
              accountId: p.accountId,
              fundId: p.fundId,
              amount: p.amount,
              categoryId: e.categoryId,
              loanId: e.loanId,
            );
          }(),
      ],
    );
  }

  /// Emits a fresh [Ledger] now and after every change to the database,
  /// which is what keeps every screen live.
  static Stream<Ledger> watch(AppDatabase db) async* {
    yield await load(db);
    await for (final _ in db.tableUpdates()) {
      yield await load(db);
    }
  }

  // ------------------------------------------------------------- lookups

  bool isLiquid(int accountId) => accounts[accountId]!.type.isLiquid;

  Fund get spendingFund =>
      funds.values.firstWhere((f) => f.kind == FundKind.spending);

  Iterable<Account> accountsOfType(bool Function(AccountType) test) =>
      accounts.values.where((a) => test(a.type));

  Iterable<Fund> fundsOfKind(FundKind kind) =>
      funds.values.where((f) => f.kind == kind && !f.archived);

  bool get isEmpty => entries.isEmpty;

  Iterable<PostingLine> _between({DateTime? from, DateTime? before}) =>
      lines.where((l) =>
          (from == null || !l.date.isBefore(from)) &&
          (before == null || l.date.isBefore(before)));

  static Poisha _sum(Iterable<PostingLine> lines) =>
      lines.fold(0, (total, l) => total + l.amount);

  // ------------------------------------------------------------ balances
  // `before` is exclusive: balance(before: period.start) is the opening
  // balance of the period. Leave it null for the balance right now.

  Poisha accountBalance(int accountId, {DateTime? before}) =>
      _sum(_between(before: before).where((l) => l.accountId == accountId));

  /// A fund's balance. By default only money you can spend counts: money
  /// lent to a person still belongs to the fund but is not in your hands.
  Poisha fundBalance(int fundId, {DateTime? before, bool liquidOnly = true}) =>
      _sum(_between(before: before).where((l) =>
          l.fundId == fundId && (!liquidOnly || isLiquid(l.accountId))));

  /// One cell of the account × fund grid, e.g. Cash × Monthly Savings.
  Poisha cell(int accountId, int fundId, {DateTime? before}) =>
      _sum(_between(before: before)
          .where((l) => l.accountId == accountId && l.fundId == fundId));

  /// Bank + cash + wallets.
  Poisha liquidTotal({DateTime? before}) =>
      _sum(_between(before: before).where((l) => isLiquid(l.accountId)));

  Poisha investmentTotal({DateTime? before}) => _sum(_between(before: before)
      .where((l) => accounts[l.accountId]!.type == AccountType.investment));

  /// What people owe you minus what you owe them.
  Poisha peopleNet({DateTime? before}) => _sum(_between(before: before)
      .where((l) => accounts[l.accountId]!.type == AccountType.person));

  /// Everything you have, including investments and loans with people.
  Poisha netWorth({DateTime? before}) => _sum(_between(before: before));

  /// Always true by construction: every posting has an account and a fund.
  /// Kept as an explicit check so a bug in a new feature shows up at once.
  bool get isBalanced {
    final liquidByFund = funds.keys.fold<Poisha>(0, (t, f) => t + fundBalance(f));
    return liquidByFund == liquidTotal();
  }

  // ------------------------------------------------------------- months

  Iterable<Entry> _entriesIn(Period p, EntryType type) =>
      entries.where((e) => e.type == type && p.contains(e.date));

  PeriodSummary summary(Period p) {
    final spending = spendingFund.id;
    final inPeriod = _between(from: p.start, before: p.end).toList();
    Poisha spendingFlow(Set<EntryType> types) => _sum(inPeriod.where((l) =>
        l.fundId == spending && isLiquid(l.accountId) && types.contains(l.type)));

    final expenseLines = categoryLines(p, CategoryKind.expense);
    return PeriodSummary(
      period: p,
      openingLiquid: liquidTotal(before: p.start),
      closingLiquid: liquidTotal(before: p.end),
      carriedForward: fundBalance(spending, before: p.start),
      leftToSpend: fundBalance(spending, before: p.end),
      income: _entriesIn(p, EntryType.income).fold(0, (t, e) => t + e.amount),
      expenses: _entriesIn(p, EntryType.expense).fold(0, (t, e) => t + e.amount),
      spendingIncome: spendingFlow({EntryType.income}),
      spendingExpenses: -spendingFlow({EntryType.expense}),
      setAside: -spendingFlow({EntryType.move}),
      loanNet: spendingFlow({
        EntryType.borrow,
        EntryType.repay,
        EntryType.lend,
        EntryType.collect,
      }),
      otherNet: spendingFlow({EntryType.opening, EntryType.adjust, EntryType.charge}),
      invested: _sum(inPeriod.where((l) =>
          l.type == EntryType.move &&
          accounts[l.accountId]!.type == AccountType.investment)),
      budget: expenseLines.fold(0, (t, l) => t + l.budget),
      budgetLeft: expenseLines.fold(0, (t, l) => t + l.plannedLeft),
    );
  }

  /// Actual against budget for each top-level category of [kind]. Parents
  /// include their sub-categories.
  List<CategoryLine> categoryLines(Period p, CategoryKind kind) {
    final type = kind == CategoryKind.expense ? EntryType.expense : EntryType.income;
    final actual = <int, Poisha>{};
    for (final e in _entriesIn(p, type)) {
      if (e.categoryId != null) {
        actual.update(e.categoryId!, (v) => v + e.amount, ifAbsent: () => e.amount);
      }
    }
    final budget = {
      for (final b in budgets)
        if (b.year == p.year && b.month == p.month) b.categoryId: b.amount,
    };

    CategoryLine build(CategoryRow c) {
      final children = [
        for (final child in categories.values)
          if (child.parentId == c.id) build(child),
      ]..removeWhere((l) => l.category.archived && l.actual == 0);
      return CategoryLine(
        category: c,
        children: children,
        actual: (actual[c.id] ?? 0) + children.fold(0, (t, l) => t + l.actual),
        budget: budget[c.id] ?? children.fold(0, (t, l) => t + l.budget),
      );
    }

    return [
      for (final c in categories.values)
        if (c.parentId == null && c.kind == kind) build(c),
    ]..removeWhere((l) => l.category.archived && l.actual == 0);
  }

  // -------------------------------------------------------------- loans

  LoanStatus loanStatus(Loan loan) {
    final repaid = entries
        .where((e) =>
            e.loanId == loan.id &&
            (e.type == EntryType.repay || e.type == EntryType.collect))
        .fold<Poisha>(loan.openingRepaid, (t, e) => t + e.amount);
    return LoanStatus(loan: loan, repaid: repaid);
  }

  List<LoanStatus> openLoans() => [
        for (final l in loans)
          if (l.closedAt == null) loanStatus(l),
      ]..removeWhere((s) => s.remaining <= 0);

  // -------------------------------------------------------------- goals

  /// Net amount moved into a fund during a month (e.g. this month's
  /// deposit to a goal).
  Poisha movedInto(int fundId, Period p) => _sum(_between(from: p.start, before: p.end)
      .where((l) => l.fundId == fundId && l.type == EntryType.move));

  GoalStatus goalStatus(Fund goal, DateTime today) {
    final period = Period.of(today);
    var monthly = movedInto(goal.id, period);
    if (monthly <= 0) monthly = movedInto(goal.id, period.previous);

    int? monthsLeft;
    if (goal.targetDate != null) {
      final t = goal.targetDate!;
      monthsLeft = math.max(0, (t.year * 12 + t.month) - (period.year * 12 + period.month));
    }
    return GoalStatus(
      fund: goal,
      saved: fundBalance(goal.id, liquidOnly: false),
      monthly: math.max(0, monthly),
      monthsLeft: monthsLeft,
      period: period,
    );
  }

  /// Total still owed back to a fund by own-savings loans.
  Poisha owedToFund(int fundId) => openLoans()
      .where((s) => s.loan.kind == LoanKind.ownSavings && s.loan.fundId == fundId)
      .fold(0, (t, s) => t + s.remaining);
}

class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.openingLiquid,
    required this.closingLiquid,
    required this.carriedForward,
    required this.leftToSpend,
    required this.income,
    required this.expenses,
    required this.spendingIncome,
    required this.spendingExpenses,
    required this.setAside,
    required this.loanNet,
    required this.otherNet,
    required this.invested,
    required this.budget,
    required this.budgetLeft,
  });

  final Period period;

  /// Bank + cash + wallets on the 1st, and at the end of the month (or now).
  final Poisha openingLiquid;
  final Poisha closingLiquid;

  /// Spending fund on the 1st: last month's leftover.
  final Poisha carriedForward;

  /// Spending fund at the end of the month (or now).
  final Poisha leftToSpend;

  /// All income and all expenses this month, whatever fund they touched.
  final Poisha income;
  final Poisha expenses;

  /// The parts that went through the Spending fund. Together they explain
  /// [leftToSpend]; see [checks].
  final Poisha spendingIncome;
  final Poisha spendingExpenses;

  /// Net amount moved out of Spending to savings, goals and investments.
  final Poisha setAside;

  /// Borrowed into Spending minus repaid from it (own savings and people).
  final Poisha loanNet;

  /// Opening balances, adjustments and loan charges in Spending.
  final Poisha otherNet;

  /// Net amount put into investment accounts.
  final Poisha invested;

  final Poisha budget;

  /// Budget not yet used, counting only categories still under budget.
  final Poisha budgetLeft;

  /// Left to spend that no budget is waiting for.
  Poisha get unplanned => leftToSpend - budgetLeft;

  /// True when the month's parts add up to the Spending fund balance.
  bool get checks =>
      carriedForward + spendingIncome - spendingExpenses - setAside + loanNet + otherNet ==
      leftToSpend;

  /// How much a day you can spend for the rest of the month, counting
  /// [today] as a day left, rounded to whole taka. Null outside the month.
  Poisha? perDay(DateTime today) {
    if (!period.contains(today)) return null;
    final daysLeft = period.daysInMonth - today.day + 1;
    return (leftToSpend / daysLeft / poishaPerTaka).round() * poishaPerTaka;
  }
}

class CategoryLine {
  const CategoryLine({
    required this.category,
    required this.children,
    required this.actual,
    required this.budget,
  });

  final CategoryRow category;
  final List<CategoryLine> children;
  final Poisha actual;
  final Poisha budget;

  Poisha get remaining => budget - actual;
  bool get isOver => budget > 0 && actual > budget;

  /// 0.0–1.0+ share of the budget used; 0 when there is no budget.
  double get usage => budget == 0 ? 0 : actual / budget;

  /// Budget still expected to be spent. Over-budget sub-categories don't
  /// reduce what the others still need.
  Poisha get plannedLeft => children.isEmpty
      ? math.max(0, remaining)
      : children.fold(0, (t, c) => t + c.plannedLeft);
}

class LoanStatus {
  const LoanStatus({required this.loan, required this.repaid});

  final Loan loan;
  final Poisha repaid;

  Poisha get due => loan.principal + loan.charge;
  Poisha get remaining => due - repaid;
  double get progress => due == 0 ? 1 : repaid / due;
}

class GoalStatus {
  const GoalStatus({
    required this.fund,
    required this.saved,
    required this.monthly,
    required this.monthsLeft,
    required this.period,
  });

  final Fund fund;
  final Poisha saved;

  /// What you put in this month, or last month if nothing yet this month.
  final Poisha monthly;

  /// Whole months after the current one until the target month.
  final int? monthsLeft;
  final Period period;

  Poisha get target => fund.targetAmount ?? 0;
  Poisha get remaining => math.max(0, target - saved);
  double get progress => target == 0 ? 0 : saved / target;
  bool get reached => target > 0 && saved >= target;

  /// Monthly amount that reaches the target on time, in whole taka.
  Poisha? get neededPerMonth {
    if (monthsLeft == null) return null;
    if (monthsLeft == 0) return remaining;
    return (remaining / monthsLeft! / poishaPerTaka).round() * poishaPerTaka;
  }

  bool get onTrack {
    final needed = neededPerMonth;
    return reached || needed == null || monthly >= needed;
  }

  /// The month you finish at the current rate.
  Period? get projectedFinish {
    if (reached) return period;
    if (monthly <= 0) return null;
    final months = (remaining / monthly).ceil();
    return Period.of(DateTime(period.year, period.month + months));
  }
}
