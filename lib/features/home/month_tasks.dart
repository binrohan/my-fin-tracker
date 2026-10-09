import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../reports/reports_screen.dart';

const leftoverSetting = 'month_leftover';
const leftoverCarry = 'carry_forward';
const leftoverToSavings = 'to_savings';

/// Compare an account with its real balance (bank app, counted cash) and
/// record any difference.
Future<void> showMatchBalance(BuildContext context) => showModalBottomSheet(
  useRootNavigator: true,
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _MatchBalanceSheet(),
);

class _MatchBalanceSheet extends ConsumerStatefulWidget {
  const _MatchBalanceSheet();

  @override
  ConsumerState<_MatchBalanceSheet> createState() => _MatchBalanceSheetState();
}

class _MatchBalanceSheetState extends ConsumerState<_MatchBalanceSheet> {
  int? _account;
  final _real = TextEditingController();

  @override
  void dispose() {
    _real.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final status = StatusColors.of(context);
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();
    _account ??= accounts.first.id;
    final app = ledger.accountBalance(_account!);
    final real = parseTaka(_real.text);
    final diff = real == null ? null : real - app;
    final spending = ledger.spendingFund.id;

    return SheetBody(
      title: 'Match a balance',
      children: [
        Text(
          'Enter the balance your bank app shows (or the cash you counted). '
          'Any difference is recorded as an adjustment to Spending.',
          style: TextStyle(color: status.muted),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final a in accounts)
              ChoiceChip(
                label: Text(a.name),
                selected: a.id == _account,
                onSelected: (_) => setState(() => _account = a.id),
              ),
          ],
        ),
        AmountRow('The app says', app),
        AmountField(
          controller: _real,
          label: 'Real balance',
          autofocus: true,
          allowNegative: true,
          onChanged: (_) => setState(() {}),
        ),
        if (diff != null)
          diff == 0
              ? const StatusChip('Matches', tone: ChipTone.good, icon: Icons.check)
              : AmountRow('Difference', diff, signed: true),
        FilledButton(
          onPressed: diff == null || diff == 0
              ? null
              : () async {
                  await ref
                      .read(repositoryProvider)
                      .matchBalance(
                        date: ref.read(todayProvider),
                        pot: (account: _account!, fund: spending),
                        appBalance: app,
                        realBalance: real!,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(context, '${ledger.accounts[_account]!.name} now matches');
                },
          child: const Text('Record the difference'),
        ),
      ],
    );
  }
}

/// Close a finished month: optionally confirm the bank balance, then carry
/// the leftover forward or move it to savings.
Future<void> showCloseMonth(BuildContext context, Period period) => showModalBottomSheet(
  useRootNavigator: true,
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _CloseMonthSheet(period: period),
);

class _CloseMonthSheet extends ConsumerStatefulWidget {
  const _CloseMonthSheet({required this.period});

  final Period period;

  @override
  ConsumerState<_CloseMonthSheet> createState() => _CloseMonthSheetState();
}

class _LeftoverRow {
  _LeftoverRow(this.fund, Poisha amount) : amount = TextEditingController(text: amountText(amount));

  int fund;
  final TextEditingController amount;
}

class _CloseMonthSheetState extends ConsumerState<_CloseMonthSheet> {
  final _bank = TextEditingController();

  /// Parts of the leftover moved to pots and goals; the rest carries over.
  final _rows = <_LeftoverRow>[];
  bool _rowsReady = false;

