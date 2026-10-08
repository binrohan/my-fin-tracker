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
import '../../ui/widgets.dart';

class SaveScreen extends ConsumerWidget {
  const SaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(builder: (context, ledger) {
      final period = Period.of(today);
      final savings = ledger.fundsOfKind(FundKind.savings).toList();
      final goals = [
        for (final f in ledger.fundsOfKind(FundKind.goal)) ledger.goalStatus(f, today),
      ];
      final pots = [...savings.map((f) => ledger.fundBalance(f.id)), ...goals.map((g) => g.saved)]
          .fold<Poisha>(0, (t, v) => t + v);
      final loans = ledger.openLoans();
      final investments = ledger
          .accountsOfType((t) => t == AccountType.investment)
          .where((a) => ledger.accountBalance(a.id) != 0);

      return PageList(children: [
        ScreenHeader('Savings', subtitle: '${formatTaka(pots)} across all pots'),
        for (final f in savings) _SavingsCard(ledger: ledger, fund: f, period: period),
        if (goals.isNotEmpty) const Label('Saving for something'),
        for (final g in goals) _GoalCard(goal: g),
        if (loans.isNotEmpty) const Label('Loans'),
        for (final l in loans) _LoanCard(ledger: ledger, status: l),
        if (investments.isNotEmpty)
          SectionCard(children: [
            const Label('Investments'),
            for (final a in investments) AmountRow(a.name, ledger.accountBalance(a.id)),
            AmountRow('Total', ledger.investmentTotal(), total: true),
          ]),
      ]);
    });
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
    return SectionCard(children: [
      Label(fund.name),
      Money(ledger.fundBalance(fund.id),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      Row(children: [
        Expanded(
          child: Text(
            added == 0 ? 'Nothing added this month' : '${formatTaka(added, showPlus: true)} this month',
            style: TextStyle(color: added > 0 ? StatusColors.of(context).good : null),
          ),
        ),
        if (owed > 0) StatusChip('${formatTaka(owed)} owed back', tone: ChipTone.warn),
      ]),
    ]);
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
    if (g.reached) {
      advice = 'Target reached.';
    } else if (needed == null) {
      advice = g.monthly > 0 ? 'Saving ${formatTaka(g.monthly)}/mo.' : 'No deposits yet.';
    } else if (g.onTrack) {
      advice = 'Target ${DateFormat.yMMM().format(target!)} needs ${formatTaka(needed)}/mo. '
          'You save ${formatTaka(g.monthly)}/mo.';
    } else {
      advice = 'Target ${DateFormat.yMMM().format(target!)} needs ${formatTaka(needed)}/mo.';
      if (finish != null) {
        advice += ' At ${formatTaka(g.monthly)}/mo you\'ll finish in ${finish.shortLabel}.';
      }
    }

    return SectionCard(children: [
      Row(children: [
        Expanded(
          child: Text(g.fund.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        g.reached
            ? const StatusChip('Reached', tone: ChipTone.good)
            : g.onTrack
                ? const StatusChip('On track', tone: ChipTone.good)
                : const StatusChip('Behind', tone: ChipTone.warn),
      ]),
      Row(children: [
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: formatTaka(g.saved, symbol: false)),
            TextSpan(
                text: ' of ${formatTaka(g.target, symbol: false)}',
                style: TextStyle(color: status.muted)),
          ])),
        ),
        Text('${(g.progress * 100).toStringAsFixed(1)}%'),
      ]),
      Bar(g.progress, color: g.onTrack ? status.good : status.warn),
      Text(advice, style: TextStyle(color: status.muted, fontSize: 13)),
    ]);
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.ledger, required this.status});

  final Ledger ledger;
  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final loan = status.loan;
    final person = loan.personAccountId == null ? null : ledger.accounts[loan.personAccountId]!.name;
    final (title, chip, tone, leftLabel) = switch (loan.kind) {
      LoanKind.ownSavings => ('From ${ledger.funds[loan.fundId]!.name}', 'Own savings', ChipTone.warn, 'You owe'),
      LoanKind.lent => (person!, 'Lent', ChipTone.good, 'Owes you'),
      LoanKind.borrowed => (person!, 'Borrowed', ChipTone.bad, 'You owe'),
    };
    final rate = loan.chargeRateBp == 0 ? 'no charge' : 'charge ${formatPercentBp(loan.chargeRateBp)}';

    return SectionCard(children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        StatusChip(chip, tone: tone),
      ]),
      Text(
        [DateFormat.yMMMd().format(loan.date), rate, if (loan.note.isNotEmpty) loan.note].join(' · '),
        style: TextStyle(color: colors.muted, fontSize: 13),
      ),
      AmountRow(loan.kind == LoanKind.lent ? 'Lent' : 'Borrowed', loan.principal),
      if (loan.charge > 0) AmountRow('Charge', loan.charge),
      AmountRow(loan.kind == LoanKind.lent ? 'Received back' : 'Paid back', status.repaid,
          color: colors.good),
      Bar(status.progress, color: colors.good),
      AmountRow(leftLabel, status.remaining,
          total: true, color: loan.kind == LoanKind.lent ? colors.good : colors.bad),
    ]);
  }
}
