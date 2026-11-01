import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database.dart';
import '../../data/ledger_repository.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

String loanKindLabel(LoanKind k) => switch (k) {
  LoanKind.ownSavings => 'Borrow from my savings',
  LoanKind.lent => 'Lend to someone',
  LoanKind.borrowed => 'Borrow from someone',
};

String loanTitle(Ledger ledger, LoanStatus s) {
  final loan = s.loan;
  return switch (loan.kind) {
    LoanKind.ownSavings => 'From ${ledger.funds[loan.fundId]?.name ?? 'savings'}',
    LoanKind.lent => 'Lent to ${ledger.accounts[loan.personAccountId]?.name ?? '?'}',
    LoanKind.borrowed => 'Borrowed from ${ledger.accounts[loan.personAccountId]?.name ?? '?'}',
  };
}

Future<void> showNewLoan(BuildContext context, {LoanKind? kind, int? sourceFund}) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewLoanSheet(kind: kind ?? LoanKind.ownSavings, sourceFund: sourceFund),
    );

class _NewLoanSheet extends ConsumerStatefulWidget {
  const _NewLoanSheet({required this.kind, this.sourceFund});

  final LoanKind kind;
  final int? sourceFund;

  @override
  ConsumerState<_NewLoanSheet> createState() => _NewLoanSheetState();
}

class _NewLoanSheetState extends ConsumerState<_NewLoanSheet> {
  late LoanKind _kind = widget.kind;
  bool _ready = false;
  bool _existing = false;
  int? _sourceFund;
  int? _person;
  final _newPerson = TextEditingController();
  late Pot _pot;
  final _amount = TextEditingController();
  final _charge = TextEditingController();
  final _repaid = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = ref.read(todayProvider);
  DateTime? _due;

