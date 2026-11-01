import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../ledger/afford.dart';
import '../../ledger/enums.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// Type a price and see whether this month's money covers it, what it
/// leaves a day, and what else could pay for it.
class AffordScreen extends ConsumerStatefulWidget {
  const AffordScreen({super.key});

  @override
  ConsumerState<AffordScreen> createState() => _AffordScreenState();
}

class _AffordScreenState extends ConsumerState<AffordScreen> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Can I afford it?')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final amount = parseTaka(_amount.text) ?? 0;
          final a = amount > 0 ? Affordability.of(ledger, amount, today) : null;
          return PageList(
            children: [
              AmountField(
                controller: _amount,
                label: 'Price',
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              if (a == null)
                Text(
                  'Checks it against what is left to spend this month, the budgets still '
                  'waiting, and your savings.',
                  style: TextStyle(color: StatusColors.of(context).muted),
                )
              else ...[
                _Verdict(a: a),
                _Breakdown(a: a),
                if (a.verdict != AffordVerdict.yes) _Options(a: a),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.a});

  final Affordability a;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final (title, body, color, soft) = switch (a.verdict) {
      AffordVerdict.yes => (
        'Yes',
        'It fits in money no budget is waiting for.',
        status.good,
        status.goodSoft,
      ),
      AffordVerdict.tight => (
        'Yes, but it is tight',
        'It takes ${formatTaka(a.fromBudgets)} that your budgets still need this month.',
        status.warn,
        status.warnSoft,
      ),
      AffordVerdict.fromSavings => (
        'Not from this month alone',
        '${formatTaka(a.fromSavingsAmount)} would have to come from savings.',
        status.warn,
        status.warnSoft,
      ),
      AffordVerdict.saveUp => (
        'Not now',
        'It is more than this month\'s money and your savings together.',
        status.bad,
        status.badSoft,
      ),
    };
    return SectionCard(
      color: soft,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        Text(body, style: TextStyle(color: color)),
        if (a.perDayAfter case final perDay?)
          Text(
            'Afterwards ≈ ${formatTaka(perDay)} a day for ${a.daysLeft} days',
            style: TextStyle(color: color),
          ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.a});

  final Affordability a;

  @override
  Widget build(BuildContext context) => SectionCard(
    children: [
      const Label('This month'),
      AmountRow('Left to spend', a.leftToSpend),
      AmountRow('Budgets still waiting', -a.planned, signed: true),
      AmountRow('Not in a budget', a.unplanned, total: true),
      AmountRow('This purchase', -a.amount, signed: true),
      AmountRow('Left to spend after', a.after, total: true, signed: a.after < 0),
    ],
  );
}

class _Options extends ConsumerWidget {
  const _Options({required this.a});

  final Affordability a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = StatusColors.of(context);
    final months = a.monthsToSave;
    return SectionCard(
      children: [
        const Label('Other ways'),
        if (a.verdict == AffordVerdict.fromSavings) ...[
          AmountRow('In your savings', a.savings),
          AmountRow(
            'Borrow from savings',
            a.fromSavingsAmount,
            detail: a.charge > 0 ? '+ ${formatTaka(a.charge)} charge' : null,
          ),
        ],
        if (months != null)
          Text(
            months <= 1
                ? 'A usual month leaves about ${formatTaka(a.monthlySpare!)}: enough by next month.'
                : 'A usual month leaves about ${formatTaka(a.monthlySpare!)}: '
                      'about $months months to save it up.',
          )
        else
          Text(
            'Not enough history yet to say how long saving up would take.',
            style: TextStyle(color: status.muted),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _makeGoal(context, ref, a.amount),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Save up for it as a goal'),
          ),
        ),
      ],
    );
  }

  Future<void> _makeGoal(BuildContext context, WidgetRef ref, Poisha amount) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New goal of ${formatTaka(amount)}'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. New Phone'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    final text = name.text.trim();
    if (ok != true || text.isEmpty) return;
    await ref.read(setupRepositoryProvider).addFund(text, FundKind.goal, target: amount);
    if (context.mounted) showSnack(context, 'Goal "$text" added. Find it on the Save tab.');
  }
}
