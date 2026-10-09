import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/ledger_repository.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import 'accounts_screen.dart';

typedef SavedPart = ({int fund, int account, Poisha amount});

/// Turns "City Bank 20,000 of which 5,000 is Monthly Savings" into pots:
/// each saved part in its fund, the rest of every account in Spending.
/// Returns null and the account names in [overdrawn] when the saved parts
/// of an account add up to more than its total.
List<(Pot, Poisha)>? splitStartingBalances({
  required Map<int, Poisha> totals,
  required List<SavedPart> saved,
  required int spendingFund,
  List<int>? overdrawn,
}) {
  final result = <(Pot, Poisha)>[];
  for (final MapEntry(key: account, value: total) in totals.entries) {
    final parts = saved.where((s) => s.account == account && s.amount > 0);
    final savedTotal = parts.fold<Poisha>(0, (t, s) => t + s.amount);
    if (savedTotal > total) {
      overdrawn?.add(account);
      continue;
    }
    for (final s in parts) {
      result.add(((account: account, fund: s.fund), s.amount));
    }
    if (total - savedTotal != 0) {
      result.add(((account: account, fund: spendingFund), total - savedTotal));
    }
  }
  if (overdrawn != null && overdrawn.isNotEmpty) return null;
  // Saved parts kept in an account with no total entered.
  for (final s in saved.where((s) => s.amount > 0 && !totals.containsKey(s.account))) {
    overdrawn?.add(s.account);
  }
  return overdrawn != null && overdrawn.isNotEmpty ? null : result;
}

class _SavedRow {
  _SavedRow(this.fund, this.account);

  int fund;
  int account;
  final amount = TextEditingController();
}

/// What you have on the day you start: each bank account, wallet and the
/// cash drawer, and how much of it is already savings.
class StartingBalancesScreen extends ConsumerStatefulWidget {
  const StartingBalancesScreen({super.key});

  @override
  ConsumerState<StartingBalancesScreen> createState() => _StartingBalancesScreenState();
}

class _StartingBalancesScreenState extends ConsumerState<StartingBalancesScreen> {
  final _totals = <int, TextEditingController>{};
  final _investments = <int, TextEditingController>{};
  final _saved = <_SavedRow>[];
  late DateTime _start = _defaultStart(ref.read(todayProvider));

  /// The 1st of this month if today is early in the month, otherwise today.
  static DateTime _defaultStart(DateTime today) =>
      today.day <= 3 ? DateTime(today.year, today.month) : today;

