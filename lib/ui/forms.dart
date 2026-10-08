import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../core/money.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../ledger/enums.dart';
import '../ledger/ledger.dart';
import 'widgets.dart';

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

void showSnack(BuildContext context, String message, {SnackBarAction? action}) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));

/// "Cash · Spending"
String potLabel(Ledger ledger, Pot pot) =>
    '${ledger.accounts[pot.account]?.name ?? '?'} · ${ledger.funds[pot.fund]?.name ?? '?'}';

String dayLabel(DateTime date, DateTime today) {
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today, ${DateFormat.MMMd().format(d)}';
  if (diff == 1) return 'Yesterday, ${DateFormat.MMMd().format(d)}';
  return DateFormat.yMMMEd().format(d);
}

/// A text field for taka amounts. Accepts digits, commas and a decimal point.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.allowNegative = false,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool allowNegative;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(allowNegative ? r'[0-9.,\-]' : r'[0-9.,]')),
    ],
    textAlign: TextAlign.end,
    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint ?? '0',
      prefixText: '$takaSymbol ',
      isDense: true,
      border: const OutlineInputBorder(),
    ),
    onChanged: onChanged,
  );
}

/// Text for an amount field: "1,23,970" or "" for zero.
String amountText(Poisha amount) => amount == 0 ? '' : formatTaka(amount, symbol: false);

/// A tappable box showing a label and a value, opening a picker.
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: StatusColors.of(context).sunk,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(label),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    ),
  );
}

/// Lets you choose an account and a fund ("Cash · Spending").
Future<Pot?> pickPot(
  BuildContext context,
  Ledger ledger, {
  required String title,
  required Pot initial,
  bool includeInvestments = false,
}) {
  final accounts = ledger.accounts.values
      .where(
        (a) =>
            !a.archived &&
            (a.type.isLiquid || (includeInvestments && a.type == AccountType.investment)),
      )
      .toList();
  final funds = ledger.funds.values.where((f) => !f.archived).toList();
  var account = initial.account;
  var fund = initial.fund;

  return showModalBottomSheet<Pot>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const Label('Where the money is'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final a in accounts)
                    ChoiceChip(
                      label: Text(a.name),
                      selected: account == a.id,
                      onSelected: (_) => setState(() => account = a.id),
                    ),
                ],
              ),
              const Label('What it is for'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final f in funds)
                    ChoiceChip(
                      label: Text(f.name),
                      selected: fund == f.id,
                      onSelected: (_) => setState(() => fund = f.id),
                    ),
                ],
              ),
              Text(
                'In this pot now: ${formatTaka(ledger.cell(account, fund))}',
                style: TextStyle(color: StatusColors.of(context).muted),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, (account: account, fund: fund)),
                child: const Text('Use this'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Chooses one leaf category from the full list, grouped by parent.
Future<CategoryRow?> pickCategory(BuildContext context, Ledger ledger, CategoryKind kind) {
  final leaves = ledger.leafCategories(kind);
  return showModalBottomSheet<CategoryRow>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          for (final c in leaves)
            ListTile(
              title: Text(c.name),
              subtitle: c.parentId == null ? null : Text(ledger.categories[c.parentId]!.name),
              onTap: () => Navigator.pop(context, c),
            ),
        ],
      ),
    ),
  );
}

/// A bottom sheet body with a title, scrolling content and the keyboard
/// pushing it up.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// Pot ids parsed from a setting like "3:1"; null if missing or stale.
Pot? potFromSetting(Ledger ledger, String? value) {
  final parts = value?.split(':');
  if (parts == null || parts.length != 2) return null;
  final account = int.tryParse(parts[0]);
  final fund = int.tryParse(parts[1]);
  if (account == null || fund == null) return null;
  final a = ledger.accounts[account];
  final f = ledger.funds[fund];
  if (a == null || f == null || a.archived || f.archived) return null;
  return (account: account, fund: fund);
}

String potSetting(Pot pot) => '${pot.account}:${pot.fund}';

/// First liquid account of a type, falling back to any liquid account.
Account defaultAccount(Ledger ledger, AccountType type) {
  final liquid = ledger.accounts.values.where((a) => a.type.isLiquid && !a.archived);
  return liquid.firstWhere((a) => a.type == type, orElse: () => liquid.first);
}

/// Opens a full screen above the tabs.
Future<void> openScreen(BuildContext context, Widget screen) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => screen));
