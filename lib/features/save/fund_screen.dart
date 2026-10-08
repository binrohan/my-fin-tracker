import 'package:flutter/material.dart';
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
import '../entries/entries_screen.dart';
import '../loans/loan_sheets.dart';
import 'move_sheet.dart';

/// One savings pot or goal: balance, where the money is, actions and
/// history.
class FundScreen extends ConsumerWidget {
  const FundScreen({super.key, required this.fundId});

  final int fundId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(
      builder: (context, ledger) {
        final fund = ledger.funds[fundId];
        if (fund == null) return const Scaffold(body: Center(child: Text('This pot was removed.')));
        final status = StatusColors.of(context);
        final isGoal = fund.kind == FundKind.goal;
        final goal = isGoal ? ledger.goalStatus(fund, today) : null;
        final total = ledger.fundBalance(fund.id, liquidOnly: false);
        final where = [
          for (final a in ledger.accounts.values)
            if (ledger.cell(a.id, fund.id) != 0) (account: a, amount: ledger.cell(a.id, fund.id)),
        ];
        final owed = ledger.owedToFund(fund.id);
        final spending = ledger.spendingFund.id;
        final bank = defaultAccount(ledger, AccountType.bank).id;
        final biggest = where
            .where((w) => w.account.type.isLiquid)
            .fold<Account?>(
              null,
              (best, w) =>
                  best == null || w.amount > ledger.cell(best.id, fund.id) ? w.account : best,
            );
        final source = biggest?.id ?? bank;

        return Scaffold(
          appBar: AppBar(title: Text(fund.name)),
          body: PageList(
            children: [
              SectionCard(
                children: [
                  Row(
                    children: [
                      Expanded(child: Label(isGoal ? 'Saved for this goal' : 'Balance')),
                      if (fund.achievedAt != null)
                        StatusChip(
                          'Achieved ${DateFormat.yMMM().format(fund.achievedAt!)}',
                          tone: ChipTone.good,
                        )
                      else if (goal != null && goal.target > 0)
                        StatusChip(
                          goal.onTrack ? 'On track' : 'Behind',
                          tone: goal.onTrack ? ChipTone.good : ChipTone.warn,
                        ),
                    ],
                  ),
                  Money(total, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  if (goal != null && goal.target > 0) ...[
                    Bar(goal.progress, color: goal.onTrack ? status.good : status.warn),
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(1)}% of ${formatTaka(goal.target)}'
                      '${fund.targetDate == null ? '' : ' by ${DateFormat.yMMM().format(fund.targetDate!)}'}',
                    ),
                    if (goal.neededPerMonth != null && !goal.reached)
                      Text(
                        'Needs ${formatTaka(goal.neededPerMonth!)}/mo. '
                        'This month: ${formatTaka(goal.monthly)}.',
                        style: TextStyle(color: status.muted),
                      ),
                  ],
                  if (owed > 0)
                    StatusChip(
                      '${formatTaka(owed)} borrowed, to be paid back',
                      tone: ChipTone.warn,
                    ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Where the money is'),
                  if (where.isEmpty) Text('Nothing yet.', style: TextStyle(color: status.muted)),
                  for (final w in where) AmountRow(w.account.name, w.amount),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Deposit'),
                    onPressed: () => showMoveSheet(
                      context,
                      title: 'Deposit to ${fund.name}',
                      from: (account: bank, fund: spending),
                      to: (account: bank, fund: fund.id),
                      lockTo: false,
                      action: 'Deposit',
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Withdraw'),
                    onPressed: total <= 0
                        ? null
                        : () => showMoveSheet(
                            context,
                            title: 'Withdraw from ${fund.name}',
                            hint: 'Moves money back to Spending. To borrow it with a charge, use Borrow.',
                            from: (account: source, fund: fund.id),
                            to: (account: source, fund: spending),
                            action: 'Withdraw',
                          ),
                  ),
                  if (fund.kind != FundKind.investment)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('Borrow'),
                      onPressed: total <= 0
                          ? null
                          : () => showNewLoan(
                              context,
                              kind: LoanKind.ownSavings,
                              sourceFund: fund.id,
                            ),
                    ),
                  if (isGoal && fund.achievedAt == null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Buy it'),
                      onPressed: () => _buy(context, ref, ledger, fund),
                    ),
                  if (isGoal && fund.achievedAt != null)
                    TextButton(
                      onPressed: () => ref.read(repositoryProvider).setGoalAchieved(fund.id, null),
                      child: const Text('Mark not achieved'),
                    ),
                ],
              ),
              _History(ledger: ledger, fundId: fund.id),
            ],
          ),
        );
      },
    );
  }

  Future<void> _buy(BuildContext context, WidgetRef ref, Ledger ledger, Fund goal) async {
    final price = TextEditingController(
      text: amountText(ledger.fundBalance(goal.id, liquidOnly: true)),
    );
    final note = TextEditingController(text: goal.name);
    final categories = ledger.leafCategories(CategoryKind.expense);
    var categoryId = categories
        .firstWhere((c) => c.name == 'Random', orElse: () => categories.first)
        .id;
    var account = defaultAccount(ledger, AccountType.bank).id;
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final status = StatusColors.of(context);
          final p = parseTaka(price.text) ?? 0;
          final saved = ledger.fundBalance(goal.id);
          return SheetBody(
            title: 'Buy ${goal.name}',
            children: [
              AmountField(
                controller: price,
                label: 'Price paid',
                onChanged: (_) => setState(() {}),
              ),
              if (p > saved)
                Text(
                  '${formatTaka(p - saved)} more than saved; it comes from Spending.',
                  style: TextStyle(color: status.warn),
                )
              else if (p > 0 && p < saved)
                Text(
                  '${formatTaka(saved - p)} stays in the goal; you can withdraw it afterwards.',
                  style: TextStyle(color: status.muted),
                ),
              DropdownButtonFormField<int>(
                initialValue: account,
                decoration: const InputDecoration(
                  labelText: 'Paid from',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => account = v!),
              ),
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => categoryId = v!),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'What you bought',
                  border: OutlineInputBorder(),
                ),
              ),
              FilledButton(
                onPressed: p <= 0 ? null : () => Navigator.pop(context, true),
                child: Text('Record purchase ${formatTaka(p)}'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    await ref
        .read(repositoryProvider)
        .buyGoal(
          goalId: goal.id,
          spendingFund: ledger.spendingFund.id,
          payFromAccount: account,
          goalMoney: [
            for (final a in ledger.accountsOfType((t) => t.isLiquid))
              (account: a.id, amount: ledger.cell(a.id, goal.id)),
          ],
          date: ref.read(todayProvider),
          price: parseTaka(price.text)!,
          categoryId: categoryId,
          note: note.text.trim(),
        );
    if (context.mounted) showSnack(context, '${goal.name} bought. Goal achieved!');
  }
}

class _History extends StatelessWidget {
  const _History({required this.ledger, required this.fundId});

  final Ledger ledger;
  final int fundId;

  @override
  Widget build(BuildContext context) {
    final history = ledger.fundHistory(fundId);
    final status = StatusColors.of(context);
    return SectionCard(
      children: [
        const Label('History'),
        if (history.isEmpty) Text('No deposits yet.', style: TextStyle(color: status.muted)),
        for (final h in history.take(60))
          InkWell(
            onTap: () => showEntryDetails(context, h.entry),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AmountRow(
                entryTitle(ledger, h.entry),
                h.amount,
                signed: true,
                detail: DateFormat.yMMMd().format(h.entry.date),
              ),
            ),
          ),
      ],
    );
  }
}
