import 'dart:math' as math;

import 'package:drift/drift.dart' show OrderingTerm, innerJoin;

import '../core/money.dart';
import '../core/period.dart';
import '../data/database.dart';
import 'allocation.dart';
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
    this.settings = const {},
    this.monthCloses = const [],
    List<InvestmentDetail> investmentDetails = const [],
    this.purchases = const [],
    List<Tracker> trackers = const [],
  }) : accounts = {for (final a in accounts) a.id: a},
       funds = {for (final f in funds) f.id: f},
       categories = {for (final c in categories) c.id: c},
       investmentDetails = {for (final d in investmentDetails) d.accountId: d},
       trackers = {for (final t in trackers) t.id: t};

  final Map<int, Account> accounts;
  final Map<int, Fund> funds;
  final Map<int, CategoryRow> categories;
  final List<Loan> loans;
  final List<Budget> budgets;
  final List<Entry> entries;
  final List<PostingLine> lines;
  final Map<String, String> settings;
  final List<MonthClose> monthCloses;
  final Map<int, InvestmentDetail> investmentDetails;

  /// Newest first.
  final List<Purchase> purchases;
  final Map<int, Tracker> trackers;

  static Future<Ledger> load(AppDatabase db) async {
    final rows = await (db.select(db.postings).join([
      innerJoin(db.entries, db.entries.id.equalsExp(db.postings.entryId)),
    ])).get();
    return Ledger(
      accounts: await (db.select(
        db.accounts,
      )..orderBy([(a) => OrderingTerm.asc(a.sortOrder), (a) => OrderingTerm.asc(a.id)])).get(),
      funds: await (db.select(
        db.funds,
      )..orderBy([(f) => OrderingTerm.asc(f.sortOrder), (f) => OrderingTerm.asc(f.id)])).get(),
      categories: await (db.select(
        db.categories,
      )..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.id)])).get(),
      loans: await db.select(db.loans).get(),
      budgets: await db.select(db.budgets).get(),
      entries: await (db.select(
        db.entries,
      )..orderBy([(e) => OrderingTerm.desc(e.date), (e) => OrderingTerm.desc(e.id)])).get(),
      settings: {for (final s in await db.select(db.settings).get()) s.key: s.value},
      monthCloses: await db.select(db.monthCloses).get(),
      investmentDetails: await db.select(db.investmentDetails).get(),
      purchases: await (db.select(
        db.purchases,
      )..orderBy([(p) => OrderingTerm.desc(p.date), (p) => OrderingTerm.desc(p.id)])).get(),
      trackers: await (db.select(db.trackers)..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
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

  Fund get spendingFund => funds.values.firstWhere((f) => f.kind == FundKind.spending);

  Iterable<Account> accountsOfType(bool Function(AccountType) test) =>
      accounts.values.where((a) => test(a.type));

  Iterable<Fund> fundsOfKind(FundKind kind) =>
      funds.values.where((f) => f.kind == kind && !f.archived);

  bool get isEmpty => entries.isEmpty;

  Iterable<PostingLine> _between({DateTime? from, DateTime? before}) => lines.where(
    (l) => (from == null || !l.date.isBefore(from)) && (before == null || l.date.isBefore(before)),
  );

  static Poisha _sum(Iterable<PostingLine> lines) => lines.fold(0, (total, l) => total + l.amount);

  // ------------------------------------------------------------ balances
  // `before` is exclusive: balance(before: period.start) is the opening
  // balance of the period. Leave it null for the balance right now.

  Poisha accountBalance(int accountId, {DateTime? before}) =>
      _sum(_between(before: before).where((l) => l.accountId == accountId));

  /// A fund's balance. By default only money you can spend counts: money
  /// lent to a person still belongs to the fund but is not in your hands.
  Poisha fundBalance(int fundId, {DateTime? before, bool liquidOnly = true}) => _sum(
    _between(before: before)
        .where((l) => l.fundId == fundId && (!liquidOnly || isLiquid(l.accountId))),
  );

  /// One cell of the account × fund grid, e.g. Cash × Monthly Savings.
  Poisha cell(int accountId, int fundId, {DateTime? before}) =>
      _sum(_between(before: before).where((l) => l.accountId == accountId && l.fundId == fundId));

  /// Bank + cash + wallets.
  Poisha liquidTotal({DateTime? before}) =>
      _sum(_between(before: before).where((l) => isLiquid(l.accountId)));

  Poisha investmentTotal({DateTime? before}) => _sum(
    _between(before: before).where((l) => accounts[l.accountId]!.type == AccountType.investment),
  );

  /// What people owe you minus what you owe them.
  Poisha peopleNet({DateTime? before}) => _sum(
    _between(before: before).where((l) => accounts[l.accountId]!.type == AccountType.person),
  );

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
    Poisha spendingFlow(Set<EntryType> types) => _sum(
      inPeriod.where(
        (l) => l.fundId == spending && isLiquid(l.accountId) && types.contains(l.type),
      ),
    );

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
      loanNet: spendingFlow({EntryType.borrow, EntryType.repay, EntryType.lend, EntryType.collect}),
      startingNet: spendingFlow({EntryType.opening}),
      adjustNet: spendingFlow({EntryType.adjust, EntryType.charge}),
      invested: _sum(
        inPeriod.where(
          (l) => l.type == EntryType.move && accounts[l.accountId]!.type == AccountType.investment,
        ),
      ),
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
    final budget = budgetsFor(p);

    CategoryLine build(CategoryRow c) {
      final children = [
        for (final child in categories.values)
          if (child.parentId == c.id) build(child),
      ]..removeWhere((l) => l.category.archived && l.actual == 0);
      return CategoryLine(
        category: c,
        children: children,
        actual: (actual[c.id] ?? 0) + children.fold(0, (t, l) => t + l.actual),
        // A section with its own budget keeps it; otherwise it is the sum
        // of its subsections.
        budget: children.isEmpty
            ? budget[c.id] ?? 0
            : (budget[c.id] ?? 0) > 0
            ? budget[c.id]!
            : children.fold(0, (t, l) => t + l.budget),
      );
    }

    return [
      for (final c in categories.values)
        if (c.parentId == null && c.kind == kind) build(c),
    ]..removeWhere((l) => l.category.archived && l.actual == 0);
  }

  /// The budget of each category in a month. A budget set in one month
  /// stays in force for later months until it is changed.
  Map<int, Poisha> budgetsFor(Period p) {
    final key = p.year * 12 + p.month;
    final sorted = [...budgets]
      ..sort((a, b) => (a.year * 12 + a.month).compareTo(b.year * 12 + b.month));
    return {
      for (final b in sorted)
        if (b.year * 12 + b.month <= key) b.categoryId: b.amount,
    };
  }

  /// Categories you can put an entry on: those without sub-categories.
  List<CategoryRow> leafCategories(CategoryKind kind) => [
    for (final c in categories.values)
      if (c.kind == kind &&
          !c.archived &&
          !categories.values.any((x) => x.parentId == c.id && !x.archived))
        c,
  ];

  /// Leaf categories ordered by how often you used them in the 90 days
  /// before [today], then in their usual order.
  List<CategoryRow> frequentCategories(CategoryKind kind, DateTime today) {
    final type = kind == CategoryKind.expense ? EntryType.expense : EntryType.income;
    final since = today.subtract(const Duration(days: 90));
    final uses = <int, int>{};
    for (final e in entries) {
      if (e.type == type && e.categoryId != null && !e.date.isBefore(since)) {
        uses.update(e.categoryId!, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final leaves = leafCategories(kind);
    final order = {for (final (i, c) in leaves.indexed) c.id: i};
    return leaves..sort((a, b) {
      final byUse = (uses[b.id] ?? 0).compareTo(uses[a.id] ?? 0);
      return byUse != 0 ? byUse : order[a.id]!.compareTo(order[b.id]!);
    });
  }

  /// Fixed bills with a budget that are not fully paid this month, with
  /// the amount still to pay.
  List<CategoryLine> unpaidFixedBills(Period p) {
    final result = <CategoryLine>[];
    void walk(CategoryLine line) {
      if (line.children.isEmpty) {
        if (line.category.isFixed && line.budget > 0 && line.actual < line.budget) {
          result.add(line);
        }
      } else {
        line.children.forEach(walk);
      }
    }

    categoryLines(p, CategoryKind.expense).forEach(walk);
    return result;
  }

  /// The postings of one entry.
  List<PostingLine> postingsOf(int entryId) => lines.where((l) => l.entryId == entryId).toList();

  // --------------------------------------------------------- month close

  bool isClosed(Period p) => monthCloses.any((c) => c.year == p.year && c.month == p.month);

  /// The earliest finished month with entries that you haven't closed yet.
  /// Starting balances alone don't make a month you need to close.
  Period? monthToClose(DateTime today) {
    final dates = entries.where((e) => e.type != EntryType.opening).map((e) => e.date);
    if (dates.isEmpty) return null;
    final first = Period.of(dates.reduce((a, b) => a.isBefore(b) ? a : b));
    for (var p = first; p.compareTo(Period.of(today)) < 0; p = p.next) {
      if (!isClosed(p)) return p;
    }
    return null;
  }

  String setting(String key, String fallback) => settings[key] ?? fallback;

  // -------------------------------------------------------------- loans

  /// A loan's position now, or on the day before [before].
  LoanStatus loanStatus(Loan loan, {DateTime? before}) {
    final repaid = entries
        .where(
          (e) =>
              e.loanId == loan.id &&
              (e.type == EntryType.repay || e.type == EntryType.collect) &&
              (before == null || e.date.isBefore(before)),
        )
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
  Poisha movedInto(int fundId, Period p) => _sum(
    _between(
      from: p.start,
      before: p.end,
    ).where((l) => l.fundId == fundId && l.type == EntryType.move),
  );

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

  /// Entries that changed a fund's balance, newest first, with the net
  /// amount for that fund. Moves within the fund (bank to cash) are left out.
  List<({Entry entry, Poisha amount})> fundHistory(int fundId, {bool liquidOnly = false}) {
    final net = <int, Poisha>{};
    for (final l in lines) {
      if (l.fundId == fundId && (!liquidOnly || isLiquid(l.accountId))) {
        net.update(l.entryId, (v) => v + l.amount, ifAbsent: () => l.amount);
      }
    }
    return [
      for (final e in entries)
        if ((net[e.id] ?? 0) != 0) (entry: e, amount: net[e.id]!),
    ];
  }

  /// A loan's own entries, oldest first: the borrowing, charges and every
  /// repayment.
  List<Entry> loanEntries(int loanId) =>
      entries.where((e) => e.loanId == loanId).toList().reversed.toList();

  /// Every loan, open ones first, newest first within each group.
  List<LoanStatus> allLoans() {
    final all = [for (final l in loans) loanStatus(l)];
    all.sort((a, b) {
      final open = (b.remaining > 0 ? 1 : 0).compareTo(a.remaining > 0 ? 1 : 0);
      return open != 0 ? open : b.loan.date.compareTo(a.loan.date);
    });
    return all;
  }

  /// The money in one account split by what it is for, e.g. the cash
  /// drawer by sector. Zero sectors are left out.
  List<({Fund fund, Poisha amount})> sectorsOf(int accountId, {DateTime? before}) => [
    for (final f in funds.values)
      if (cell(accountId, f.id, before: before) != 0)
        (fund: f, amount: cell(accountId, f.id, before: before)),
  ];

  /// Charge for new loans from savings, in basis points.
  int get borrowChargeBp => int.tryParse(settings['borrow_charge_bp'] ?? '') ?? 500;

  // ---------------------------------------------------------- investments

  InvestmentStatus investmentStatus(Account account, {DateTime? before}) {
    final own = _between(before: before).where((l) => l.accountId == account.id);
    final paidIn = own.where((l) => l.type == EntryType.move && l.amount > 0);
    return InvestmentStatus(
      account: account,
      details: investmentDetails[account.id],
      value: _sum(own),
      invested: _sum(own.where((l) => l.type != EntryType.adjust)),
      instalmentsPaid:
          (investmentDetails[account.id]?.openingInstalments ?? 0) +
          paidIn.map((l) => l.entryId).toSet().length,
    );
  }

  /// Investments you still hold, maturing soonest first.
  List<InvestmentStatus> investments() {
    final list = [
      for (final a in accountsOfType((t) => t == AccountType.investment))
        if (!a.archived) investmentStatus(a),
    ];
    final far = DateTime(9999);
    list.sort((a, b) => (a.details?.maturityDate ?? far).compareTo(b.details?.maturityDate ?? far));
    return list;
  }

  /// Investments maturing within [days] of [today] (or already matured)
  /// that still hold money.
  List<InvestmentStatus> maturingSoon(DateTime today, {int days = 30}) => [
    for (final i in investments())
      if (i.value > 0 && i.daysToMaturity(today) != null && i.daysToMaturity(today)! <= days) i,
  ];

  // ------------------------------------------------------------- trackers

  TrackerStatus trackerStatus(Tracker tracker) {
    final tagged = [
      for (final e in entries)
        if (e.trackerId == tracker.id && e.type == EntryType.expense) e,
    ];
    final byCategory = <int?, Poisha>{};
    for (final e in tagged) {
      final top = _topCategory(e.categoryId);
      byCategory.update(top, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return TrackerStatus(tracker: tracker, entries: tagged, byCategory: byCategory);
  }

  int? _topCategory(int? id) {
    var c = categories[id];
    while (c?.parentId != null) {
      c = categories[c!.parentId];
    }
    return c?.id;
  }

  /// Trackers not archived: countdowns first (soonest end), then projects.
  List<TrackerStatus> activeTrackers() {
    final list = [
      for (final t in trackers.values)
        if (!t.archived) trackerStatus(t),
    ];
    final far = DateTime(9999);
    list.sort((a, b) {
      final kind = a.tracker.kind.index.compareTo(b.tracker.kind.index);
      if (kind != 0) return -kind;
      return (a.tracker.endDate ?? far).compareTo(b.tracker.endDate ?? far);
    });
    return list;
  }

  // ------------------------------------------------------------ purchases

  List<Purchase> purchasesIn(int year) => [
    for (final p in purchases)
      if (p.date.year == year) p,
  ];

  Purchase? purchaseFor(int entryId) => purchases.where((p) => p.entryId == entryId).firstOrNull;

  // -------------------------------------------------------------- reports

  /// How a fund's spendable balance changed during a month.
  FundMovement fundMovement(int fundId, Period p) {
    final inP = _between(
      from: p.start,
      before: p.end,
    ).where((l) => l.fundId == fundId && isLiquid(l.accountId));
    Poisha sum(bool Function(PostingLine) test) => _sum(inP.where(test));
    return FundMovement(
      opening: fundBalance(fundId, before: p.start),
      closing: fundBalance(fundId, before: p.end),
      deposits: sum((l) => l.type == EntryType.move && l.amount > 0),
      withdrawals: sum((l) => l.type == EntryType.move && l.amount < 0),
      borrowedOut: sum((l) => l.type == EntryType.borrow && l.amount < 0),
      repaidIn: sum((l) => l.type == EntryType.repay && l.amount > 0),
      spent: sum((l) => l.type == EntryType.expense),
      other: sum(
        (l) =>
            !(l.type == EntryType.move ||
                (l.type == EntryType.borrow && l.amount < 0) ||
                (l.type == EntryType.repay && l.amount > 0) ||
                l.type == EntryType.expense),
      ),
    );
  }

  /// What Spending sent where during a month: savings pots, goals and
  /// investments, by the kind of fund that received it.
  Map<FundKind, Poisha> setAsideByKind(Period p) {
    final spending = spendingFund.id;
    final result = <FundKind, Poisha>{};
    final moves = entries.where((e) => e.type == EntryType.move && p.contains(e.date));
    for (final e in moves) {
      final postings = postingsOf(e.id);
      if (!postings.any((l) => l.fundId == spending && l.amount < 0)) continue;
      for (final l in postings.where((l) => l.amount > 0 && l.fundId != spending)) {
        final kind = funds[l.fundId]!.kind;
        result.update(kind, (v) => v + l.amount, ifAbsent: () => l.amount);
      }
    }
    return result;
  }

  /// Loans that were open at some point during the month.
  List<LoanStatus> loansDuring(Period p) => [
    for (final l in loans)
      if (!l.date.isAfter(p.end) &&
          (loanStatus(l, before: p.start).remaining > 0 ||
              !l.date.isBefore(p.start) ||
              loanEntries(l.id).any((e) => p.contains(e.date))))
        loanStatus(l, before: p.end),
  ];

  // ------------------------------------------------- unused budget to pots

  /// Spending money in each account at the end of month [p] (only accounts
  /// with some), banks first, then the largest. This is where month-end
  /// moves take their money from.
  List<({int account, Poisha amount})> spendingCells(Period p) {
    final spending = spendingFund.id;
    final cells =
        [
          for (final a in accountsOfType((t) => t.isLiquid))
            if (cell(a.id, spending, before: p.end) > 0)
              (
                account: a.id,
                amount: cell(a.id, spending, before: p.end),
                bank: a.type == AccountType.bank,
              ),
        ]..sort((a, b) {
          final bank = (b.bank ? 1 : 0).compareTo(a.bank ? 1 : 0);
          return bank != 0 ? bank : b.amount.compareTo(a.amount);
        });
    return [for (final c in cells) (account: c.account, amount: c.amount)];
  }

  /// Unused budget of a category already saved to its pot for month [p].
  Poisha savedFromBudget(int categoryId, Period p) => entries
      .where((e) => e.type == EntryType.move && e.categoryId == categoryId && p.contains(e.date))
      .fold(0, (t, e) => t + e.amount);

  /// What closing [p] saves from categories linked to a pot: each linked
  /// category's unused budget (nothing if it went over). A linked section
  /// counts as a whole and its subsections' links are not used. The total
  /// is capped at what is left in Spending; each move says which accounts
  /// its money sits in, since only its purpose changes.
  List<UnusedBudgetMove> unusedBudgetMoves(Period p) {
    final wanted = <(CategoryRow, Fund, Poisha)>[];
    void walk(CategoryLine l) {
      final fund = funds[l.category.savingsFundId];
      if (fund != null && !fund.archived) {
        final unused = l.budget - l.actual - savedFromBudget(l.category.id, p);
        if (unused > 0) wanted.add((l.category, fund, unused));
        return;
      }
      l.children.forEach(walk);
    }

    categoryLines(p, CategoryKind.expense).forEach(walk);
    if (wanted.isEmpty) return const [];

    final available = [
      for (final c in spendingCells(p)) (account: accounts[c.account]!, amount: c.amount),
    ];
    final left = {for (final a in available) a.account.id: a.amount};

    final moves = <UnusedBudgetMove>[];
    for (final (category, fund, unused) in wanted) {
      var need = unused;
      final parts = <({int account, Poisha amount})>[];
      for (final a in available) {
        if (need <= 0) break;
        final take = math.min(need, left[a.account.id]!);
        if (take <= 0) continue;
        parts.add((account: a.account.id, amount: take));
        left[a.account.id] = left[a.account.id]! - take;
        need -= take;
      }
      final moved = unused - need;
      if (moved > 0) {
        moves.add(
          UnusedBudgetMove(
            category: category,
            fund: fund,
            unused: unused,
            amount: moved,
            parts: parts,
          ),
        );
      }
    }
    return moves;
  }

  // --------------------------------------------------------- monthly plan

  AllocationPlan get plan => AllocationPlan.parse(settings[AllocationPlan.settingKey]);

  /// Planned incomes whose day has come this month but which have not been
  /// recorded yet.
  List<IncomeSource> incomesDue(DateTime today) {
    final p = Period.of(today);
    final received = {
      for (final e in entries)
        if (e.type == EntryType.income && p.contains(e.date)) e.categoryId,
    };
    return [
      for (final i in plan.incomes)
        if (i.day != null &&
            today.day >= i.day!.clamp(1, p.daysInMonth) &&
            !received.contains(i.categoryId) &&
            categories[i.categoryId] != null)
          i,
    ];
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
    required this.startingNet,
    required this.adjustNet,
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

  /// Starting balances entered this month (the month you began).
  final Poisha startingNet;

  /// Corrections after matching a balance, and loan charges.
  final Poisha adjustNet;

  /// Net amount put into investment accounts.
  final Poisha invested;

  final Poisha budget;

  /// Budget not yet used, counting only categories still under budget.
  final Poisha budgetLeft;

  /// Left to spend that no budget is waiting for.
  Poisha get unplanned => leftToSpend - budgetLeft;

  /// True when the month's parts add up to the Spending fund balance.
  bool get checks =>
      carriedForward +
          spendingIncome -
          spendingExpenses -
          setAside +
          loanNet +
          startingNet +
          adjustNet ==
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
  Poisha get plannedLeft =>
      children.isEmpty ? math.max(0, remaining) : children.fold(0, (t, c) => t + c.plannedLeft);
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

class InvestmentStatus {
  const InvestmentStatus({
    required this.account,
    required this.details,
    required this.value,
    required this.invested,
    required this.instalmentsPaid,
  });

  final Account account;
  final InvestmentDetail? details;

  /// What it is worth now.
  final Poisha value;

  /// What went in (starting value plus instalments, minus withdrawals).
  final Poisha invested;
  final int instalmentsPaid;

  /// Profit recorded through value updates.
  Poisha get growth => value - invested;

  int? daysToMaturity(DateTime today) => details?.maturityDate == null
      ? null
      : details!.maturityDate!.difference(dateOnly(today)).inDays;
}

class TrackerStatus {
  const TrackerStatus({required this.tracker, required this.entries, required this.byCategory});

  final Tracker tracker;

  /// Tagged expenses, newest first.
  final List<Entry> entries;

  /// Spent per top-level category (null: no category).
  final Map<int?, Poisha> byCategory;

  Poisha get spent => tracker.openingSpent + entries.fold<Poisha>(0, (t, e) => t + e.amount);
  Poisha? get left => tracker.budget == null ? null : tracker.budget! - spent;
  double get progress =>
      (tracker.budget ?? 0) <= 0 ? 0 : (spent / tracker.budget!).clamp(0, 1).toDouble();

  int? daysLeft(DateTime today) => tracker.endDate?.difference(dateOnly(today)).inDays;
}

class FundMovement {
  const FundMovement({
    required this.opening,
    required this.closing,
    required this.deposits,
    required this.withdrawals,
    required this.borrowedOut,
    required this.repaidIn,
    required this.spent,
    required this.other,
  });

  final Poisha opening;
  final Poisha closing;

  /// Moves in (positive) and out (negative).
  final Poisha deposits;
  final Poisha withdrawals;

  /// Borrowed from the fund (negative) and paid back into it (positive).
  final Poisha borrowedOut;
  final Poisha repaidIn;

  /// Expenses paid straight from the fund (negative).
  final Poisha spent;
  final Poisha other;
}

/// Unused budget of one category, saved to its linked pot at month close.
class UnusedBudgetMove {
  const UnusedBudgetMove({
    required this.category,
    required this.fund,
    required this.unused,
    required this.amount,
    required this.parts,
  });

  final CategoryRow category;
  final Fund fund;

  /// Budget not spent.
  final Poisha unused;

  /// What will move: [unused], unless less was left in Spending.
  final Poisha amount;

  /// Where that money sits (it stays there; only its purpose changes).
  final List<({int account, Poisha amount})> parts;
}
