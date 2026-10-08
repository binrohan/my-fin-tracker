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

/// Your real balances on the day you start using the app, split by what the
/// money is for.
class StartingBalancesScreen extends ConsumerStatefulWidget {
  const StartingBalancesScreen({super.key});

  @override
  ConsumerState<StartingBalancesScreen> createState() => _StartingBalancesScreenState();
}

class _StartingBalancesScreenState extends ConsumerState<StartingBalancesScreen> {
  final _fields = <String, TextEditingController>{};
  late DateTime _start = _defaultStart(ref.read(todayProvider));

  /// The 1st of this month if today is early in the month, otherwise today.
  static DateTime _defaultStart(DateTime today) =>
      today.day <= 3 ? DateTime(today.year, today.month) : today;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(Pot pot) =>
      _fields.putIfAbsent(potSetting(pot), TextEditingController.new);

  List<(Pot, Poisha)> _balances() => [
    for (final MapEntry(:key, :value) in _fields.entries)
      if ((parseTaka(value.text) ?? 0) != 0)
        (
          (account: int.parse(key.split(':')[0]), fund: int.parse(key.split(':')[1])),
          parseTaka(value.text)!,
        ),
  ];

  Future<void> _save(Ledger ledger) async {
    final balances = _balances();
    if (balances.isEmpty) {
      showSnack(context, 'Enter at least one balance');
      return;
    }
    final total = balances.fold<Poisha>(0, (t, b) => t + b.$2);
    final ok = await confirm(
      context,
      title: 'Save starting balances?',
      body:
          '${formatTaka(total)} across ${balances.length} pots, '
          'as of the start of ${DateFormat.yMMMd().format(_start)}.',
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
          final accounts = ledger.accounts.values.where(
            (a) => !a.archived && (a.type.isLiquid || a.type == AccountType.investment),
          );
          final funds = ledger.funds.values
              .where((f) => !f.archived && f.kind != FundKind.investment)
              .toList();
          final investmentFund = ledger.funds.values
              .where((f) => f.kind == FundKind.investment && !f.archived)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Text(
                'Enter what you have at the start of the day you begin. Split each account by what '
                'the money is for; leave the rest empty. Starting on the 1st of a month gives the '
                'cleanest first report.',
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
              for (final a in accounts) ...[
                Padding(padding: const EdgeInsets.only(top: 20, bottom: 4), child: Label(a.name)),
                if (a.type == AccountType.investment && investmentFund != null)
                  _row('Current value', _field((account: a.id, fund: investmentFund.id)))
                else
                  for (final f in funds) _row(f.name, _field((account: a.id, fund: f.id))),
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
              Expanded(
                child: Text('Total ${formatTaka(_balances().fold<Poisha>(0, (t, b) => t + b.$2))}'),
              ),
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

  Widget _row(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      spacing: 12,
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 160,
          child: AmountField(controller: controller, onChanged: (_) => setState(() {})),
        ),
      ],
    ),
  );
}
