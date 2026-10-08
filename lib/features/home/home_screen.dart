import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(builder: (context, ledger) {
      final period = Period.of(today);
      final header = ScreenHeader(
        period.label,
        subtitle: 'Day ${today.day} of ${period.daysInMonth}',
        trailing: ledger.isBalanced
            ? const StatusChip('✓ Balanced', tone: ChipTone.good)
            : const StatusChip('Not balanced', tone: ChipTone.bad),
      );
      if (ledger.isEmpty) return PageList(children: [header, const _EmptyHome()]);

      final s = ledger.summary(period);
      return PageList(children: [
        header,
        _LeftToSpend(summary: s, today: today),
        _ThisMonth(ledger: ledger, summary: s),
        _WhereAndWhat(ledger: ledger),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AmountRow('Net worth', ledger.netWorth(),
              detail: 'incl. investments & loans'),
        ),
      ]);
    });
  }
}

class _LeftToSpend extends StatelessWidget {
  const _LeftToSpend({required this.summary, required this.today});

  final PeriodSummary summary;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    final s = summary;
    final perDay = s.perDay(today);
    final daysLeft = s.period.daysInMonth - today.day + 1;
    final planned = s.leftToSpend <= 0 ? 1.0 : s.budgetLeft / s.leftToSpend;

    return SectionCard(color: scheme.primary, children: [
      Label('Left to spend', color: on.withValues(alpha: .8)),
      Money(s.leftToSpend,
          color: on,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.05)),
      if (perDay != null && perDay > 0)
        Text('≈ ${formatTaka(perDay)} a day for $daysLeft days',
            style: TextStyle(color: on)),
      Bar(planned, color: on, height: 6),
      DefaultTextStyle.merge(
        style: TextStyle(color: on, fontSize: 13),
        child: Row(children: [
          Expanded(child: Text('Budgeted ${formatTaka(s.budgetLeft)}')),
          Text(s.unplanned >= 0
              ? 'Unplanned ${formatTaka(s.unplanned)}'
              : 'Short ${formatTaka(-s.unplanned)}'),
        ]),
      ),
    ]);
  }
}

class _ThisMonth extends StatelessWidget {
  const _ThisMonth({required this.ledger, required this.summary});

  final Ledger ledger;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final income = ledger
        .categoryLines(s.period, CategoryKind.income)
        .where((l) => l.actual != 0);
    return SectionCard(children: [
      const Label('This month'),
      AmountRow('Carried forward', s.carriedForward),
      for (final line in income) AmountRow(line.category.name, line.actual, signed: true),
      if (s.setAside != 0)
        AmountRow('Set aside', -s.setAside, detail: 'savings, goals, DPS', signed: true),
      AmountRow('Spent', -s.spendingExpenses, signed: true),
      if (s.loanNet != 0)
        AmountRow(s.loanNet > 0 ? 'Borrowed' : 'Loan repayment', s.loanNet, signed: true),
      if (s.otherNet != 0) AmountRow('Adjustments', s.otherNet, signed: true),
      AmountRow('Left to spend', s.leftToSpend, total: true),
    ]);
  }
}

class _WhereAndWhat extends StatelessWidget {
  const _WhereAndWhat({required this.ledger});

  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final liquid = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived);
    final goals = ledger
        .fundsOfKind(FundKind.goal)
        .fold<Poisha>(0, (t, f) => t + ledger.fundBalance(f.id));
    final total = ledger.liquidTotal();

    // Stacked, not side by side: at phone width with Android's font sizes
    // two half-width cards wrap names like "Spending".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionCard(children: [
          const Label('Where it is'),
          for (final a in liquid) AmountRow(a.name, ledger.accountBalance(a.id)),
          AmountRow('Total', total, total: true),
        ]),
        SectionCard(children: [
          const Label("What it's for"),
          AmountRow('Spending', ledger.fundBalance(ledger.spendingFund.id)),
          for (final f in ledger.fundsOfKind(FundKind.savings))
            AmountRow(f.name, ledger.fundBalance(f.id)),
          if (goals != 0) AmountRow('Goals', goals),
          AmountRow('Total', total, total: true),
        ]),
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) => SectionCard(children: [
        Text('No entries yet', style: Theme.of(context).textTheme.titleMedium),
        Text(
          'Your balances, this month\'s spending and your savings will show here. '
          'Quick add for entering expenses arrives in the next build. '
          'To look around now, load the example months from More.',
          style: TextStyle(color: StatusColors.of(context).muted),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: () => context.go('/more'),
            child: const Text('Go to More'),
          ),
        ),
      ]);
}
