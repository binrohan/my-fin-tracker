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
              ? const StatusChip('✓ Matches', tone: ChipTone.good)
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

class _CloseMonthSheetState extends ConsumerState<_CloseMonthSheet> {
  final _bank = TextEditingController();
  String? _leftover;

  @override
  void dispose() {
    _bank.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger == null) return const SizedBox(height: 200);
    final p = widget.period;
    final s = ledger.summary(p);
    final savings = ledger.fundsOfKind(FundKind.savings).firstOrNull;
    _leftover ??= ledger.setting(leftoverSetting, leftoverCarry);
    final bank = ledger
        .accountsOfType((t) => t == AccountType.bank)
        .where((a) => !a.archived)
        .firstOrNull;
    final appBank = bank == null ? 0 : ledger.accountBalance(bank.id, before: p.end);
    final realBank = parseTaka(_bank.text);
    final status = StatusColors.of(context);

    return SheetBody(
      title: 'Close ${p.label}',
      children: [
        AmountRow('Income', s.income),
        AmountRow('Spent', s.expenses, detail: 'budget ${formatTaka(s.budget)}'),
        AmountRow('Set aside', s.setAside),
        AmountRow('Left over', s.leftToSpend, total: true),
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
        if (s.leftToSpend > 0 && savings != null) ...[
          const Label('The leftover'),
          RadioGroup<String>(
            groupValue: _leftover,
            onChanged: (v) => setState(() => _leftover = v),
            child: Column(
              children: [
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: leftoverCarry,
                  title: Text('Carry ${formatTaka(s.leftToSpend)} forward to ${p.next.label}'),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: leftoverToSavings,
                  title: Text('Move it to ${savings.name}'),
                ),
              ],
            ),
          ),
        ],
        FilledButton(
          onPressed: () async {
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
            final sweep = _leftover == leftoverToSavings && savings != null;
            // Re-read so a bank correction just recorded is in the leftover.
            final fresh = await Ledger.load(ref.read(databaseProvider));
            await repo.closeMonth(
              p,
              spendingFund: ledger.spendingFund.id,
              sweepTo: sweep ? savings.id : null,
              leftovers: [
                for (final a in fresh.accountsOfType((t) => t.isLiquid))
                  (account: a.id, amount: fresh.cell(a.id, ledger.spendingFund.id, before: p.end)),
              ],
              confirmedBank: realBank,
            );
            await repo.setSetting(leftoverSetting, _leftover!);
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
