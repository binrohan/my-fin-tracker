import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database.dart';
import '../../ledger/allocation.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// The monthly plan in three steps: what comes in (Income), what each taka
/// is for (Split), and how the expense part breaks down (Expenses).
class MonthlyPlanScreen extends ConsumerStatefulWidget {
  const MonthlyPlanScreen({super.key, this.initialTab = 0});

  /// 0 Income, 1 Split, 2 Expenses.
  final int initialTab;

  @override
  ConsumerState<MonthlyPlanScreen> createState() => _MonthlyPlanScreenState();
}

class _IncomeRow {
  _IncomeRow(this.categoryId, Poisha amount, this.day, this.accountId)
    : amount = TextEditingController(text: amountText(amount));

  int categoryId;
  int? day;
  int? accountId;
  final TextEditingController amount;
}

class _SplitRow {
  _SplitRow(this.fundId, this.accountId, Poisha amount)
    : amount = TextEditingController(text: amountText(amount));

  int fundId;
  int? accountId;
  final TextEditingController amount;
}

class _MonthlyPlanScreenState extends ConsumerState<MonthlyPlanScreen> {
  bool _loaded = false;
  late final Period _period = Period.of(ref.read(todayProvider));
  final _incomes = <_IncomeRow>[];
  final _splits = <_SplitRow>[];
  final _expenseTarget = TextEditingController();
  int? _trigger;

  /// Budget field per expense category (sections and subsections).
  final _budgets = <int, TextEditingController>{};
  Map<int, Poisha> _originalBudgets = {};

