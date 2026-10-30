import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../data/database.dart';
import '../../ui/widgets.dart';

/// Everything behind Home's short "What it's for" card: each pot, how this
/// month's spending money adds up, and net worth.
class MoneyDetailsScreen extends ConsumerWidget {
  const MoneyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('What your money is for')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final period = Period.of(today);
          final s = ledger.summary(period);
          final total = ledger.liquidTotal();
          final next = ledger.heldForNextMonth;
          return PageList(
            children: [
              SectionCard(
                children: [
                  const Label('Every pot'),
                  AmountRow('Spending', ledger.fundBalance(ledger.spendingFund.id)),
                  for (final kind in [FundKind.savings, FundKind.goal])
                    for (final f in ledger.fundsOfKind(kind))
                      if (ledger.fundBalance(f.id) != 0 || kind == FundKind.savings)
                        AmountRow(
                          f.name,
                          ledger.fundBalance(f.id),
                          detail: kind == FundKind.goal ? 'goal' : null,
                        ),
                  if (next != 0)
                    AmountRow('For ${period.next.label.split(' ').first}', next, detail: 'held'),
                  AmountRow('Total', total, total: true),
                ],
              ),
              PotsTable(ledger: ledger, summary: s),
              ThisMonthCard(ledger: ledger, summary: s),
              SectionCard(
                children: [
                  AmountRow(
                    'Net worth',
                    ledger.netWorth(),
                    detail: 'incl. investments & loans',
                    total: true,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// How this month's spending money adds up: carried forward, income,
/// set aside, spent, loans, to left to spend.
class ThisMonthCard extends StatelessWidget {
  const ThisMonthCard({super.key, required this.ledger, required this.summary});

  final Ledger ledger;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    // Income by type, split by where it went: into Spending (part of this
    // month's sum) or straight into another pot (shown apart, not counted).
    final spending = ledger.spendingFund.id;
    final toSpending = <int?, Poisha>{};
    final elsewhere = <(int?, int), Poisha>{};
    for (final e in ledger.entries) {
      if (e.type != EntryType.income || !s.period.contains(e.date)) continue;
      for (final l in ledger.postingsOf(e.id)) {
        if (l.amount <= 0 || !ledger.isLiquid(l.accountId)) continue;
        final kind = ledger.funds[l.fundId]?.kind;
        if (l.fundId == spending) {
          toSpending.update(e.categoryId, (v) => v + l.amount, ifAbsent: () => l.amount);
        } else if (kind != FundKind.nextMonth) {
          elsewhere.update((e.categoryId, l.fundId), (v) => v + l.amount, ifAbsent: () => l.amount);
        }
      }
    }
    String name(int? category) => ledger.categories[category]?.name ?? 'Income';
    return SectionCard(
      children: [
        const Label('This month'),
        AmountRow('Carried forward', s.carriedForward),
        if (s.released != 0)
          AmountRow(
            'Income for ${s.period.label.split(' ').first}',
            s.released,
            detail: 'received last month',
            signed: true,
          ),
        // Income held for next month is not part of this month's flow.
        for (final MapEntry(:key, :value) in toSpending.entries)
          AmountRow(name(key), value, signed: true),
        if (s.setAside != 0)
          AmountRow('Set aside', -s.setAside, detail: 'savings, goals, DPS', signed: true),
        AmountRow('Spent', -s.spendingExpenses, signed: true),
        if (s.loanNet != 0)
          AmountRow(s.loanNet > 0 ? 'Borrowed' : 'Loan repayment', s.loanNet, signed: true),
        if (s.startingNet != 0) AmountRow('Starting balance', s.startingNet, signed: true),
        if (s.adjustNet != 0) AmountRow('Adjustments', s.adjustNet, signed: true),
        AmountRow('Left to spend', s.leftToSpend, total: true),
        for (final MapEntry(key: (category, fund), :value) in elsewhere.entries)
          Text(
            'Also received: ${name(category)} ${formatTaka(value)} → '
            '${ledger.funds[fund]?.name ?? 'a pot'}',
            style: TextStyle(color: StatusColors.of(context).muted, fontSize: 12),
          ),
      ],
    );
  }
}

/// Each kind of money across your bank, cash and wallets, with totals.
class PotsTable extends StatelessWidget {
  const PotsTable({super.key, required this.ledger, required this.summary});

  final Ledger ledger;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final s = summary;
    final accounts = [
      for (final a in ledger.accountsOfType((t) => t.isLiquid))
        if (!a.archived && ledger.accountBalance(a.id) != 0) a,
    ];
    // Sector name → the funds it adds up.
    final sectors = <(String, List<int>)>[
      ('Spending', [ledger.spendingFund.id]),
      for (final f in ledger.fundsOfKind(FundKind.savings)) (f.name, [f.id]),
      ('Goals', [for (final f in ledger.fundsOfKind(FundKind.goal)) f.id]),
      (
        'For ${s.period.next.label.split(' ').first}',
        [
          for (final f in ledger.funds.values)
            if (f.kind == FundKind.nextMonth) f.id,
        ],
      ),
    ];
    Poisha cell(List<int> funds, int account) =>
        funds.fold(0, (t, f) => t + ledger.cell(account, f));
    final rows = [
      for (final (name, funds) in sectors)
        if (accounts.any((a) => cell(funds, a.id) != 0)) (name, funds),
    ];

    final numbers = TextStyle(
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
    final head = TextStyle(color: status.muted, fontSize: 12, fontWeight: FontWeight.w600);
    final bold = numbers.copyWith(fontWeight: FontWeight.w700);
    // Numbers shrink to fit their column rather than wrap.
    Widget pad(Widget child, {bool right = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: right ? FittedBox(fit: BoxFit.scaleDown, child: child) : child,
      ),
    );
    String amount(Poisha v) => v == 0 ? '–' : formatTaka(v, symbol: false);

    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FlexColumnWidth(1.3),
        for (var i = 1; i <= accounts.length + 1; i++) i: const FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: status.line)),
          ),
          children: [
            pad(Text('Sector', style: head), right: false),
            for (final a in accounts)
              pad(Text(a.name, style: head, maxLines: 1, overflow: TextOverflow.ellipsis)),
            pad(Text('Total', style: head)),
          ],
        ),
        for (final (name, funds) in rows)
          TableRow(
            children: [
              pad(Text(name, maxLines: 2, overflow: TextOverflow.ellipsis), right: false),
              for (final a in accounts) pad(Text(amount(cell(funds, a.id)), style: numbers)),
              pad(
                Text(
                  amount(accounts.fold(0, (t, a) => t + cell(funds, a.id))),
                  style: numbers.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        TableRow(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: status.line)),
          ),
          children: [
            pad(const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)), right: false),
            for (final a in accounts) pad(Text(amount(ledger.accountBalance(a.id)), style: bold)),
            pad(Text(amount(ledger.liquidTotal()), style: bold)),
          ],
        ),
      ],
    );

    return SectionCard(
      children: [
        const Label('By account'),
        // Many accounts: scroll sideways rather than squeeze.
        if (accounts.length > 3)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 110 + 90.0 * (accounts.length + 1), child: table),
          )
        else
          table,
      ],
    );
  }
}

