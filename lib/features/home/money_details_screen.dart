import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
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