  @override
  void dispose() {
    for (final c in [
      _expenseTarget,
      ..._incomes.map((r) => r.amount),
      ..._splits.map((r) => r.amount),
      ..._budgets.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Ledger ledger) {
    if (_loaded) return;
    _loaded = true;
    final plan = ledger.plan;
    for (final i in plan.incomes) {
      if (ledger.categories[i.categoryId] != null) {
        _incomes.add(_IncomeRow(i.categoryId, i.amount, i.day, i.accountId));
      }
    }
    if (_incomes.isEmpty) {
      final salary = ledger
          .leafCategories(CategoryKind.income)
          .where((c) => c.name == 'Salary')
          .firstOrNull;
      if (salary != null) {
        _incomes.add(_IncomeRow(salary.id, 0, 1, defaultAccount(ledger, AccountType.bank).id));
      }
    }
    for (final i in plan.items) {
      if (ledger.funds[i.fundId] != null) _splits.add(_SplitRow(i.fundId, i.accountId, i.amount));
    }
    _trigger = plan.categoryId ?? _incomes.firstOrNull?.categoryId;
    _originalBudgets = _budgetValues(ledger);
    final total = ledger
        .categoryLines(_period, CategoryKind.expense)
        .fold<Poisha>(0, (t, l) => t + l.budget);
    _expenseTarget.text = amountText(plan.expenseTarget ?? total);
  }

  /// What each expense category's budget field starts with: its own
  /// budget, or for a section without one, the sum of its subsections.
  Map<int, Poisha> _budgetValues(Ledger ledger) {
    final values = <int, Poisha>{};
    void walk(CategoryLine l) {
      values[l.category.id] = l.budget;
      l.children.forEach(walk);
    }

    ledger.categoryLines(_period, CategoryKind.expense).forEach(walk);
    return values;
  }

  TextEditingController _budget(int categoryId) => _budgets.putIfAbsent(
    categoryId,
    () => TextEditingController(text: amountText(_originalBudgets[categoryId] ?? 0)),
  );

  Poisha _value(TextEditingController c) => parseTaka(c.text) ?? 0;

  Poisha get _plannedIncome => _incomes.fold(0, (t, r) => t + _value(r.amount));
  Poisha get _setAside => _splits.fold(0, (t, r) => t + _value(r.amount));
  Poisha get _unassigned => _plannedIncome - _value(_expenseTarget) - _setAside;

  Future<void> _save(Ledger ledger) async {
    final repo = ref.read(repositoryProvider);
    final plan = AllocationPlan(
      categoryId: _incomes.any((r) => r.categoryId == _trigger)
          ? _trigger
          : _incomes.firstOrNull?.categoryId,
      incomes: [
        for (final r in _incomes)
          IncomeSource(
            categoryId: r.categoryId,
            amount: _value(r.amount),
            day: r.day,
            accountId: r.accountId,
          ),
      ],
      expenseTarget: _value(_expenseTarget),
      items: [
        for (final r in _splits)
          if (_value(r.amount) > 0)
            AllocationItem(fundId: r.fundId, accountId: r.accountId, amount: _value(r.amount)),
      ],
    );
    await repo.setSetting(AllocationPlan.settingKey, plan.encode());
    for (final MapEntry(key: id, value: c) in _budgets.entries) {
      if (_value(c) != (_originalBudgets[id] ?? 0)) await repo.setBudget(_period, id, _value(c));
    }
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Monthly plan saved');
  }

  Future<String?> _askName(String title, {String? hint}) async {
    final name = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text),
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((v) => v == null || v.trim().isEmpty ? null : v.trim());
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _load(ledger);
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monthly plan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Income'),
              Tab(text: 'Split'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        body: TabBarView(children: [_incomeTab(ledger), _splitTab(ledger), _expensesTab(ledger)]),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: _Balance(unassigned: _unassigned, income: _plannedIncome),
                ),
                FilledButton(onPressed: () => _save(ledger), child: const Text('Save')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Income

  Widget _incomeTab(Ledger ledger) {
    final status = StatusColors.of(context);
    final types = ledger.leafCategories(CategoryKind.income);
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'What comes in each month. From the day you set, Home asks whether it has arrived '
          'and where: one tap records it.',
          style: TextStyle(color: status.muted),
        ),
        const SizedBox(height: 12),
        for (final (i, r) in _incomes.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: r.categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Income',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in types) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => r.categoryId = v!),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _incomes.removeAt(i).amount.dispose()),
                    ),
                  ],
                ),
                AmountField(
                  controller: r.amount,
                  label: 'Amount a month',
                  onChanged: (_) => setState(() {}),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: r.day?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          hintText: '1–31',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final d = int.tryParse(v);
                          r.day = d == null || d < 1 || d > 31 ? null : d;
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: accounts.any((a) => a.id == r.accountId) ? r.accountId : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Usually arrives in',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final a in accounts)
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                        ],
                        onChanged: (v) => setState(() => r.accountId = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add income source'),
              onPressed: types.isEmpty
                  ? null
                  : () => setState(() {
                      final used = _incomes.map((r) => r.categoryId).toSet();
                      final next = types.firstWhere(
                        (c) => !used.contains(c.id),
                        orElse: () => types.first,
                      );
                      _incomes.add(
                        _IncomeRow(next.id, 0, null, defaultAccount(ledger, AccountType.bank).id),
                      );
                    }),
            ),
            TextButton.icon(
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('New income type'),
              onPressed: () async {
                final name = await _askName(
                  'New income type',
                  hint: 'e.g. Freelance, Rent received',
                );
                if (name == null) return;
                final id = await ref
                    .read(setupRepositoryProvider)
                    .addCategory(name, CategoryKind.income);
                if (!mounted) return;
                setState(
                  () => _incomes.add(
                    _IncomeRow(id, 0, null, defaultAccount(ledger, AccountType.bank).id),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(),
        AmountRow('Planned income a month', _plannedIncome, total: true),
      ],
    );
  }

  // -------------------------------------------------------------- Split

  Widget _splitTab(Ledger ledger) {
    final status = StatusColors.of(context);
    final targets = ledger.funds.values
        .where((f) => !f.archived && f.kind != FundKind.spending)
        .toList();
    final investAccounts = ledger
        .accountsOfType((t) => t == AccountType.investment)
        .where((a) => !a.archived)
        .toList();
    final incomeTypes = [
      for (final r in _incomes)
        if (ledger.categories[r.categoryId] != null) ledger.categories[r.categoryId]!,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Give every taka of your income a job: monthly expenses, savings, goals.',
          style: TextStyle(color: status.muted),
        ),
        const SizedBox(height: 12),
        AmountRow('Planned income', _plannedIncome, total: true),
        const SizedBox(height: 12),
        SectionCard(
          children: [
            const Label('Monthly expenses'),
            AmountField(
              controller: _expenseTarget,
              label: 'For spending each month',
              onChanged: (_) => setState(() {}),
            ),
            Text(
              'Break it into sections in the Expenses tab.',
              style: TextStyle(color: status.muted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          children: [
            const Label('Set aside'),
            for (final (i, r) in _splits.indexed) ...[
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: r.fundId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final f in targets) DropdownMenuItem(value: f.id, child: Text(f.name)),
                      ],
                      onChanged: (v) => setState(() {
                        r.fundId = v!;
                        r.accountId = ledger.funds[v]!.kind == FundKind.investment
                            ? investAccounts.firstOrNull?.id
                            : null;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: AmountField(controller: r.amount, onChanged: (_) => setState(() {})),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _splits.removeAt(i).amount.dispose()),
                  ),
                ],
              ),
              if (ledger.funds[r.fundId]?.kind == FundKind.investment && investAccounts.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: r.accountId ?? investAccounts.first.id,
                  decoration: const InputDecoration(
                    labelText: 'Into',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final a in investAccounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => r.accountId = v),
                ),
            ],
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add a line'),
                  onPressed: targets.isEmpty
                      ? null
                      : () => setState(() => _splits.add(_SplitRow(targets.first.id, null, 0))),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('New goal'),
                  onPressed: () async {
                    final name = await _askName('New goal', hint: 'e.g. New Laptop');
                    if (name == null) return;
                    final id = await ref.read(setupRepositoryProvider).addFund(name, FundKind.goal);
                    if (!mounted) return;
                    setState(() => _splits.add(_SplitRow(id, null, 0)));
                    showSnack(context, 'Goal added. Set its target in Accounts & pots.');
                  },
                ),
              ],
            ),
            AmountRow('Set aside in total', _setAside, total: true),
          ],
        ),
        const SizedBox(height: 12),
        if (incomeTypes.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: incomeTypes.any((c) => c.id == _trigger)
                ? _trigger
                : incomeTypes.first.id,
            decoration: const InputDecoration(
              labelText: 'Set aside when this income arrives',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in {for (final c in incomeTypes) c.id: c}.values)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _trigger = v),
          ),
      ],
    );
  }

  // ----------------------------------------------------------- Expenses

  Widget _expensesTab(Ledger ledger) {
    final status = StatusColors.of(context);
    final sections = [
      for (final c in ledger.categories.values)
        if (c.kind == CategoryKind.expense && c.parentId == null && !c.archived) c,
    ];
    List<CategoryRow> subsOf(int id) => [
      for (final c in ledger.categories.values)
        if (c.parentId == id && !c.archived) c,
    ];
    final sectionsTotal = sections.fold<Poisha>(0, (t, c) => t + _value(_budget(c.id)));
    final target = _value(_expenseTarget);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        SectionCard(
          children: [
            Row(
              children: [
                const Expanded(child: Label('Monthly expenses')),
                _AddsUp(parts: sectionsTotal, whole: target),
              ],
            ),
            Money(target, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(
              'Sections ${formatTaka(sectionsTotal)}. Applies from ${_period.label} on.',
              style: TextStyle(color: status.muted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final section in sections) ...[
          _sectionCard(ledger, section, subsOf(section.id)),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add section'),
            onPressed: () async {
              final name = await _askName('New section', hint: 'e.g. Transport');
              if (name == null) return;
              await ref.read(setupRepositoryProvider).addCategory(name, CategoryKind.expense);
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(Ledger ledger, CategoryRow section, List<CategoryRow> subs) {
    final subsTotal = subs.fold<Poisha>(0, (t, c) => t + _value(_budget(c.id)));
    final sectionField = _budget(section.id);
    return SectionCard(
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _NameWithLink(
                name: section.name,
                link: ledger.funds[section.savingsFundId]?.name,
                bold: true,
              ),
            ),
            SizedBox(
              width: 140,
              child: AmountField(controller: sectionField, onChanged: (_) => setState(() {})),
            ),
          ],
        ),
        for (final sub in subs)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: _NameWithLink(name: sub.name, link: ledger.funds[sub.savingsFundId]?.name),
                ),
                SizedBox(
                  width: 124,
                  child: AmountField(
                    controller: _budget(sub.id),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        // Wraps on narrow screens rather than overflowing.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
              label: const Text('Subsection'),
              onPressed: () async {
                final name = await _askName('New subsection of ${section.name}');
                if (name == null) return;
                await ref
                    .read(setupRepositoryProvider)
                    .addCategory(
                      name,
                      CategoryKind.expense,
                      parentId: section.id,
                      isFixed: section.isFixed,
                    );
              },
            ),
            if (subs.isNotEmpty) _AddsUp(parts: subsTotal, whole: _value(sectionField)),
          ],
        ),
      ],
    );
  }
}

