import 'package:drift/drift.dart' show Value;
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

String accountTypeLabel(AccountType t) => switch (t) {
  AccountType.bank => 'Bank',
  AccountType.cash => 'Cash',
  AccountType.wallet => 'Mobile wallet',
  AccountType.investment => 'Investment',
  AccountType.person => 'Person',
};

String fundKindLabel(FundKind k) => switch (k) {
  FundKind.spending => 'Spending',
  FundKind.savings => 'Savings pot',
  FundKind.goal => 'Goal',
  FundKind.investment => 'Investments',
};

/// Where money is (accounts) and what it is for (savings pots and goals).
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts & pots')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          TextStyle? archivedStyle(bool archived) => archived
              ? TextStyle(color: status.muted, decoration: TextDecoration.lineThrough)
              : null;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Label('Where money is'),
              ),
              for (final a in ledger.accounts.values)
                ListTile(
                  title: Text(a.name, style: archivedStyle(a.archived)),
                  subtitle: Text(accountTypeLabel(a.type)),
                  trailing: Money(ledger.accountBalance(a.id)),
                  onTap: () => _editAccount(context, ref, ledger, a),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editAccount(context, ref, ledger, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add account'),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Label('What money is for'),
              ),
              for (final f in ledger.funds.values)
                ListTile(
                  title: Text(f.name, style: archivedStyle(f.archived)),
                  subtitle: Text(
                    [
                      fundKindLabel(f.kind),
                      if (f.targetAmount != null) 'target ${formatTaka(f.targetAmount!)}',
                      if (f.targetDate != null) 'by ${DateFormat.yMMM().format(f.targetDate!)}',
                    ].join(' · '),
                  ),
                  trailing: Money(ledger.fundBalance(f.id, liquidOnly: false)),
                  onTap: () => _editFund(context, ref, ledger, f),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editFund(context, ref, ledger, null, kind: FundKind.goal),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Add goal'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _editFund(context, ref, ledger, null, kind: FundKind.savings),
                      icon: const Icon(Icons.savings_outlined),
                      label: const Text('Add savings pot'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editAccount(BuildContext context, WidgetRef ref, Ledger ledger, Account? a) async {
    final setup = ref.read(setupRepositoryProvider);
    final name = TextEditingController(text: a?.name);
    var type = a?.type ?? AccountType.bank;
    var archived = a?.archived ?? false;
    final balance = a == null ? 0 : ledger.accountBalance(a.id);

    final ok = await showModalBottomSheet<bool>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SheetBody(
          title: a == null ? 'New account' : 'Edit account',
          children: [
            TextField(
              controller: name,
              autofocus: a == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            if (a == null)
              DropdownButtonFormField<AccountType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: [
                  for (final t in AccountType.values)
                    DropdownMenuItem(value: t, child: Text(accountTypeLabel(t))),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
            if (a != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Archived'),
                subtitle: Text(
                  balance == 0
                      ? 'Hide from pickers; history stays'
                      : 'Only possible when the balance is ৳0 (now ${formatTaka(balance)})',
                ),
                value: archived,
                onChanged: balance == 0 || archived ? (v) => setState(() => archived = v) : null,
              ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    if (a == null) {
      await setup.addAccount(name.text, type);
    } else {
      await setup.updateAccount(a.id, name: name.text, archived: archived);
    }
  }

  Future<void> _editFund(
    BuildContext context,
    WidgetRef ref,
    Ledger ledger,
    Fund? f, {
    FundKind kind = FundKind.goal,
  }) async {
    final setup = ref.read(setupRepositoryProvider);
    kind = f?.kind ?? kind;
    final name = TextEditingController(text: f?.name);
    final target = TextEditingController(text: amountText(f?.targetAmount ?? 0));
    DateTime? targetDate = f?.targetDate;
    var archived = f?.archived ?? false;
    final balance = f == null ? 0 : ledger.fundBalance(f.id, liquidOnly: false);
    final canArchive = f != null && f.kind != FundKind.spending;

    final ok = await showModalBottomSheet<bool>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SheetBody(
          title: f == null ? 'New ${fundKindLabel(kind).toLowerCase()}' : 'Edit ${f.name}',
          children: [
            TextField(
              controller: name,
              autofocus: f == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: kind == FundKind.goal ? 'e.g. New Laptop' : null,
                border: const OutlineInputBorder(),
              ),
            ),
            if (kind == FundKind.goal) ...[
              AmountField(controller: target, label: 'Target amount'),
              PickerField(
                label: 'Target date (optional)',
                value: targetDate == null ? 'No date' : DateFormat.yMMMd().format(targetDate!),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate ?? DateTime(now.year + 1, now.month, now.day),
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 30),
                  );
                  if (picked != null) setState(() => targetDate = picked);
                },
              ),
            ],
            if (canArchive)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Archived'),
                subtitle: Text(
                  balance == 0
                      ? 'Hide from pickers; history stays'
                      : 'Only possible when it holds ৳0 (now ${formatTaka(balance)})',
                ),
                value: archived,
                onChanged: balance == 0 || archived ? (v) => setState(() => archived = v) : null,
              ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final amount = parseTaka(target.text);
    final targetValue = kind == FundKind.goal && amount != null && amount > 0 ? amount : null;
    if (f == null) {
      await setup.addFund(name.text, kind, target: targetValue, targetDate: targetDate);
    } else {
      await setup.updateFund(
        f.id,
        name: name.text,
        target: kind == FundKind.goal ? Value(targetValue) : const Value.absent(),
        targetDate: kind == FundKind.goal ? Value(targetDate) : const Value.absent(),
        archived: canArchive ? archived : null,
      );
    }
  }
}
