import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/ledger_repository.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// Moves money between pots: deposit to savings, withdraw from a goal,
/// move a cash sector, put cash in the bank.
Future<void> showMoveSheet(
  BuildContext context, {
  required String title,
  required Pot from,
  required Pot to,
  String action = 'Move',
  String? hint,
  bool lockFrom = false,
  bool lockTo = false,
  String note = '',
  Poisha? suggested,
}) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MoveSheet(
    title: title,
    from: from,
    to: to,
    action: action,
    hint: hint,
    lockFrom: lockFrom,
    lockTo: lockTo,
    note: note,
    suggested: suggested,
  ),
);

class _MoveSheet extends ConsumerStatefulWidget {
  const _MoveSheet({
    required this.title,
    required this.from,
    required this.to,
    required this.action,
    required this.hint,
    required this.lockFrom,
    required this.lockTo,
    required this.note,
    required this.suggested,
  });

  final String title;
  final Pot from;
  final Pot to;
  final String action;
  final String? hint;
  final bool lockFrom;
  final bool lockTo;
  final String note;
  final Poisha? suggested;

  @override
  ConsumerState<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends ConsumerState<_MoveSheet> {
  late Pot _from = widget.from;
  late Pot _to = widget.to;
  late final _amount = TextEditingController(text: amountText(widget.suggested ?? 0));
  late DateTime _date = ref.read(todayProvider);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final amount = parseTaka(_amount.text) ?? 0;
    final available = ledger.cell(_from.account, _from.fund);
    final today = ref.watch(todayProvider);
    final status = StatusColors.of(context);

    Widget pot(String label, Pot value, bool locked, ValueChanged<Pot> set) => locked
        ? AmountRow(label, ledger.cell(value.account, value.fund), detail: potLabel(ledger, value))
        : PickerField(
            label: label,
            value:
                '${potLabel(ledger, value)} · ${formatTaka(ledger.cell(value.account, value.fund))}',
            onTap: () async {
              final picked = await pickPot(
                context,
                ledger,
                title: label,
                initial: value,
                includeInvestments: true,
              );
              if (picked != null) setState(() => set(picked));
            },
          );

    return SheetBody(
      title: widget.title,
      children: [
        if (widget.hint != null) Text(widget.hint!, style: TextStyle(color: status.muted)),
        pot('From', _from, widget.lockFrom, (p) => _from = p),
        pot('To', _to, widget.lockTo, (p) => _to = p),
        AmountField(
          controller: _amount,
          label: 'Amount',
          autofocus: widget.suggested == null,
          onChanged: (_) => setState(() {}),
        ),
        if (amount > available)
          Text(
            'More than the ${formatTaka(available)} in ${potLabel(ledger, _from)}.',
            style: TextStyle(color: status.warn),
          ),
        PickerField(
          label: 'Date',
          value: dayLabel(_date, today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: today.add(const Duration(days: 366)),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        FilledButton(
          onPressed: amount <= 0 || _from == _to
              ? null
              : () async {
                  await ref
                      .read(repositoryProvider)
                      .move(_date, amount, from: _from, to: _to, note: widget.note);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(context, '${widget.action} ${formatTaka(amount)} done');
                },
          child: Text(amount > 0 ? '${widget.action} ${formatTaka(amount)}' : widget.action),
        ),
      ],
    );
  }
}
