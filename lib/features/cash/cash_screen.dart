import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../save/move_sheet.dart';

/// Bangladeshi notes and coins, largest first.
const denominations = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

String _countKey(int accountId) => 'cash_count_$accountId';

/// The last cash count for an account: when, and what was counted.
({DateTime date, Poisha counted})? lastCount(Ledger ledger, int accountId) {
  final raw = ledger.settings[_countKey(accountId)];
  if (raw == null) return null;
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (date: DateTime.parse(json['date'] as String), counted: json['counted'] as int);
}

class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  ConsumerState<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends ConsumerState<CashScreen> {
  int? _accountId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash in drawer')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final cashAccounts = ledger
              .accountsOfType((t) => t == AccountType.cash)
              .where((a) => !a.archived)
              .toList();
          if (cashAccounts.isEmpty) {
            return const Center(child: Text('Add a cash account in Accounts & pots.'));
          }
          final cash = cashAccounts.firstWhere(
            (a) => a.id == _accountId,
            orElse: () => cashAccounts.first,
          );
          final status = StatusColors.of(context);
          final total = ledger.accountBalance(cash.id);
          final sectors = ledger.sectorsOf(cash.id);
          final colors = [
            Theme.of(context).colorScheme.primary,
            status.warn,
            status.muted,
            status.good,
            status.bad,
          ];
          final count = lastCount(ledger, cash.id);
          final bank = defaultAccount(ledger, AccountType.bank).id;
          final spending = ledger.spendingFund.id;

          return PageList(
            children: [
              if (cashAccounts.length > 1)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in cashAccounts)
                      ChoiceChip(
                        label: Text(a.name),
                        selected: a.id == cash.id,
                        onSelected: (_) => setState(() => _accountId = a.id),
                      ),
                  ],
                ),
              SectionCard(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Label('In the drawer')),
                      if (count != null)
                        StatusChip(
                          'Last counted ${DateFormat.MMMd().format(count.date)}',
                          tone: ChipTone.plain,
                        ),
                    ],
                  ),
                  Money(total, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                  if (total > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, s) in sectors.where((s) => s.amount > 0).indexed)
                              Expanded(
                                flex: s.amount,
                                child: ColoredBox(color: colors[i % colors.length]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  for (final (i, s) in sectors.indexed)
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: s.amount > 0 ? colors[i % colors.length] : status.bad,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(child: Text(s.fund.name)),
                        Money(s.amount, color: s.amount < 0 ? status.bad : null),
                      ],
                    ),
                  if (sectors.any((s) => s.amount < 0))
                    Text(
                      'A sector below zero means more was spent from it than it held in cash. '
                      'Move money into it, or withdraw from the bank.',
                      style: TextStyle(color: status.warn, fontSize: 13),
                    ),
                ],
              ),
              FilledButton.icon(
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Count cash'),
                onPressed: () => _count(context, ledger, cash),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => showMoveSheet(
                      context,
                      title: 'Move between sectors',
                      hint: 'The cash stays in the drawer; only what it is for changes.',
                      from: (account: cash.id, fund: sectors.firstOrNull?.fund.id ?? spending),
                      to: (account: cash.id, fund: spending),
                      action: 'Move',
                    ),
                    child: const Text('Move between sectors'),
                  ),
                  OutlinedButton(
                    onPressed: () => showMoveSheet(
                      context,
                      title: 'Withdraw from bank',
                      from: (account: bank, fund: spending),
                      to: (account: cash.id, fund: spending),
                      action: 'Withdraw',
                      note: 'Cash withdrawal',
                    ),
                    child: const Text('Withdraw from bank'),
                  ),
                  OutlinedButton(
                    onPressed: () => showMoveSheet(
                      context,
                      title: 'Deposit to bank',
                      from: (account: cash.id, fund: spending),
                      to: (account: bank, fund: spending),
                      action: 'Deposit',
                      note: 'Cash deposit',
                    ),
                    child: const Text('Deposit to bank'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _count(BuildContext context, Ledger ledger, Account cash) async {
    final counted = await showModalBottomSheet<Poisha>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CountSheet(appBalance: ledger.accountBalance(cash.id)),
    );
    if (counted == null) return;
    final repo = ref.read(repositoryProvider);
    final today = ref.read(todayProvider);
    final app = ledger.accountBalance(cash.id);
    await repo.matchBalance(
      date: today,
      pot: (account: cash.id, fund: ledger.spendingFund.id),
      appBalance: app,
      realBalance: counted,
      note: 'Cash count (${formatTaka(counted - app, showPlus: true)})',
    );
    await repo.setSetting(
      _countKey(cash.id),
      jsonEncode({'date': today.toIso8601String(), 'counted': counted}),
    );
    if (!context.mounted) return;
    showSnack(
      context,
      counted == app
          ? 'Cash matches: ${formatTaka(counted)}'
          : 'Difference of ${formatTaka(counted - app, showPlus: true)} recorded',
    );
  }
}

class _CountSheet extends StatefulWidget {
  const _CountSheet({required this.appBalance});

  final Poisha appBalance;

  @override
  State<_CountSheet> createState() => _CountSheetState();
}

class _CountSheetState extends State<_CountSheet> {
  final _counts = {for (final d in denominations) d: TextEditingController()};

  @override
  void dispose() {
    for (final c in _counts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Poisha get _total =>
      _counts.entries.fold(0, (t, e) => t + taka(e.key * (int.tryParse(e.value.text) ?? 0)));

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final diff = _total - widget.appBalance;
    return SheetBody(
      title: 'Count cash',
      children: [
        Text('Enter how many of each note and coin.', style: TextStyle(color: status.muted)),
        for (final d in denominations)
          Row(
            spacing: 12,
            children: [
              SizedBox(
                width: 64,
                child: Text('৳$d', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Text('×'),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _counts[d],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Money(taka(d * (int.tryParse(_counts[d]!.text) ?? 0))),
                ),
              ),
            ],
          ),
        AmountRow('Counted', _total, total: true),
        AmountRow('The app says', widget.appBalance),
        if (_total > 0)
          diff == 0
              ? const StatusChip('Matches', tone: ChipTone.good, icon: Icons.check)
              : AmountRow('Difference', diff, signed: true),
        FilledButton(
          onPressed: () => Navigator.pop(context, _total),
          child: Text(diff == 0 ? 'Save count' : 'Save count and record difference'),
        ),
      ],
    );
  }
}