  @override
  void dispose() {
    for (final c in [_newPerson, _amount, _charge, _repaid, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(Ledger ledger) {
    if (_ready) return;
    _ready = true;
    final savings = [...ledger.fundsOfKind(FundKind.savings), ...ledger.fundsOfKind(FundKind.goal)];
    _sourceFund = widget.sourceFund ?? savings.firstOrNull?.id;
    _pot = (account: defaultAccount(ledger, AccountType.bank).id, fund: ledger.spendingFund.id);
    _setDefaultCharge(ledger);
  }

  void _setDefaultCharge(Ledger ledger) {
    final bp = _kind == LoanKind.ownSavings ? ledger.borrowChargeBp : 0;
    _charge.text = formatPercentBp(bp).replaceAll('%', '');
  }

  int get _chargeBp => ((double.tryParse(_charge.text) ?? 0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    _init(ledger);
    final status = StatusColors.of(context);
    final today = ref.watch(todayProvider);
    final amount = parseTaka(_amount.text) ?? 0;
    final charge = LedgerRepository.chargeFor(amount, _chargeBp);
    final repaid = _existing ? parseTaka(_repaid.text) ?? 0 : 0;
    final people = ledger
        .accountsOfType((t) => t == AccountType.person)
        .where((a) => !a.archived)
        .toList();
    final sources = [...ledger.fundsOfKind(FundKind.savings), ...ledger.fundsOfKind(FundKind.goal)];
    final isPeople = _kind != LoanKind.ownSavings;
    final personOk = !isPeople || _person != null || _newPerson.text.trim().isNotEmpty;
    final canSave =
        amount > 0 && personOk && (isPeople || _sourceFund != null) && repaid <= amount + charge;

    Widget dateField(
      String label,
      DateTime? value,
      ValueChanged<DateTime> set, {
      bool optional = false,
    }) => PickerField(
      label: label,
      value: value == null ? 'None' : DateFormat.yMMMd().format(value),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? today,
          firstDate: DateTime(2000),
          lastDate: today.add(const Duration(days: 3650)),
        );
        if (picked != null) setState(() => set(picked));
      },
    );

    return SheetBody(
      title: 'New loan',
      children: [
        SegmentedButton<LoanKind>(
          segments: const [
            ButtonSegment(value: LoanKind.ownSavings, label: Text('My savings')),
            ButtonSegment(value: LoanKind.lent, label: Text('Lend')),
            ButtonSegment(value: LoanKind.borrowed, label: Text('Borrow')),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() {
            _kind = s.single;
            _setDefaultCharge(ledger);
          }),
        ),
        Text(loanKindLabel(_kind), style: TextStyle(color: status.muted)),
        if (!isPeople)
          DropdownButtonFormField<int>(
            initialValue: _sourceFund,
            decoration: const InputDecoration(
              labelText: 'Borrow from',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final f in sources)
                DropdownMenuItem(
                  value: f.id,
                  child: Text('${f.name} · ${formatTaka(ledger.fundBalance(f.id))}'),
                ),
            ],
            onChanged: (v) => setState(() => _sourceFund = v),
          )
        else ...[
          DropdownButtonFormField<int?>(
            initialValue: _person,
            decoration: const InputDecoration(labelText: 'Person', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Someone new…')),
              for (final p in people) DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: (v) => setState(() => _person = v),
          ),
          if (_person == null)
            TextField(
              controller: _newPerson,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
        ],
        AmountField(controller: _amount, label: 'Amount', onChanged: (_) => setState(() {})),
        TextField(
          controller: _charge,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(
            labelText: 'Charge',
            suffixText: '%',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Started before I used the app'),
          subtitle: const Text('Records what is still open without moving money now'),
          value: _existing,
          onChanged: (v) => setState(() => _existing = v),
        ),
        if (!_existing)
          PickerField(
            label: switch (_kind) {
              LoanKind.lent => 'Money goes out of',
              _ => 'Money goes into',
            },
            value: potLabel(ledger, _pot),
            onTap: () async {
              final picked = await pickPot(context, ledger, title: 'Account', initial: _pot);
              if (picked != null) setState(() => _pot = picked);
            },
          ),
        if (_existing)
          AmountField(
            controller: _repaid,
            label: 'Already paid back',
            onChanged: (_) => setState(() {}),
          ),
        Row(
          spacing: 8,
          children: [
            Expanded(child: dateField('Date', _date, (d) => _date = d)),
            if (isPeople) Expanded(child: dateField('Due (optional)', _due, (d) => _due = d)),
          ],
        ),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        if (amount > 0) ...[
          AmountRow('Charge ${formatPercentBp(_chargeBp)}', charge),
          AmountRow(
            _kind == LoanKind.lent ? 'They will owe you' : 'You will owe',
            amount + charge - repaid,
            total: true,
          ),
        ],
        FilledButton(
          onPressed: canSave ? () => _save(ledger) : null,
          child: const Text('Save loan'),
        ),
      ],
    );
  }

  Future<void> _save(Ledger ledger) async {
    final repo = ref.read(repositoryProvider);
    final amount = parseTaka(_amount.text)!;
    final note = _note.text.trim();
    var person = _person;
    if (_kind != LoanKind.ownSavings && person == null) {
      person = await ref
          .read(setupRepositoryProvider)
          .addAccount(_newPerson.text, AccountType.person);
    }

    if (_existing) {
      final fund = _kind == LoanKind.ownSavings ? _sourceFund! : _pot.fund;
      await repo.openExistingLoan(
        kind: _kind,
        person: person,
        fundId: fund,
        principal: amount,
        alreadyRepaid: parseTaka(_repaid.text) ?? 0,
        chargeRateBp: _chargeBp,
        date: _date,
        dueDate: _due,
        openingDate: _date,
        note: note,
      );
    } else {
      switch (_kind) {
        case LoanKind.ownSavings:
          await repo.borrowFromFund(
            _date,
            amount,
            sourceFund: _sourceFund!,
            intoFund: ledger.spendingFund.id,
            account: _pot.account,
            chargeRateBp: _chargeBp,
            note: note,
          );
        case LoanKind.lent:
          await repo.lendToPerson(
            _date,
            amount,
            person: person!,
            from: _pot,
            chargeRateBp: _chargeBp,
            dueDate: _due,
            note: note,
          );
        case LoanKind.borrowed:
          await repo.borrowFromPerson(
            _date,
            amount,
            person: person!,
            to: _pot,
            chargeRateBp: _chargeBp,
            dueDate: _due,
            note: note,
          );
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Loan saved');
  }
}

/// Pay back (or receive back) part or all of a loan.
Future<void> showRepay(BuildContext context, LoanStatus status) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _RepaySheet(status: status),
);

class _RepaySheet extends ConsumerStatefulWidget {
  const _RepaySheet({required this.status});

  final LoanStatus status;

  @override
  ConsumerState<_RepaySheet> createState() => _RepaySheetState();
}

class _RepaySheetState extends ConsumerState<_RepaySheet> {
  late final _amount = TextEditingController(text: amountText(widget.status.remaining));
  late DateTime _date = ref.read(todayProvider);
  int? _account;

  /// The category whose budget pays for it, when it comes from Spending.
  int? _budget;
  bool _budgetSet = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Budgets it can come out of, the most money left first.
  List<CategoryRow> _budgets(Ledger ledger, Period period) => [
    for (final c in ledger.leafCategories(CategoryKind.expense, month: period))
      if (ledger.movableFrom(c.id, period) > 0) c,
  ]..sort((a, b) => ledger.movableFrom(b.id, period).compareTo(ledger.movableFrom(a.id, period)));

  Widget _budgetPicker(Ledger ledger, Period period, Poisha amount) {
    final options = _budgets(ledger, period);
    if (!_budgetSet) {
      _budget = options.firstOrNull?.id;
      _budgetSet = true;
    }
    final name = ledger.categories[_budget]?.name;
    final room = _budget == null ? 0 : ledger.movableFrom(_budget!, period);
    final note = name == null
        ? 'Budgets stay as they are, so together they promise '
              '${formatTaka(amount)} more than you have.'
        : amount > room
        ? '$name has only ${formatTaka(room)} left: its budget goes '
              '${formatTaka(amount - room)} over.'
        : '$name\'s budget for ${period.label} goes down by ${formatTaka(amount)}, '
              'so Budget by category still adds up to what you have.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        PickerField(
          label: 'Take it from the budget of',
          value: name == null ? 'No budget' : '$name · ${formatTaka(room)} left',
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Take it from the budget of'),
                children: [
                  for (final c in options)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, c.id),
                      child: Text(
                        '${c.name} · ${formatTaka(ledger.movableFrom(c.id, period))} left',
                      ),
                    ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, -1),
                    child: const Text('No budget'),
                  ),
                ],
              ),
            );
            if (picked != null) setState(() => _budget = picked < 0 ? null : picked);
          },
        ),
        Text(note, style: TextStyle(color: StatusColors.of(context).muted, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final loan = widget.status.loan;
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();
    _account ??= defaultAccount(ledger, AccountType.bank).id;
    final amount = parseTaka(_amount.text) ?? 0;
    final today = ref.watch(todayProvider);
    final receiving = loan.kind == LoanKind.lent;
    // Paying back out of Spending uses up budget, like an expense.
    final fromSpending =
        loan.kind == LoanKind.ownSavings ||
        (loan.kind == LoanKind.borrowed && loan.fundId == ledger.spendingFund.id);
    final period = Period.of(_date);

    return SheetBody(
      title: receiving ? 'Money received back' : 'Pay back',
      children: [
        Text(loanTitle(ledger, widget.status)),
        AmountRow('Still open', widget.status.remaining),
        AmountField(controller: _amount, label: 'Amount', onChanged: (_) => setState(() {})),
        DropdownButtonFormField<int>(
          initialValue: _account,
          decoration: InputDecoration(
            labelText: receiving ? 'Received into' : 'Paid from',
            border: const OutlineInputBorder(),
          ),
          items: [for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
          onChanged: (v) => setState(() => _account = v),
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
        if (fromSpending && amount > 0) _budgetPicker(ledger, period, amount),
        FilledButton(
          onPressed: amount <= 0
              ? null
              : () async {
                  final repo = ref.read(repositoryProvider);
                  switch (loan.kind) {
                    case LoanKind.ownSavings:
                      await repo.repayOwnLoan(
                        loan.id,
                        _date,
                        amount,
                        from: (account: _account!, fund: ledger.spendingFund.id),
                        budgetCategoryId: _budget,
                      );
                    case LoanKind.lent:
                      await repo.collectFromPerson(loan.id, _date, amount, toAccount: _account!);
                    case LoanKind.borrowed:
                      await repo.repayPerson(
                        loan.id,
                        _date,
                        amount,
                        fromAccount: _account!,
                        budgetCategoryId: fromSpending ? _budget : null,
                      );
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(
                    context,
                    amount >= widget.status.remaining
                        ? 'Loan fully paid'
                        : '${formatTaka(amount)} recorded',
                  );
                },
          child: Text('Record ${formatTaka(amount)}'),
        ),
      ],
    );
  }
}