  @override
  void dispose() {
    for (final c in [..._totals.values, ..._investments.values, ..._saved.map((s) => s.amount)]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _total(int id) => _totals.putIfAbsent(id, TextEditingController.new);

  Map<int, Poisha> get _totalValues => {
    for (final MapEntry(:key, :value) in _totals.entries)
      if ((parseTaka(value.text) ?? 0) != 0) key: parseTaka(value.text)!,
  };

  List<SavedPart> get _savedValues => [
    for (final s in _saved)
      (fund: s.fund, account: s.account, amount: parseTaka(s.amount.text) ?? 0),
  ];

  Poisha get _grandTotal =>
      _totalValues.values.fold(0, (t, v) => t + v) +
      _investments.values.fold(0, (t, c) => t + (parseTaka(c.text) ?? 0));

  Future<String?> _askName(String title, String hint, {String initial = ''}) {
    final name = TextEditingController(text: initial);
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
          FilledButton(onPressed: () => Navigator.pop(context, name.text), child: const Text('OK')),
        ],
      ),
    ).then((v) => v == null || v.trim().isEmpty ? null : v.trim());
  }

  Future<void> _addAccount(AccountType type, String hint) async {
    final name = await _askName('New ${accountTypeLabel(type).toLowerCase()}', hint);
    if (name != null) await ref.read(setupRepositoryProvider).addAccount(name, type);
  }

  Future<void> _save(Ledger ledger) async {
    final overdrawn = <int>[];
    final split = splitStartingBalances(
      totals: _totalValues,
      saved: _savedValues,
      spendingFund: ledger.spendingFund.id,
      overdrawn: overdrawn,
    );
    if (split == null) {
      showSnack(
        context,
        'Savings in ${overdrawn.map((a) => ledger.accounts[a]?.name).toSet().join(', ')} '
        'are more than the amount you entered for it',
      );
      return;
    }
    final investmentFund = ledger.fundsOfKind(FundKind.investment).firstOrNull;
    final balances = [
      ...split,
      if (investmentFund != null)
        for (final MapEntry(:key, :value) in _investments.entries)
          if ((parseTaka(value.text) ?? 0) != 0)
            ((account: key, fund: investmentFund.id), parseTaka(value.text)!),
    ];
    if (balances.isEmpty) {
      showSnack(context, 'Enter at least one amount');
      return;
    }
    final ok = await confirm(
      context,
      title: 'Save starting balances?',
      body:
          '${formatTaka(_grandTotal)} in total, as of the start of '
          '${DateFormat.yMMMd().format(_start)}.\n\n'
          '${[for (final (pot, amount) in balances) '${potLabel(ledger, pot)}: ${formatTaka(amount)}'].join('\n')}',
      action: 'Save',
    );
    if (!ok) return;
    await ref.read(repositoryProvider).setStartingBalances(_start, balances);
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Starting balances saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Starting balances')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final accounts = ledger
              .accountsOfType((t) => t.isLiquid)
              .where((a) => !a.archived)
              .toList();
          final investments = ledger
              .accountsOfType((t) => t == AccountType.investment)
              .where((a) => !a.archived)
              .toList();
          final pots = [
            ...ledger.fundsOfKind(FundKind.savings),
            ...ledger.fundsOfKind(FundKind.goal),
          ];
          final setup = ref.read(setupRepositoryProvider);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Text(
                'Enter what you have on the day you begin. Starting on the 1st of a month gives '
                'the cleanest first report.',
                style: TextStyle(color: status.muted),
              ),
              if (!ledger.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'You already have entries. These balances are added to them.',
                  style: TextStyle(color: status.warn),
                ),
              ],
              const SizedBox(height: 12),
              PickerField(
                label: 'Starting on',
                value: DateFormat.yMMMEd().format(_start),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime(2000),
                    lastDate: ref.read(todayProvider).add(const Duration(days: 62)),
                  );
                  if (picked != null) setState(() => _start = picked);
                },
              ),
              const SizedBox(height: 12),
              SectionCard(
                children: [
                  const Label('Your money'),
                  for (final a in accounts)
                    Row(
                      spacing: 4,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final name = await _askName(
                                'Rename',
                                'e.g. City Bank',
                                initial: a.name,
                              );
                              if (name != null) await setup.updateAccount(a.id, name: name);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 4,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          a.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Icon(Icons.edit_outlined, size: 14, color: status.muted),
                                    ],
                                  ),
                                  Text(
                                    accountTypeLabel(a.type),
                                    style: TextStyle(color: status.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: AmountField(
                            controller: _total(a.id),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.account_balance_outlined, size: 18),
                        label: const Text('Bank account'),
                        onPressed: () => _addAccount(AccountType.bank, 'e.g. BRAC Bank'),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.phone_android, size: 18),
                        label: const Text('Mobile wallet'),
                        onPressed: () => _addAccount(AccountType.wallet, 'e.g. Nagad'),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Cash'),
                        onPressed: () => _addAccount(AccountType.cash, 'e.g. Wallet cash'),
                      ),
                    ],
                  ),
                  AmountRow('Total', _totalValues.values.fold(0, (t, v) => t + v), total: true),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                children: [
                  const Label('Part of this is already savings? (optional)'),
                  Text(
                    'Tell the app which part is savings or saved for a goal, and where it is kept. '
                    'The rest is money for spending.',
                    style: TextStyle(color: status.muted, fontSize: 13),
                  ),
                  for (final (i, s) in _saved.indexed)
                    Column(
                      spacing: 6,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: s.fund,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Savings or goal',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  for (final f in pots)
                                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                                ],
                                onChanged: (v) => setState(() => s.fund = v!),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _saved.removeAt(i).amount.dispose()),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: s.account,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Kept in',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  for (final a in accounts)
                                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                                ],
                                onChanged: (v) => setState(() => s.account = v!),
                              ),
                            ),
                            SizedBox(
                              width: 130,
                              child: AmountField(
                                controller: s.amount,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  if (pots.isNotEmpty && accounts.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add savings'),
                        onPressed: () =>
                            setState(() => _saved.add(_SavedRow(pots.first.id, accounts.first.id))),
                      ),
                    ),
                ],
              ),
              if (investments.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  children: [
                    const Label('Investments (optional)'),
                    for (final a in investments)
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(child: Text(a.name)),
                          SizedBox(
                            width: 150,
                            child: AmountField(
                              controller: _investments.putIfAbsent(a.id, TextEditingController.new),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            spacing: 12,
            children: [
              Expanded(child: Text('Total ${formatTaka(_grandTotal)}')),
              FilledButton(
                onPressed: () {
                  final ledger = ref.read(ledgerProvider).value;
                  if (ledger != null) _save(ledger);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
