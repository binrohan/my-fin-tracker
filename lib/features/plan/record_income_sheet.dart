import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/allocation.dart';
import '../../ledger/enums.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// "Has your Salary arrived?": records a planned income in the account it
/// arrived in and puts it where it belongs at once: the plan's pots, the
/// spending part (now or parked for next month), the rest to Unplanned.
Future<void> showRecordIncome(BuildContext context, IncomeSource source) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _RecordIncomeSheet(source: source),
);

class _RecordIncomeSheet extends ConsumerStatefulWidget {
  const _RecordIncomeSheet({required this.source});

  final IncomeSource source;

  @override
  ConsumerState<_RecordIncomeSheet> createState() => _RecordIncomeSheetState();
}

class _RecordIncomeSheetState extends ConsumerState<_RecordIncomeSheet> {
  late final _amount = TextEditingController(text: amountText(widget.source.amount));
  int? _account;
  late DateTime _date = ref.read(todayProvider);
  bool _split = true;

  /// Where the money (or, after the split, its spending part) goes.
  late IncomeTo _to = widget.source.forNextMonth ? IncomeTo.nextMonth : IncomeTo.spending;
  int? _pot;

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
    final today = ref.watch(todayProvider);
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();
    _account ??= accounts.any((a) => a.id == widget.source.accountId)
        ? widget.source.accountId
        : defaultAccount(ledger, AccountType.bank).id;
    final name = ledger.categories[widget.source.categoryId]?.name ?? 'Income';
    // The Monthly plan is a blueprint: used as it is now, when income arrives.
    final plan = ledger.latestPlan;
    final offersSplit = plan.categoryId == widget.source.categoryId && !plan.isEmpty;
    final splitting = offersSplit && _split;
    final amount = parseTaka(_amount.text) ?? 0;
    final next = Period.of(_date).next;
    final nextName = next.label.split(' ').first;
    final pots = [
      ...ledger.fundsOfKind(FundKind.savings),
      ...ledger.fundsOfKind(FundKind.goal).where((f) => f.achievedAt == null),
    ];

    // What goes where, as the repository will do it.
    var left = amount;
    final parts = <(String, Poisha)>[];
    if (splitting) {
      for (final i in plan.items) {
        final part = i.amount < left ? i.amount : left;
        if (part <= 0) break;
        parts.add((ledger.funds[i.fundId]?.name ?? 'Pot', part));
        left -= part;
      }
    }
    final target = plan.expenseTarget;
    final spendPart = splitting && target != null && left > target ? target : left;
    final extra = left - spendPart;
    final toLabel = switch (_to) {
      IncomeTo.spending => 'This month',
      IncomeTo.nextMonth => 'Held for $nextName',
      IncomeTo.unplanned => 'Floating',
      IncomeTo.pot => ledger.funds[_pot]?.name ?? 'a pot',
    };

    Widget choice(String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => setState(onTap));

    return SheetBody(
      title: 'Record $name',
      children: [
        AmountField(
          controller: _amount,
          label: 'Amount received',
          onChanged: (_) => setState(() {}),
        ),
        Text('Received in', style: TextStyle(color: status.muted)),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final a in accounts) choice(a.name, a.id == _account, () => _account = a.id),
          ],
        ),
        PickerField(
          label: 'Date',
          value: dayLabel(_date, today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: today,
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        if (offersSplit)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Split as planned, now'),
            subtitle: const Text('Fills your pots today, from the Monthly plan'),
            value: _split,
            onChanged: (v) => setState(() => _split = v),
          ),
        Text(splitting ? 'Expense part goes to' : 'Goes to', style: TextStyle(color: status.muted)),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            choice('Held for $nextName', _to == IncomeTo.nextMonth, () => _to = IncomeTo.nextMonth),
            choice('This month', _to == IncomeTo.spending, () => _to = IncomeTo.spending),
            choice('Floating', _to == IncomeTo.unplanned, () => _to = IncomeTo.unplanned),
            if (!splitting)
              for (final f in pots)
                choice(f.name, _to == IncomeTo.pot && _pot == f.id, () {
                  _to = IncomeTo.pot;
                  _pot = f.id;
                }),
          ],
        ),
        if (amount > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: status.sunk, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                for (final (pot, value) in parts) AmountRow(pot, value),
                AmountRow(toLabel, spendPart, total: parts.isNotEmpty),
                if (extra > 0) AmountRow('Floating', extra, detail: 'more than planned'),
              ],
            ),
          ),
        FilledButton(
          onPressed: amount <= 0 || (_to == IncomeTo.pot && _pot == null)
              ? null
              : () async {
                  await ref
                      .read(repositoryProvider)
                      .receiveIncome(
                        _date,
                        amount,
                        categoryId: widget.source.categoryId,
                        account: _account!,
                        to: (splitting && _to == IncomeTo.pot) ? IncomeTo.spending : _to,
                        potFund: _pot,
                        split: splitting ? plan : null,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(context, '$name recorded');
                },
          child: Text('Record ${formatTaka(amount)}'),
        ),
      ],
    );
  }
}