/// "Adds up", or how much is left to assign / over.
class _AddsUp extends StatelessWidget {
  const _AddsUp({required this.parts, required this.whole});

  final Poisha parts;
  final Poisha whole;

  @override
  Widget build(BuildContext context) {
    final diff = whole - parts;
    if (diff == 0) return const StatusChip('Adds up', tone: ChipTone.good, icon: Icons.check);
    return diff > 0
        ? StatusChip('${formatTaka(diff)} left to assign', tone: ChipTone.warn)
        : StatusChip('Over by ${formatTaka(-diff)}', tone: ChipTone.bad);
  }
}

/// The bottom line: does the whole income have a job?
class _Balance extends StatelessWidget {
  const _Balance({required this.unassigned, required this.income});

  final Poisha unassigned;
  final Poisha income;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    if (income == 0) return Text('Add your income first', style: TextStyle(color: status.muted));
    final (text, color) = unassigned == 0
        ? ('Every taka has a job', status.good)
        : unassigned > 0
        ? ('${formatTaka(unassigned)} not planned', status.warn)
        : ('Planned ${formatTaka(-unassigned)} more than income', status.bad);
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}

/// A category name, with "Unused → New Laptop" under it when linked.
class _NameWithLink extends StatelessWidget {
  const _NameWithLink({required this.name, this.link, this.bold = false});

  final String name;
  final String? link;
  final bool bold;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: bold ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16) : null),
      if (link != null)
        Text(
          'Unused → $link',
          style: TextStyle(color: StatusColors.of(context).muted, fontSize: 12),
        ),
    ],
  );
}
