import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ui/forms.dart';

/// Spends pot money directly: no section or budget is touched.
Future<void> showUsePot(BuildContext context, Fund fund, int account) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _PotSheet(fund: fund, account: account, toSection: false),
);

/// Moves pot money into a section: its budget this month grows by the amount.
Future<void> showMoveToSection(BuildContext context, Fund fund, int account) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PotSheet(fund: fund, account: account, toSection: true),
    );

class _PotSheet extends ConsumerStatefulWidget {
  const _PotSheet({required this.fund, required this.account, required this.toSection});

  final Fund fund;
  final int account;
  final bool toSection;

  @override
  ConsumerState<_PotSheet> createState() => _PotSheetState();
}

class _PotSheetState extends ConsumerState<_PotSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late int _account = widget.account;
  late DateTime _date = ref.read(todayProvider);
  CategoryRow? _section;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final status = StatusColors.of(context);
    final today = ref.watch(todayProvider);
    final fund = widget.fund;
    final amount = parseTaka(_amount.text) ?? 0;
    final available = ledger.cell(_account, fund.id);
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived);
    final ready =
        amount > 0 && (widget.toSection ? _section != null : _note.text.trim().isNotEmpty);

    return SheetBody(
      title: widget.toSection ? 'Move ${fund.name} to a section' : 'Use ${fund.name}',
      children: [
        Text(
          widget.toSection
              ? 'The section\'s budget this month grows by the amount.'
              : 'It comes off this pot and the account. No monthly budget changes.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        AmountField(
          controller: _amount,
          label: 'Amount',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        if (amount > available)
          Text(
            'More than the ${formatTaka(available)} of this pot in '
            '${ledger.accounts[_account]?.name}.',
            style: TextStyle(color: status.warn),
          ),
        Text(widget.toSection ? 'Money is in' : 'Paid from', style: TextStyle(color: status.muted)),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final a in accounts)
              ChoiceChip(
                label: Text(a.name),
                selected: a.id == _account,
                onSelected: (_) => setState(() => _account = a.id),
              ),
          ],
        ),
        if (widget.toSection)
          PickerField(
            label: 'To section',
            value: _section?.name ?? 'Choose',
            onTap: () async {
              final picked = await pickCategory(context, ledger, CategoryKind.expense);
              if (picked != null) setState(() => _section = picked);
            },
          )
        else
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'What was it for?',
              border: OutlineInputBorder(),
            ),
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
        FilledButton(
          onPressed: !ready
              ? null
              : () async {
                  final repo = ref.read(repositoryProvider);
                  final from = (account: _account, fund: fund.id);
                  if (widget.toSection) {
                    await repo.moveToSection(
                      _date,
                      amount,
                      from: from,
                      categoryId: _section!.id,
                      spendingFund: ledger.spendingFund.id,
                    );
                  } else {
                    await repo.usePot(_date, amount, from, _note.text.trim());
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(
                    context,
                    widget.toSection
                        ? '${formatTaka(amount)} moved to ${_section!.name}'
                        : '${formatTaka(amount)} used from ${fund.name}',
                  );
                },
          child: Text(
            widget.toSection ? 'Move ${formatTaka(amount)}' : 'Use ${formatTaka(amount)}',
          ),
        ),
      ],
    );
  }
}
