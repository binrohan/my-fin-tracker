import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../investments/investments_screen.dart';
import '../loans/loan_sheets.dart';
import '../loans/loans_screen.dart';
import '../setup/accounts_screen.dart';
import 'fund_screen.dart';

class SaveScreen extends ConsumerWidget {
  const SaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(
      builder: (context, ledger) {
        final period = Period.of(today);
        final status = StatusColors.of(context);
        final savings = ledger.fundsOfKind(FundKind.savings).toList();
        final goals = [
          for (final f in ledger.fundsOfKind(FundKind.goal)) ledger.goalStatus(f, today),
        ];
        final active = goals.where((g) => g.fund.achievedAt == null).toList();
        final achieved = goals.where((g) => g.fund.achievedAt != null).toList();
        final pots = [
          ...savings.map((f) => ledger.fundBalance(f.id, liquidOnly: false)),
          ...active.map((g) => g.saved),
        ].fold<Poisha>(0, (t, v) => t + v);
        final loans = ledger.openLoans();
        final investments = ledger
            .accountsOfType((t) => t == AccountType.investment)
            .where((a) => ledger.accountBalance(a.id) != 0);

        return PageList(
          children: [
            ScreenHeader(
              'Savings',
              subtitle: '${formatTaka(pots)} across all pots',
              trailing: OutlinedButton.icon(
                onPressed: () => openScreen(context, const AccountsScreen()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Goal'),
              ),
            ),
            for (final f in savings) _SavingsCard(ledger: ledger, fund: f, period: period),
            if (active.isNotEmpty) const Label('Saving for something'),
            for (final g in active) _GoalCard(goal: g),
            if (achieved.isNotEmpty)
              SectionCard(
                children: [
                  const Label('Achieved'),
                  for (final g in achieved)
                    InkWell(
                      onTap: () => openScreen(context, FundScreen(fundId: g.fund.id)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AmountRow(
                          '${g.fund.name} ✓',
                          g.target,
                          detail: DateFormat.yMMM().format(g.fund.achievedAt!),
                        ),
                      ),
                    ),
                ],
              ),
            Row(
              children: [
                const Expanded(child: Label('Loans')),
                TextButton(
                  onPressed: () => openScreen(context, const LoansScreen()),
                  child: const Text('All loans'),
                ),
              ],
            ),
            if (loans.isEmpty)
              SectionCard(
                children: [
                  Text('No open loans.', style: TextStyle(color: status.muted)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showNewLoan(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New loan'),
                    ),
                  ),
                ],
              ),
            for (final l in loans)
              LoanCard(
                ledger: ledger,
                status: l,
                onTap: () => openScreen(context, LoanScreen(loanId: l.loan.id)),
              ),
            if (investments.isNotEmpty)
              SectionCard(
                onTap: () => openScreen(context, const InvestmentsScreen()),
                children: [
                  const Label('Investments'),
                  for (final a in investments) AmountRow(a.name, ledger.accountBalance(a.id)),
                  AmountRow('Total', ledger.investmentTotal(), total: true),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.ledger, required this.fund, required this.period});

  final Ledger ledger;
  final Fund fund;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final added = ledger.movedInto(fund.id, period);
    final owed = ledger.owedToFund(fund.id);
    final lent = ledger.fundBalance(fund.id, liquidOnly: false) - ledger.fundBalance(fund.id);
    return SectionCard(
      onTap: () => openScreen(context, FundScreen(fundId: fund.id)),
      children: [
        Row(
          children: [
            Expanded(child: Label(fund.name)),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        Money(
          ledger.fundBalance(fund.id),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              added == 0
                  ? 'Nothing added this month'
                  : '${formatTaka(added, showPlus: true)} this month',
              style: TextStyle(color: added > 0 ? StatusColors.of(context).good : null),
            ),
            if (owed > 0) StatusChip('${formatTaka(owed)} owed back', tone: ChipTone.warn),
            if (lent > 0) StatusChip('${formatTaka(lent)} lent out', tone: ChipTone.accent),
          ],
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final GoalStatus goal;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final g = goal;
    final target = g.fund.targetDate;
    final needed = g.neededPerMonth;
    final finish = g.projectedFinish;

    String advice;
    if (g.target == 0) {
      advice = 'No target set.';
    } else if (g.reached) {
      advice = 'Target reached. Tap to record the purchase.';
    } else if (needed == null) {
      advice = g.monthly > 0 ? 'Saving ${formatTaka(g.monthly)}/mo.' : 'No deposits yet.';
    } else if (g.onTrack) {
      advice =
          'Target ${DateFormat.yMMM().format(target!)} needs ${formatTaka(needed)}/mo. '
          'You save ${formatTaka(g.monthly)}/mo.';
    } else {
      advice = 'Target ${DateFormat.yMMM().format(target!)} needs ${formatTaka(needed)}/mo.';
      if (finish != null) {
        advice += ' At ${formatTaka(g.monthly)}/mo you\'ll finish in ${finish.shortLabel}.';
      }
    }

    return SectionCard(
      onTap: () => openScreen(context, FundScreen(fundId: g.fund.id)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                g.fund.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (g.target > 0)
              g.reached
                  ? const StatusChip('Reached', tone: ChipTone.good)
                  : g.onTrack
                  ? const StatusChip('On track', tone: ChipTone.good)
                  : const StatusChip('Behind', tone: ChipTone.warn),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: formatTaka(g.saved, symbol: false)),
                    if (g.target > 0)
                      TextSpan(
                        text: ' of ${formatTaka(g.target, symbol: false)}',
                        style: TextStyle(color: status.muted),
                      ),
                  ],
                ),
              ),
            ),
            if (g.target > 0) Text('${(g.progress * 100).toStringAsFixed(1)}%'),
          ],
        ),
        if (g.target > 0) Bar(g.progress, color: g.onTrack ? status.good : status.warn),
        Text(advice, style: TextStyle(color: status.muted, fontSize: 13)),
      ],
    );
  }
}