  @override
  void dispose() {
    _bank.dispose();
    for (final r in _rows) {
      r.amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final p = widget.period;
    final s = ledger.summary(p);
    final savings = ledger.fundsOfKind(FundKind.savings).firstOrNull;
    final bank = ledger
        .accountsOfType((t) => t == AccountType.bank)
        .where((a) => !a.archived)
        .firstOrNull;
    final appBank = bank == null ? 0 : ledger.accountBalance(bank.id, before: p.end);
    final realBank = parseTaka(_bank.text);
    final status = StatusColors.of(context);
    final toPots = ledger.unusedBudgetMoves(p);
    final toPotsTotal = toPots.fold<Poisha>(0, (t, m) => t + m.amount);
    final leftAfter = s.leftToSpend - toPotsTotal;
    final pots = [
      for (final f in ledger.funds.values)
        if (!f.archived &&
            (f.kind == FundKind.savings || (f.kind == FundKind.goal && f.achievedAt == null)))
          f,
    ];
    if (!_rowsReady) {
      _rowsReady = true;
      // Last time everything went to savings: suggest the same.
      if (ledger.setting(leftoverSetting, leftoverCarry) == leftoverToSavings &&
          savings != null &&
          leftAfter > 0) {
        _rows.add(_LeftoverRow(savings.id, leftAfter));
      }
    }
    final rest = leftAfter - _rows.fold<Poisha>(0, (t, r) => t + (parseTaka(r.amount.text) ?? 0));

    return SheetBody(
      title: 'Close ${p.label}',
      children: [
        AmountRow('Income', s.income),
        AmountRow('Spent', s.expenses, detail: 'budget ${formatTaka(s.budget)}'),
        AmountRow('Set aside', s.setAside),
        AmountRow('Left over', s.leftToSpend, total: true),
        if (toPots.isNotEmpty) ...[
          const Label('Unused budget to savings'),
          for (final m in toPots)
            AmountRow(
              '${m.category.name} → ${m.fund.name}',
              m.amount,
              detail: m.amount < m.unused ? 'of ${formatTaka(m.unused)} unused' : null,
            ),
          if (toPots.any((m) => m.amount < m.unused))
            Text(
              'Less than the unused budget moves: only ${formatTaka(s.leftToSpend)} was left in Spending.',
              style: TextStyle(color: status.warn, fontSize: 13),
            ),
        ],
        if (bank != null) ...[
          const Label('Check the bank (optional)'),
          Text(
            '${bank.name} on the last day, by the app: ${formatTaka(appBank)}',
            style: TextStyle(color: status.muted),
          ),
          AmountField(
            controller: _bank,
            label: 'Balance on your statement',
            allowNegative: true,
            onChanged: (_) => setState(() {}),
          ),
          if (realBank != null && realBank != appBank)
            Text(
              'A ${formatTaka(realBank - appBank, showPlus: true)} adjustment will be recorded on '
              'the last day of ${p.label}.',
              style: TextStyle(color: status.warn),
            ),
        ],
        if (leftAfter > 0) ...[
          Label('The leftover: ${formatTaka(leftAfter)}'),
          Text(
            'Move parts of it to savings or goals. Whatever you do not move is carried forward.',
            style: TextStyle(color: status.muted, fontSize: 13),
          ),
          for (final (i, r) in _rows.indexed)
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: r.fund,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    items: [
                      for (final f in pots) DropdownMenuItem(value: f.id, child: Text(f.name)),
                    ],
                    onChanged: (v) => setState(() => r.fund = v!),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: AmountField(controller: r.amount, onChanged: (_) => setState(() {})),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _rows.removeAt(i).amount.dispose()),
                ),
              ],
            ),
          if (pots.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Move part to savings or a goal'),
                  onPressed: () =>
                      setState(() => _rows.add(_LeftoverRow(pots.first.id, rest > 0 ? rest : 0))),
                ),
                if (_rows.isEmpty && savings != null)
                  TextButton(
                    onPressed: () => setState(() => _rows.add(_LeftoverRow(savings.id, leftAfter))),
                    child: Text('All to ${savings.name}'),
                  ),
              ],
            ),
          AmountRow(
            'Carried forward to ${p.next.label}',
            rest,
            total: true,
            color: rest < 0 ? status.bad : null,
          ),
          if (rest < 0)
            Text(
              'That is ${formatTaka(-rest)} more than the leftover.',
              style: TextStyle(color: status.bad, fontSize: 13),
            ),
        ],
        FilledButton(
          onPressed: rest < 0
              ? null
              : () async {
                  final repo = ref.read(repositoryProvider);
                  final lastDay = p.end.subtract(const Duration(days: 1));
                  if (bank != null && realBank != null) {
                    await repo.matchBalance(
                      date: lastDay,
                      pot: (account: bank.id, fund: ledger.spendingFund.id),
                      appBalance: appBank,
                      realBalance: realBank,
                      note: 'Matched to statement for ${p.label}',
                    );
                  }
                  final db = ref.read(databaseProvider);
                  // Recalculate after a bank correction, then save unused budget
                  // of linked categories before deciding on the leftover.
                  final afterBank = await Ledger.load(db);
                  await repo.moveUnusedBudgets(
                    p,
                    ledger.spendingFund.id,
                    afterBank.unusedBudgetMoves(p),
                  );
                  final fresh = await Ledger.load(db);
                  final split = [
                    for (final r in _rows)
                      if ((parseTaka(r.amount.text) ?? 0) > 0)
                        (fund: r.fund, amount: parseTaka(r.amount.text)!),
                  ];
                  await repo.closeMonth(
                    p,
                    spendingFund: ledger.spendingFund.id,
                    leftoverTo: split,
                    leftovers: fresh.spendingCells(p),
                    confirmedBank: realBank,
                  );
                  // Remember: everything to savings next time, or carry forward.
                  await repo.setSetting(
                    leftoverSetting,
                    split.length == 1 && split.single.fund == savings?.id && rest == 0
                        ? leftoverToSavings
                        : leftoverCarry,
                  );
                  if (!context.mounted) return;
                  final navigator = Navigator.of(context, rootNavigator: true);
                  Navigator.pop(context);
                  showSnack(
                    context,
                    '${p.label} closed',
                    action: SnackBarAction(
                      label: 'View report',
                      onPressed: () => navigator.push(
                        MaterialPageRoute<void>(builder: (_) => ReportPreviewScreen.monthly(p)),
                      ),
                    ),
                  );
                },
          child: Text('Close ${p.label}'),
        ),
      ],
    );
  }
}
