import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// Save part of a category's budget to a pot now, during the month (e.g.
/// Rice Bag's ৳1,000 into the Rice Bag pot). Starts with [categoryId] and
/// its linked pot when given.
Future<void> showSaveBudgetSheet(BuildContext context, Period period, {int? categoryId}) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SaveBudgetSheet(period: period, categoryId: categoryId),
    );

/// Pots budget can be saved to: savings pots and goals not yet reached.
List<Fund> savingPots(Ledger ledger) => [
  ...ledger.fundsOfKind(FundKind.savings),
  ...ledger.fundsOfKind(FundKind.goal).where((f) => f.achievedAt == null),
];

class _SaveBudgetSheet extends ConsumerStatefulWidget {
  const _SaveBudgetSheet({required this.period, this.categoryId});

  final Period period;
  final int? categoryId;

  @override
  ConsumerState<_SaveBudgetSheet> createState() => _SaveBudgetSheetState();
}

class _SaveBudgetSheetState extends ConsumerState<_SaveBudgetSheet> {
  final _amount = TextEditingController();
  bool _ready = false;
  int? _category;
  int? _fund;
  int? _account;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Leaf expense categories (not slots), linked ones with money left first.
  List<CategoryRow> _categories(Ledger ledger) {
    final list = [
      for (final c in ledger.leafCategories(CategoryKind.expense))
        if (!ledger.isSlot(c)) c,
    ];
    int rank(CategoryRow c) =>
        c.savingsFundId != null && ledger.movableFrom(c.id, widget.period) > 0 ? 0 : 1;
    return list..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  void _pickCategory(Ledger ledger, int id) {
    _category = id;
    final linked = ledger.categories[id]?.savingsFundId;
    if (linked != null && savingPots(ledger).any((f) => f.id == linked)) _fund = linked;
    _amount.text = amountText(ledger.movableFrom(id, widget.period));
  }

  void _init(Ledger ledger) {
    if (_ready) return;
    _ready = true;
    final cats = _categories(ledger);
    final start = widget.categoryId ?? cats.firstOrNull?.id;
    _fund = savingPots(ledger).firstOrNull?.id;
    if (start != null) _pickCategory(ledger, start);
    _account = ledger.spendingCells(widget.period).firstOrNull?.account;
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    _init(ledger);
    final status = StatusColors.of(context);
    final pots = savingPots(ledger);
    final category = ledger.categories[_category];
    final unspent = _category == null ? 0 : ledger.movableFrom(_category!, widget.period);
    final cells = ledger.spendingCells(widget.period);
    final inAccount = cells.where((c) => c.account == _account).firstOrNull?.amount ?? 0;
    final amount = parseTaka(_amount.text) ?? 0;
    final limit = math.min(unspent, inAccount);
    final fund = ledger.funds[_fund];
    final ok =
        category != null && fund != null && _account != null && amount > 0 && amount <= limit;

    if (pots.isEmpty) {
      return SheetBody(
        title: 'Save to a pot',
        children: [
          Text(
            'Add a savings pot or a goal first, in More → Accounts & pots.',
            style: TextStyle(color: status.muted),
          ),
        ],
      );
    }

    return SheetBody(
      title: 'Save to a pot · ${widget.period.label}',
      children: [
        Text(
          'Lowers this month\'s budget and moves the money from Spending into the pot. '
          'Your Monthly plan does not change.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        PickerField(
          label: 'From the budget of',
          value: category?.name ?? 'Choose',
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('From the budget of'),
                children: [
                  for (final c in _categories(ledger))
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, c.id),
                      child: Text(
                        '${c.name} · ${formatTaka(ledger.movableFrom(c.id, widget.period))} left'
                        '${c.savingsFundId != null ? ' → ${ledger.funds[c.savingsFundId]?.name}' : ''}',
                      ),
                    ),
                ],
              ),
            );
            if (picked != null) setState(() => _pickCategory(ledger, picked));
          },
        ),
        const Label('To'),
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
        AmountField(controller: _amount, label: 'Amount', onChanged: (_) => setState(() {})),
        Text(
          unspent == 0
              ? '${category?.name ?? 'This category'} has nothing left to save this month.'
              : amount > limit
              ? 'At most ${formatTaka(limit)}'
                    '${inAccount < unspent ? ' (Spending money in this account)' : ' (still unspent)'}.'
              : '${formatTaka(unspent)} of its budget is still unspent.',
          style: TextStyle(color: amount > limit ? status.bad : status.muted, fontSize: 13),
        ),
        if (cells.length > 1)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cells)
                ChoiceChip(
                  label: Text('${ledger.accounts[c.account]?.name} · ${formatTaka(c.amount)}'),
                  selected: _account == c.account,
                  onSelected: (_) => setState(() => _account = c.account),
                ),
            ],
          ),
        FilledButton(
          onPressed: !ok
              ? null
              : () async {
                  final today = ref.read(todayProvider);
                  final date = widget.period.contains(today)
                      ? today
                      : widget.period.end.subtract(const Duration(days: 1));
                  await ref
                      .read(repositoryProvider)
                      .saveBudgetToPot(
                        categoryId: category.id,
                        categoryName: category.name,
                        account: _account!,
                        spendingFund: ledger.spendingFund.id,
                        fundId: fund.id,
                        amount: amount,
                        date: date,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(context, '${formatTaka(amount)} saved to ${fund.name}');
                },
          child: Text(fund == null ? 'Save' : 'Save ${formatTaka(amount)} to ${fund.name}'),
        ),
      ],
    );
  }
}

/// Budget saved to pots this month, with undo.
class SavedThisMonth extends ConsumerWidget {
  const SavedThisMonth({super.key, required this.ledger, required this.period});

  final Ledger ledger;
  final Period period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = StatusColors.of(context);
    final saves = ledger.entries.where(
      (e) => e.type == EntryType.move && e.budgetSave == true && period.contains(e.date),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in saves)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ledger.categories[e.categoryId]?.name} → '
                  '${ledger.funds[ledger.postingsOf(e.id).where((p) => p.amount > 0).firstOrNull?.fundId]?.name}'
                  ' · ${formatTaka(e.amount)}',
                  style: TextStyle(color: status.muted, fontSize: 13),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () async {
                  if (!await confirm(
                    context,
                    title: 'Undo this save?',
                    body:
                        'The money goes back to Spending and the budget back to '
                        '${ledger.categories[e.categoryId]?.name}.',
                    action: 'Undo',
                  )) {
                    return;
                  }
                  await ref.read(repositoryProvider).deleteEntry(e.id);
                },
                child: const Text('Undo'),
              ),
            ],
          ),
      ],
    );
  }
}
