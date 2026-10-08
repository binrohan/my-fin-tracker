import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final ledger = ref.read(ledgerProvider).value;
          if (ledger != null) _editCategory(context, ref, ledger, null);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: LedgerBuilder(builder: (context, ledger) {
        final status = StatusColors.of(context);
        List<Widget> section(CategoryKind kind) {
          final roots = ledger.categories.values.where((c) => c.kind == kind && c.parentId == null);
          return [
            for (final root in roots) ...[
              _tile(context, ref, ledger, root, indent: false),
              for (final child in ledger.categories.values.where((c) => c.parentId == root.id))
                _tile(context, ref, ledger, child, indent: true),
            ],
          ];
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: Label('Expenses')),
            ...section(CategoryKind.expense),
            const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 4), child: Label('Income')),
            ...section(CategoryKind.income),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Archived categories are hidden from quick add but keep their history.',
                style: TextStyle(color: status.muted),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, Ledger ledger, CategoryRow c,
      {required bool indent}) {
    final status = StatusColors.of(context);
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent ? 40 : 16, right: 16),
      title: Text(c.name,
          style: TextStyle(
            color: c.archived ? status.muted : null,
            decoration: c.archived ? TextDecoration.lineThrough : null,
            fontWeight: indent ? null : FontWeight.w600,
          )),
      subtitle: c.isFixed
          ? Text(c.dueDay == null ? 'Fixed bill' : 'Fixed bill · due on day ${c.dueDay}')
          : null,
      trailing: const Icon(Icons.edit_outlined, size: 20),
      onTap: () => _editCategory(context, ref, ledger, c),
    );
  }

  Future<void> _editCategory(
      BuildContext context, WidgetRef ref, Ledger ledger, CategoryRow? existing) async {
    final setup = ref.read(setupRepositoryProvider);
    final name = TextEditingController(text: existing?.name);
    final due = TextEditingController(text: existing?.dueDay?.toString() ?? '');
    var kind = existing?.kind ?? CategoryKind.expense;
    int? parentId = existing?.parentId;
    var fixed = existing?.isFixed ?? false;
    var archived = existing?.archived ?? false;
    final hasChildren = existing != null && ledger.categories.values.any((c) => c.parentId == existing.id);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        final parents = ledger.categories.values
            .where((c) => c.parentId == null && c.kind == kind && c.id != existing?.id && !c.archived)
            .toList();
        return SheetBody(title: existing == null ? 'New category' : 'Edit category', children: [
          TextField(
            controller: name,
            autofocus: existing == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          if (existing == null)
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(value: CategoryKind.expense, label: Text('Expense')),
                ButtonSegment(value: CategoryKind.income, label: Text('Income')),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() {
                kind = s.single;
                parentId = null;
              }),
            ),
          if (existing == null || (!hasChildren && existing.parentId != null))
            DropdownButtonFormField<int?>(
              initialValue: parentId,
              decoration: const InputDecoration(labelText: 'Inside', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nothing (main category)')),
                for (final p in parents) DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: existing == null ? (v) => setState(() => parentId = v) : null,
            ),
          if (kind == CategoryKind.expense)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fixed bill'),
              subtitle: const Text('Paid every month, shown as paid or due'),
              value: fixed,
              onChanged: (v) => setState(() => fixed = v),
            ),
          if (fixed && kind == CategoryKind.expense)
            TextField(
              controller: due,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              decoration: const InputDecoration(
                  labelText: 'Due on day of month (optional)', border: OutlineInputBorder()),
            ),
          if (existing != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Archived'),
              subtitle: const Text('Hide from quick add; history stays'),
              value: archived,
              onChanged: (v) => setState(() => archived = v),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ]);
      }),
    );
    if (saved != true) return;
    if (name.text.trim().isEmpty) {
      if (context.mounted) showSnack(context, 'A category needs a name');
      return;
    }
    final dueDay = int.tryParse(due.text);
    final validDue = (dueDay != null && dueDay >= 1 && dueDay <= 31 && fixed) ? dueDay : null;
    if (existing == null) {
      await setup.addCategory(name.text, kind, parentId: parentId, isFixed: fixed, dueDay: validDue);
    } else {
      await setup.updateCategory(existing.id,
          name: name.text, isFixed: fixed, dueDay: Value(validDue), archived: archived);
    }
  }
}
