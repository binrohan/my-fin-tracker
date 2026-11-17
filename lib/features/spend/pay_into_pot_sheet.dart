import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import 'save_budget_sheet.dart';

/// Pays a bill into a pot instead of spending it (the Cycle instalment put
/// aside as cash in the Cycle pot): it counts as paid this month, and the
/// money stays yours in the pot, in whichever account you choose.
Future<void> showPayIntoPotSheet(BuildContext context, Period period, {required int categoryId}) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PayIntoPotSheet(period: period, categoryId: categoryId),
    );

class _PayIntoPotSheet extends ConsumerStatefulWidget {
  const _PayIntoPotSheet({required this.period, required this.categoryId});

  final Period period;
  final int categoryId;

  @override
  ConsumerState<_PayIntoPotSheet> createState() => _PayIntoPotSheetState();
}

class _PayIntoPotSheetState extends ConsumerState<_PayIntoPotSheet> {
  final _amount = TextEditingController();
  bool _ready = false;
  int? _fund;
  int? _from;
  int? _to;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final status = StatusColors.of(context);
    final period = widget.period;
    final category = ledger.categoriesIn(period)[widget.categoryId];
    final pots = savingPots(ledger);
    final cells = ledger.spendingCells(period);
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();
    final left = ledger.movableFrom(widget.categoryId, period);
    if (!_ready) {
      _ready = true;
      final linked = category?.savingsFundId;
      _fund = pots.any((f) => f.id == linked) ? linked : pots.firstOrNull?.id;
      _from = cells.firstOrNull?.account;
      _to = _from;
      _amount.text = amountText(left);
    }

    if (category == null || pots.isEmpty) {
      return SheetBody(
        title: 'Pay into a pot',
        children: [
          Text(
            'Add a savings pot or a goal first, in More → Accounts & pots.',
            style: TextStyle(color: status.muted),
          ),
        ],
      );
    }

    final inAccount = cells.where((c) => c.account == _from).firstOrNull?.amount ?? 0;
    final amount = parseTaka(_amount.text) ?? 0;
    final limit = math.min(left, inAccount);
    final fund = ledger.funds[_fund];
    final ok = fund != null && _from != null && _to != null && amount > 0 && amount <= limit;

    return SheetBody(
      title: 'Pay ${category.name} into a pot',
      children: [
        Text(
          'Counts as paid in ${category.name} for ${period.label}. The money stays yours, in the '
          'pot; spend it from there later.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        const Label('From this month\'s money in'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in cells)
              ChoiceChip(
                label: Text('${ledger.accounts[c.account]?.name} · ${formatTaka(c.amount)}'),
                selected: _from == c.account,
                onSelected: (_) => setState(() {
                  // Keep "put it in" with the money unless it was changed.
                  if (_to == _from) _to = c.account;
                  _from = c.account;
                }),
              ),
          ],
        ),
        const Label('Into the pot'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in pots)
              ChoiceChip(
                label: Text(f.name),
                selected: _fund == f.id,
                onSelected: (_) => setState(() => _fund = f.id),
              ),
          ],
        ),
        const Label('Kept in'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in accounts)
              ChoiceChip(
                label: Text(a.name),
                selected: _to == a.id,
                onSelected: (_) => setState(() => _to = a.id),
              ),
          ],
        ),
        AmountField(controller: _amount, label: 'Amount', onChanged: (_) => setState(() {})),
        Text(
          left == 0
              ? '${category.name} is already paid this month.'
              : amount > limit
              ? 'At most ${formatTaka(limit)}'
                    '${inAccount < left ? ' (this month\'s money in this account)' : ' (still to pay)'}.'
              : '${formatTaka(left)} still to pay.',
          style: TextStyle(color: amount > limit ? status.bad : status.muted, fontSize: 13),
        ),
        FilledButton(
          onPressed: !ok
              ? null
              : () async {
                  final today = ref.read(todayProvider);
                  final date = period.contains(today)
                      ? today
                      : period.end.subtract(const Duration(days: 1));
                  await ref
                      .read(repositoryProvider)
                      .payIntoPot(
                        categoryId: category.id,
                        categoryName: category.name,
                        fromAccount: _from!,
                        spendingFund: ledger.spendingFund.id,
                        toAccount: _to!,
                        fundId: fund.id,
                        amount: amount,
                        date: date,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(
                    context,
                    '${category.name} paid · ${formatTaka(amount)} in ${fund.name}',
                  );
                },
          child: Text(fund == null ? 'Pay' : 'Pay ${formatTaka(amount)} into ${fund.name}'),
        ),
      ],
    );
  }
}
