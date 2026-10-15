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

/// Slots of the month: money for a coming expense, moved in from other
/// categories' budgets, for this month only.
class SlotsCard extends StatelessWidget {
  const SlotsCard({super.key, required this.ledger, required this.period});

  final Ledger ledger;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final slots = ledger.slotsIn(period);
    final moves = ledger
        .movesIn(period)
        .where(
          (m) =>
              !ledger.isSlot(ledger.categories[m.toCategoryId]!) &&
              !ledger.isSlot(ledger.categories[m.fromCategoryId]!),
        );
    return SectionCard(
      children: [
        const Label('Slots & budget moves'),
        if (slots.isEmpty && moves.isEmpty)
          Text(
            'Set money aside for something coming this month, taken from other categories. '
            'Only this month changes; your Monthly plan stays as it is.',
            style: TextStyle(color: status.muted, fontSize: 13),
          ),
        for (final s in slots) _SlotTile(ledger: ledger, period: period, slot: s),
        for (final m in moves)
          Text(
            '${DateFormat.MMMd().format(m.date)}: ${formatTaka(m.amount)} '
            '${ledger.categories[m.fromCategoryId]!.name} → ${ledger.categories[m.toCategoryId]!.name}',
            style: TextStyle(color: status.muted, fontSize: 13),
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New slot'),
              onPressed: () => showSlotSheet(context, period),
            ),
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Move budget'),
              onPressed: () => showMoveBudgetSheet(context, period),
            ),
          ],
        ),
      ],
    );
  }
}

class _SlotTile extends ConsumerWidget {
  const _SlotTile({required this.ledger, required this.period, required this.slot});

  final Ledger ledger;
  final Period period;
  final SlotStatus slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = StatusColors.of(context);
    final over = slot.left < 0;
    final day = slot.category.dueDay;
    Future<void> changeDay() async {
      final picked = await _pickSpendDay(context, period, ref.read(todayProvider), day);
      if (picked != null) {
        await ref.read(repositoryProvider).setSlotDay(slot.category.id, picked.day);
      }
    }

