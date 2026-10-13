import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/allocation.dart';
import '../../ledger/enums.dart';
import '../../ui/forms.dart';

/// "Has your Salary arrived?": records a planned income in the account it
/// arrived in, and sets money aside as the plan says.
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
  bool _setAside = true;
  late bool _forNextMonth = widget.source.forNextMonth;

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
    final plan = ledger.plan;
    final offersSplit = plan.categoryId == widget.source.categoryId && !plan.isEmpty;
    final amount = parseTaka(_amount.text) ?? 0;
    final next = Period.of(_date).next;
    final firstOfNext = DateFormat.MMMd().format(next.start);

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
            for (final a in accounts)
              ChoiceChip(
                label: Text(a.name),
                selected: a.id == _account,
                onSelected: (_) => setState(() => _account = a.id),
              ),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('For ${next.label}'),
          subtitle: Text(
            _forNextMonth
                ? 'Held until $firstOfNext, then it becomes ${next.label}\'s spending money'
                : 'Counts as spending money now',
          ),
          value: _forNextMonth,
          onChanged: (v) => setState(() => _forNextMonth = v),
        ),
        if (offersSplit)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _forNextMonth
                  ? 'Set aside ${formatTaka(plan.total)} on $firstOfNext as planned'
                  : 'Set aside ${formatTaka(plan.total)} as planned',
            ),
            subtitle: Text(
              [
                for (final i in plan.items)
                  '${ledger.funds[i.fundId]?.name} ${formatTaka(i.amount)}',
              ].join(' · '),
            ),
            value: _setAside,
            onChanged: (v) => setState(() => _setAside = v),
          ),
        FilledButton(
          onPressed: amount <= 0
              ? null
              : () async {
                  final repo = ref.read(repositoryProvider);
                  if (_forNextMonth) {
                    await repo.incomeForNextMonth(
                      _date,
                      amount,
                      categoryId: widget.source.categoryId,
                      account: _account!,
                      setAsideOnRelease: offersSplit && _setAside,
                    );
                  } else {
                    final pot = (account: _account!, fund: ledger.spendingFund.id);
                    await repo.income(_date, amount, categoryId: widget.source.categoryId, to: pot);
                    if (offersSplit && _setAside) await repo.applyAllocation(plan, _date, pot);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(
                    context,
                    _forNextMonth
                        ? '$name held for ${next.label}'
                        : offersSplit && _setAside
                        ? '$name recorded and ${formatTaka(plan.total)} set aside'
                        : '$name recorded',
                  );
                },
          child: Text('Record ${formatTaka(amount)}'),
        ),
      ],
    );
  }
}
