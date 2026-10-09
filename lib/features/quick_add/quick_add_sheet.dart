import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/database.dart';
import '../../data/ledger_repository.dart';
import '../../ledger/allocation.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';

enum QuickAddMode { expense, income, move }

/// Opens quick add. Pass [editing] to change an existing income, expense
/// or move.
Future<void> showQuickAdd(BuildContext context, {Entry? editing}) => showModalBottomSheet(
  useRootNavigator: true,
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => QuickAddSheet(editing: editing),
);

bool canEditInQuickAdd(Entry e) =>
    e.type == EntryType.expense || e.type == EntryType.income || e.type == EntryType.move;

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.editing});

  final Entry? editing;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  static const _lastExpensePot = 'last_expense_pot';
  static const _lastIncomePot = 'last_income_pot';

  bool _ready = false;
  QuickAddMode _mode = QuickAddMode.expense;

  /// What has been typed on the number pad, e.g. "350" or "99.5".
  String _typed = '';
  int? _categoryId;
  late Pot _from;
  late Pot _to;
  late DateTime _date;
  final _note = TextEditingController();
  bool _saving = false;

  /// Add to the Buying register.
  bool _major = false;
  int? _trackerId;

  /// The purchase record of the entry being edited, kept so shop and
  /// warranty survive the edit.
  Purchase? _oldPurchase;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _init(Ledger ledger) {
    if (_ready) return;
    _ready = true;
    final spending = ledger.spendingFund.id;
    final cash = defaultAccount(ledger, AccountType.cash).id;
    final bank = defaultAccount(ledger, AccountType.bank).id;
    _date = ref.read(todayProvider);

    final e = widget.editing;
    if (e == null) {
      _from =
          potFromSetting(ledger, ledger.settings[_lastExpensePot]) ??
          (account: cash, fund: spending);
      _to =
          potFromSetting(ledger, ledger.settings[_lastIncomePot]) ??
          (account: bank, fund: spending);
      return;
    }

    _mode = switch (e.type) {
      EntryType.income => QuickAddMode.income,
      EntryType.move => QuickAddMode.move,
      _ => QuickAddMode.expense,
    };
    _typed = (e.amount % poishaPerTaka == 0)
        ? '${e.amount ~/ poishaPerTaka}'
        : (e.amount / poishaPerTaka).toStringAsFixed(2);
    _categoryId = e.categoryId;
    _date = e.date;
    _note.text = e.note;
    _trackerId = e.trackerId;
    _oldPurchase = ledger.purchaseFor(e.id);
    _major = _oldPurchase != null;
    final postings = ledger.postingsOf(e.id);
    Pot potOf(PostingLine p) => (account: p.accountId, fund: p.fundId);
    final out = postings.where((p) => p.amount < 0).firstOrNull;
    final into = postings.where((p) => p.amount > 0).firstOrNull;
    _from = out != null ? potOf(out) : (account: cash, fund: spending);
    _to = into != null ? potOf(into) : (account: bank, fund: spending);
  }

  Poisha get _amount => parseTaka(_typed) ?? 0;

  void _key(String key) {
    setState(() {
      if (key == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
        return;
      }
      if (key == '.') {
        if (!_typed.contains('.')) _typed = _typed.isEmpty ? '0.' : '$_typed.';
        return;
      }
      final next = _typed == '0' ? key : _typed + key;
      final parts = next.split('.');
      if (parts[0].length > 10) return;
      if (parts.length == 2 && parts[1].length > 2) return;
      _typed = next;
    });
  }

  /// The typed amount with lakh grouping, keeping a trailing "." visible.
  String get _display {
    if (_typed.isEmpty) return '0';
    final parts = _typed.split('.');
    final whole = groupLakh(int.tryParse(parts[0]) ?? 0);
    return parts.length == 1 ? whole : '$whole.${parts[1]}';
  }

  CategoryKind get _kind =>
      _mode == QuickAddMode.income ? CategoryKind.income : CategoryKind.expense;

  bool get _canSave =>
      !_saving && _amount > 0 && (_mode == QuickAddMode.move ? _from != _to : _categoryId != null);

  Future<void> _save(Ledger ledger) async {
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final amount = _amount;
    final note = _note.text.trim();

    Future<int> write() => switch (_mode) {
      QuickAddMode.expense => repo.expense(
        _date,
        amount,
        categoryId: _categoryId!,
        from: _from,
        note: note,
        trackerId: _trackerId,
      ),
      QuickAddMode.income => repo.income(
        _date,
        amount,
        categoryId: _categoryId!,
        to: _to,
        note: note,
      ),
      QuickAddMode.move => repo.move(_date, amount, from: _from, to: _to, note: note),
    };

    Future<int> writeWithPurchase() async {
      final id = await write();
      if (_mode == QuickAddMode.expense && _major) {
        await repo.addPurchase(
          item: note.isNotEmpty ? note : ledger.categories[_categoryId]!.name,
          date: _date,
          amount: amount,
          entryId: id,
          shop: _oldPurchase?.shop ?? '',
          warrantyUntil: _oldPurchase?.warrantyUntil,
          note: _oldPurchase?.note ?? '',
        );
      }
      return id;
    }

    final editing = widget.editing;
    if (editing != null) {
      await repo.replaceEntry(editing.id, writeWithPurchase);
    } else {
      await writeWithPurchase();
    }
    if (_mode == QuickAddMode.expense) await repo.setSetting(_lastExpensePot, potSetting(_from));
    if (_mode == QuickAddMode.income) await repo.setSetting(_lastIncomePot, potSetting(_to));

    navigator.pop();
    final what = switch (_mode) {
      QuickAddMode.move => 'Moved ${formatTaka(amount)}',
      _ =>
        '${editing == null ? 'Saved' : 'Updated'} ${formatTaka(amount)} · '
            '${ledger.categories[_categoryId]?.name}',
    };

    final plan = AllocationPlan.parse(ledger.settings[AllocationPlan.settingKey]);
    final offerPlan =
        editing == null &&
        _mode == QuickAddMode.income &&
        !plan.isEmpty &&
        plan.categoryId == _categoryId;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(what),
          duration: Duration(seconds: offerPlan ? 10 : 3),
          action: offerPlan
              ? SnackBarAction(
                  label: 'Set aside ${formatTaka(plan.total)}',
                  onPressed: () => repo.applyAllocation(plan, _date, _to),
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ledgerValue = ref.watch(ledgerProvider);
    final ledger = ledgerValue.value;
    if (ledger == null) return const SizedBox(height: 200);
    _init(ledger);

    final today = ref.watch(todayProvider);
    final status = StatusColors.of(context);
    final chips = ledger.frequentCategories(_kind, today).take(7).toList();
    final selected = ledger.categories[_categoryId];
    if (selected != null && selected.kind == _kind && !chips.any((c) => c.id == selected.id)) {
      chips.insert(0, selected);
    }

    Widget potField(String label, Pot pot, ValueChanged<Pot> onPicked) => PickerField(
      label: label,
      value: potLabel(ledger, pot),
      onTap: () async {
        final picked = await pickPot(
          context,
          ledger,
          title: label,
          initial: pot,
          includeInvestments: _mode == QuickAddMode.move,
        );
        if (picked != null) setState(() => onPicked(picked));
      },
    );

    final dateField = PickerField(
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
    );

    final saveLabel = switch (_mode) {
      QuickAddMode.move => 'Move ${formatTaka(_amount)}',
      _ when _categoryId == null => 'Choose a category',
      QuickAddMode.expense =>
        'Save ${formatTaka(_amount)} to ${ledger.categories[_categoryId]!.name}',
      QuickAddMode.income =>
        'Save ${formatTaka(_amount)} as ${ledger.categories[_categoryId]!.name}',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            SegmentedButton<QuickAddMode>(
              segments: const [
                ButtonSegment(value: QuickAddMode.expense, label: Text('Expense')),
                ButtonSegment(value: QuickAddMode.income, label: Text('Income')),
                ButtonSegment(value: QuickAddMode.move, label: Text('Move')),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: widget.editing != null
                  ? null
                  : (s) => setState(() {
                      _mode = s.single;
                      _categoryId = null;
                    }),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$takaSymbol ',
                    style: TextStyle(color: status.muted, fontSize: 22),
                  ),
                  TextSpan(text: _display),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (_mode != QuickAddMode.move)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in chips)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: c.id == _categoryId,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    ),
                  ActionChip(
                    label: const Text('All…'),
                    onPressed: () async {
                      final picked = await pickCategory(context, ledger, _kind);
                      if (picked != null) setState(() => _categoryId = picked.id);
                    },
                  ),
                ],
              ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: switch (_mode) {
                    QuickAddMode.expense => potField('Paid from', _from, (p) => _from = p),
                    QuickAddMode.income => potField('Received in', _to, (p) => _to = p),
                    QuickAddMode.move => potField('From', _from, (p) => _from = p),
                  },
                ),
                Expanded(child: dateField),
              ],
            ),
            if (_mode == QuickAddMode.move) potField('To', _to, (p) => _to = p),
            // One scrolling line, so the number pad stays on screen.
            if (_mode == QuickAddMode.expense)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Major purchase'),
                      selected: _major,
                      onSelected: (v) => setState(() => _major = v),
                    ),
                    for (final t in ledger.activeTrackers())
                      ChoiceChip(
                        avatar: Icon(
                          t.tracker.kind == TrackerKind.countdown
                              ? Icons.timer_outlined
                              : Icons.construction,
                          size: 16,
                        ),
                        label: Text(t.tracker.name),
                        selected: _trackerId == t.tracker.id,
                        onSelected: (v) => setState(() => _trackerId = v ? t.tracker.id : null),
                      ),
                  ],
                ),
              ),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            _Keypad(onKey: _key),
            FilledButton(
              onPressed: _canSave ? () => _save(ledger) : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(saveLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});

  final ValueChanged<String> onKey;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];

  @override
  Widget build(BuildContext context) {
    final sunk = StatusColors.of(context).sunk;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.6,
      children: [
        for (final k in _keys)
          Material(
            color: sunk,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onKey(k),
              onLongPress: k == '⌫' ? () => _clear() : null,
              child: Center(
                child: k == '⌫'
                    ? const Icon(Icons.backspace_outlined, semanticLabel: 'Delete digit')
                    : Text(k, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
      ],
    );
  }

  void _clear() {
    for (var i = 0; i < 14; i++) {
      onKey('⌫');
    }
  }
}