    final from = [
      for (final MapEntry(:key, :value) in slot.sources.entries)
        '${ledger.categories[key]?.name} ${formatTaka(value)}',
    ].join(' + ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: status.sunk, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  slot.category.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Money(slot.budget, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Bar(slot.budget == 0 ? 0 : slot.spent / slot.budget, color: over ? status.bad : null),
          Text(
            over
                ? 'Spent ${formatTaka(slot.spent)} · ${formatTaka(-slot.left)} over'
                : 'Spent ${formatTaka(slot.spent)} · left ${formatTaka(slot.left)}',
            style: TextStyle(color: over ? status.bad : null),
          ),
          if (from.isNotEmpty)
            Text('From $from', style: TextStyle(color: status.muted, fontSize: 13)),
          if (day != null)
            Row(
              spacing: 6,
              children: [
                Icon(Icons.event_outlined, size: 16, color: status.muted),
                Expanded(
                  child: Text(
                    'Likely to spend on '
                    '${DateFormat.MMMEd().format(DateTime(period.year, period.month, day.clamp(1, period.daysInMonth)))}',
                    style: TextStyle(color: status.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => showSlotSheet(context, period, slot: slot),
                child: const Text('Add more'),
              ),
              if (slot.left > 0)
                OutlinedButton(
                  onPressed: () => showGiveBackSheet(context, period, slot),
                  child: const Text('Give back'),
                ),
              TextButton.icon(
                onPressed: changeDay,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(day == null ? 'Set date' : 'Change date'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Categories budget can come from or go back to: this month's leaf
/// expense categories, not slots.
List<CategoryRow> _budgetCategories(Ledger ledger, Period period) => [
  for (final c in ledger.leafCategories(CategoryKind.expense))
    if (!ledger.isSlot(c)) c,
];

class _AmountRow {
  _AmountRow(this.category, [Poisha amount = 0])
    : amount = TextEditingController(text: amountText(amount));

  int category;
  final TextEditingController amount;
}

/// One "category + amount" line with what the category has available.
Widget _categoryAmountRow(
  BuildContext context,
  Ledger ledger,
  Period period,
  _AmountRow r, {
  required List<CategoryRow> categories,
  required VoidCallback onChanged,
  required VoidCallback onRemove,
  bool showAvailable = true,
}) {
  final status = StatusColors.of(context);
  final available = ledger.movableFrom(r.category, period);
  final asked = parseTaka(r.amount.text) ?? 0;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 4,
    children: [
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: r.category,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.parentId == null
                          ? c.name
                          : '${ledger.categories[c.parentId]?.name} › ${c.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                r.category = v!;
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 116,
            child: AmountField(controller: r.amount, onChanged: (_) => onChanged()),
          ),
          IconButton(tooltip: 'Remove', icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
      if (showAvailable)
        Text(
          asked > available
              ? 'Only ${formatTaka(available)} left in this budget'
              : '${formatTaka(available)} available',
          style: TextStyle(color: asked > available ? status.bad : status.muted, fontSize: 12),
        ),
    ],
  );
}

/// Asks for the day in [period] the money is likely to be spent.
Future<DateTime?> _pickSpendDay(BuildContext context, Period period, DateTime today, int? day) {
  final last = period.end.subtract(const Duration(days: 1));
  final initial = day != null
      ? DateTime(period.year, period.month, day.clamp(1, period.daysInMonth))
      : (period.contains(today) ? today : period.start);
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: period.start,
    lastDate: last,
    helpText: 'Likely to spend on',
  );
}

/// New slot, or [slot] "Add more": move budget in from categories.
Future<void> showSlotSheet(BuildContext context, Period period, {SlotStatus? slot}) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SlotSheet(period: period, slot: slot),
    );

class _SlotSheet extends ConsumerStatefulWidget {
  const _SlotSheet({required this.period, this.slot});

  final Period period;
  final SlotStatus? slot;

  @override
  ConsumerState<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends ConsumerState<_SlotSheet> {
  final _name = TextEditingController();
  final _rows = <_AmountRow>[];

  /// Day of the month it's likely to be spent; shows on Home near then.
  int? _spendDay;

  @override
  void dispose() {
    _name.dispose();
    for (final r in _rows) {
      r.amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final cats = _budgetCategories(ledger, widget.period);
    if (_rows.isEmpty && cats.isNotEmpty) _rows.add(_AmountRow(cats.first.id));
    final total = _rows.fold<Poisha>(0, (t, r) => t + (parseTaka(r.amount.text) ?? 0));
    final tooMuch = _rows.any(
      (r) => (parseTaka(r.amount.text) ?? 0) > ledger.movableFrom(r.category, widget.period),
    );
    final isNew = widget.slot == null;
    final ok = total > 0 && !tooMuch && (!isNew || _name.text.trim().isNotEmpty);

    return SheetBody(
      title: isNew ? 'New slot · ${widget.period.label}' : 'Add to ${widget.slot!.category.name}',
      children: [
        if (isNew) ...[
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What is it for?',
              hintText: 'e.g. Medical Test',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text(
            'For ${widget.period.label} only. Your Monthly plan does not change.',
            style: TextStyle(color: StatusColors.of(context).muted, fontSize: 13),
          ),
          PickerField(
            label: 'Likely to spend on (optional)',
            value: _spendDay == null
                ? 'No date'
                : DateFormat.MMMEd().format(
                    DateTime(widget.period.year, widget.period.month, _spendDay!),
                  ),
            onTap: () async {
              final picked = await _pickSpendDay(
                context,
                widget.period,
                ref.read(todayProvider),
                _spendDay,
              );
              if (picked != null) setState(() => _spendDay = picked.day);
            },
          ),
          if (_spendDay != null)
            Text(
              'It shows on Home under Needs attention from 3 days before.',
              style: TextStyle(color: StatusColors.of(context).muted, fontSize: 13),
            ),
        ],
        const Label('Take from'),
        for (final (i, r) in _rows.indexed)
          _categoryAmountRow(
            context,
            ledger,
            widget.period,
            r,
            categories: cats,
            onChanged: () => setState(() {}),
            onRemove: () => setState(() => _rows.removeAt(i).amount.dispose()),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Another category'),
            onPressed: () => setState(() {
              final used = _rows.map((r) => r.category).toSet();
              _rows.add(
                _AmountRow(
                  cats.firstWhere((c) => !used.contains(c.id), orElse: () => cats.first).id,
                ),
              );
            }),
          ),
        ),
        AmountRow(isNew ? 'Slot amount' : 'Adding', total, total: true),
        FilledButton(
          onPressed: !ok
              ? null
              : () async {
                  final repo = ref.read(repositoryProvider);
                  final from = [
                    for (final r in _rows)
                      (category: r.category, amount: parseTaka(r.amount.text) ?? 0),
                  ];
                  final today = ref.read(todayProvider);
                  if (isNew) {
                    await repo.createSlot(
                      widget.period,
                      name: _name.text,
                      from: from,
                      date: today,
                      spendDay: _spendDay,
                    );
                  } else {
                    await repo.fundSlot(
                      widget.period,
                      slot: widget.slot!.category.id,
                      from: from,
                      date: today,
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(
                    context,
                    isNew ? 'Slot ${_name.text.trim()} created' : '${formatTaka(total)} added',
                  );
                },
          child: Text(isNew ? 'Create slot' : 'Add ${formatTaka(total)}'),
        ),
      ],
    );
  }
}

/// Give a slot's unused money back to categories; suggests the same
/// proportions it came in.
Future<void> showGiveBackSheet(BuildContext context, Period period, SlotStatus slot) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GiveBackSheet(period: period, slot: slot),
    );

class _GiveBackSheet extends ConsumerStatefulWidget {
  const _GiveBackSheet({required this.period, required this.slot});

  final Period period;
  final SlotStatus slot;

  @override
  ConsumerState<_GiveBackSheet> createState() => _GiveBackSheetState();
}

class _GiveBackSheetState extends ConsumerState<_GiveBackSheet> {
  final _rows = <_AmountRow>[];
  bool _ready = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final slot = ledger
        .slotsIn(widget.period)
        .firstWhere((s) => s.category.id == widget.slot.category.id, orElse: () => widget.slot);
    final cats = _budgetCategories(ledger, widget.period);
    if (!_ready) {
      _ready = true;
      for (final s in ledger.giveBackShares(slot, slot.left)) {
        _rows.add(_AmountRow(s.category, s.amount));
      }
      if (_rows.isEmpty && cats.isNotEmpty) _rows.add(_AmountRow(cats.first.id, slot.left));
    }
    final total = _rows.fold<Poisha>(0, (t, r) => t + (parseTaka(r.amount.text) ?? 0));
    final status = StatusColors.of(context);

    return SheetBody(
      title: 'Give back from ${slot.category.name}',
      children: [
        AmountRow('Left in the slot', slot.left),
        const Label('Give back to'),
        for (final (i, r) in _rows.indexed)
          _categoryAmountRow(
            context,
            ledger,
            widget.period,
            r,
            categories: cats,
            showAvailable: false,
            onChanged: () => setState(() {}),
            onRemove: () => setState(() => _rows.removeAt(i).amount.dispose()),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Another category'),
            onPressed: () => setState(() => _rows.add(_AmountRow(cats.first.id))),
          ),
        ),
        AmountRow('Giving back', total, total: true),
        if (total > slot.left)
          Text(
            'That is ${formatTaka(total - slot.left)} more than is left.',
            style: TextStyle(color: status.bad),
          ),
        FilledButton(
          onPressed: total <= 0 || total > slot.left
              ? null
              : () async {
                  await ref
                      .read(repositoryProvider)
                      .giveBack(
                        widget.period,
                        slot: slot.category.id,
                        to: [
                          for (final r in _rows)
                            (category: r.category, amount: parseTaka(r.amount.text) ?? 0),
                        ],
                        date: ref.read(todayProvider),
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(context, '${formatTaka(total)} given back');
                },
          child: Text('Give back ${formatTaka(total)}'),
        ),
      ],
    );
  }
}

/// Move budget between two categories for this month only (e.g. to cover
/// an overspent Ration from Random).
Future<void> showMoveBudgetSheet(BuildContext context, Period period) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MoveBudgetSheet(period: period),
);

class _MoveBudgetSheet extends ConsumerStatefulWidget {
  const _MoveBudgetSheet({required this.period});

  final Period period;

  @override
  ConsumerState<_MoveBudgetSheet> createState() => _MoveBudgetSheetState();
}

class _MoveBudgetSheetState extends ConsumerState<_MoveBudgetSheet> {
  int? _from;
  int? _to;
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final cats = _budgetCategories(ledger, widget.period);
    final slots = [for (final s in ledger.slotsIn(widget.period)) s.category];
    _from ??= cats.firstOrNull?.id;
    _to ??= cats.length > 1 ? cats[1].id : cats.firstOrNull?.id;
    final status = StatusColors.of(context);
    final amount = parseTaka(_amount.text) ?? 0;
    final available = _from == null ? 0 : ledger.movableFrom(_from!, widget.period);
    String label(CategoryRow c) =>
        c.parentId == null ? c.name : '${ledger.categories[c.parentId]?.name} › ${c.name}';

    return SheetBody(
      title: 'Move budget · ${widget.period.label}',
      children: [
        Text(
          'For ${widget.period.label} only. The month total stays the same and your Monthly plan '
          'does not change.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        DropdownButtonFormField<int>(
          initialValue: _from,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
          items: [
            for (final c in [...cats, ...slots])
              DropdownMenuItem(value: c.id, child: Text(label(c))),
          ],
          onChanged: (v) => setState(() => _from = v),
        ),
        Text(
          '${formatTaka(available)} available',
          style: TextStyle(color: status.muted, fontSize: 12),
        ),
        DropdownButtonFormField<int>(
          initialValue: _to,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
          items: [
            for (final c in [...cats, ...slots])
              DropdownMenuItem(value: c.id, child: Text(label(c))),
          ],
          onChanged: (v) => setState(() => _to = v),
        ),
        AmountField(controller: _amount, label: 'Amount', onChanged: (_) => setState(() {})),
        if (amount > available)
          Text(
            'Only ${formatTaka(available)} left in that budget',
            style: TextStyle(color: status.bad),
          ),
        FilledButton(
          onPressed: amount <= 0 || amount > available || _from == _to
              ? null
              : () async {
                  await ref
                      .read(repositoryProvider)
                      .moveBudget(
                        widget.period,
                        from: _from!,
                        to: _to!,
                        amount: amount,
                        date: ref.read(todayProvider),
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(context, '${formatTaka(amount)} moved');
                },
          child: Text('Move ${formatTaka(amount)}'),
        ),
      ],
    );
  }
}