/// The kinds of money on Home's short card: Spending, the main savings pot,
/// everything saved for particular things (goals and other pots), and
/// income held for next month.
class MoneyOutline {
  const MoneyOutline({
    required this.spending,
    required this.savingsName,
    required this.savings,
    required this.savedForThings,
    required this.heldForNext,
    required this.unplanned,
  });

  factory MoneyOutline.of(Ledger ledger) {
    final pots = ledger.fundsOfKind(FundKind.savings).toList();
    // The first savings pot (Monthly Savings) is "savings"; the others, like
    // goals, are money kept for a particular thing.
    final main = pots.firstOrNull;
    Poisha sum(Iterable<Fund> funds) => funds.fold(0, (t, f) => t + ledger.fundBalance(f.id));
    return MoneyOutline(
      spending: ledger.fundBalance(ledger.spendingFund.id),
      savingsName: main?.name ?? 'Savings',
      savings: main == null ? 0 : ledger.fundBalance(main.id),
      savedForThings: sum(pots.skip(1)) + sum(ledger.fundsOfKind(FundKind.goal)),
      heldForNext: ledger.heldForNextMonth,
      unplanned: ledger.unplannedMoney,
    );
  }

  final Poisha spending;
  final String savingsName;
  final Poisha savings;
  final Poisha savedForThings;
  final Poisha heldForNext;

  /// The Unplanned pot.
  final Poisha unplanned;
}
