import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ledger/tax.dart';
import '../../ui/forms.dart';

/// Adds a category of [kind], or edits [existing]: its name, and fixed bill,
/// due day and pot (expense) or income tax type (income).
Future<void> showCategoryEditor(
  BuildContext context,
  WidgetRef ref,
  Ledger ledger, {
  CategoryRow? existing,
  CategoryKind kind = CategoryKind.expense,
}) async {
  final setup = ref.read(setupRepositoryProvider);
  final name = TextEditingController(text: existing?.name);
  final due = TextEditingController(text: existing?.dueDay?.toString() ?? '');
  final type = existing?.kind ?? kind;
  int? parentId = existing?.parentId;
  var fixed = existing?.isFixed ?? false;
  var archived = existing?.archived ?? false;
  int? savingsFund = existing?.savingsFundId;
  var taxType = existing == null ? IncomeTaxType.taxable : incomeTaxType(ledger, existing.id);
  final pots = [
    for (final f in ledger.funds.values)
      if ((f.kind == FundKind.savings || (f.kind == FundKind.goal && f.achievedAt == null)) &&
          (!f.archived || f.id == savingsFund))
        f,
  ];
  final hasChildren =
      existing != null && ledger.categories.values.any((c) => c.parentId == existing.id);

  final saved = await showModalBottomSheet<bool>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final parents = ledger.categories.values
            .where(
              (c) => c.parentId == null && c.kind == type && c.id != existing?.id && !c.archived,
            )
            .toList();
        return SheetBody(
          title: type == CategoryKind.income
              ? (existing == null ? 'New income type' : 'Edit income type')
              : 'Edit ${existing?.name ?? 'category'}',
          children: [
            TextField(
              controller: name,
              autofocus: existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            if (existing == null || (!hasChildren && existing.parentId != null))
              DropdownButtonFormField<int?>(
                initialValue: parentId,
                decoration: const InputDecoration(
                  labelText: 'Inside',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Nothing (main category)')),
                  for (final p in parents) DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: existing == null ? (v) => setState(() => parentId = v) : null,
              ),
            if (type == CategoryKind.expense)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fixed bill'),
                subtitle: const Text('Paid every month, shown as paid or due'),
                value: fixed,
                onChanged: (v) => setState(() => fixed = v),
              ),
            if (fixed && type == CategoryKind.expense)
              TextField(
                controller: due,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: 'Due on day of month (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (type == CategoryKind.expense)
              DropdownButtonFormField<int?>(
                initialValue: pots.any((f) => f.id == savingsFund) ? savingsFund : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Unused budget goes to (optional)',
                  helperText:
                      'What you did not spend is saved here when you close the month, '
                      'or any time with Save to pot on the Spend tab',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Nowhere: carried forward')),
                  for (final f in pots) DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (v) => setState(() => savingsFund = v),
              ),
            if (type == CategoryKind.income)
              DropdownButtonFormField<IncomeTaxType>(
                initialValue: taxType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'For income tax',
                  helperText: 'Salary gets the salary exemption; not taxable is left out',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in IncomeTaxType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => taxType = v ?? taxType),
              ),
            if (existing != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Archived'),
                subtitle: const Text('Hide from quick add; history stays'),
                value: archived,
                onChanged: (v) => setState(() => archived = v),
              ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    ),
  );
  if (saved != true) return;
  if (name.text.trim().isEmpty) {
    if (context.mounted) showSnack(context, 'It needs a name');
    return;
  }
  final dueDay = int.tryParse(due.text);
  final validDue = (dueDay != null && dueDay >= 1 && dueDay <= 31 && fixed) ? dueDay : null;
  final int id;
  if (existing == null) {
    id = await setup.addCategory(
      name.text,
      type,
      parentId: parentId,
      isFixed: fixed,
      dueDay: validDue,
      savingsFundId: type == CategoryKind.expense ? savingsFund : null,
    );
  } else {
    id = existing.id;
    await setup.updateCategory(
      existing.id,
      name: name.text,
      isFixed: fixed,
      dueDay: Value(validDue),
      savingsFundId: Value(type == CategoryKind.expense ? savingsFund : null),
      archived: archived,
    );
  }
  if (type == CategoryKind.income && taxType != incomeTaxType(ledger, id)) {
    await ref
        .read(repositoryProvider)
        .setSetting(incomeTaxTypesSetting, encodeIncomeTaxType(ledger, id, taxType));
  }
}
