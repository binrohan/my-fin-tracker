import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../ledger/allocation.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// What to set aside when your salary arrives. After you add the salary in
/// quick add, one tap moves these amounts.
class AllocationScreen extends ConsumerStatefulWidget {
  const AllocationScreen({super.key});

  @override
  ConsumerState<AllocationScreen> createState() => _AllocationScreenState();
}

class _Row {
  _Row(this.fundId, this.accountId, Poisha amount)
      : amount = TextEditingController(text: amountText(amount));

  int fundId;
  int? accountId;
  final TextEditingController amount;
}

class _AllocationScreenState extends ConsumerState<AllocationScreen> {
  int? _categoryId;
  final _rows = <_Row>[];
  bool _loaded = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.amount.dispose();
    }
    super.dispose();
  }

  void _load(Ledger ledger) {
    if (_loaded) return;
    _loaded = true;
    final plan = AllocationPlan.parse(ledger.settings[AllocationPlan.settingKey]);
    _categoryId = plan.categoryId ??
        ledger.leafCategories(CategoryKind.income).where((c) => c.name == 'Salary').firstOrNull?.id;
    for (final i in plan.items) {
      if (ledger.funds[i.fundId] != null) _rows.add(_Row(i.fundId, i.accountId, i.amount));
    }
  }

  Future<void> _save() async {
    final plan = AllocationPlan(categoryId: _categoryId, items: [
      for (final r in _rows)
        if ((parseTaka(r.amount.text) ?? 0) > 0)
          AllocationItem(fundId: r.fundId, accountId: r.accountId, amount: parseTaka(r.amount.text)!),
    ]);
    await ref.read(repositoryProvider).setSetting(AllocationPlan.settingKey, plan.encode());
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, plan.isEmpty ? 'Salary plan cleared' : 'Salary plan saved: ${formatTaka(plan.total)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary plan')),
      body: LedgerBuilder(builder: (context, ledger) {
        _load(ledger);
        final status = StatusColors.of(context);
        final targets = ledger.funds.values
            .where((f) => !f.archived && f.kind != FundKind.spending)
            .toList();
        final investAccounts = ledger.accountsOfType((t) => t == AccountType.investment)
            .where((a) => !a.archived)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text(
              'When this income arrives, quick add offers to set these amounts aside from it.',
              style: TextStyle(color: status.muted),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Income', border: OutlineInputBorder()),
              items: [
                for (final c in ledger.leafCategories(CategoryKind.income))
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            for (final (i, r) in _rows.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(spacing: 6, children: [
                  Row(spacing: 8, children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: r.fundId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Set aside to', isDense: true, border: OutlineInputBorder()),
                        items: [
                          for (final f in targets) DropdownMenuItem(value: f.id, child: Text(f.name)),
                        ],
                        onChanged: (v) => setState(() {
                          r.fundId = v!;
                          r.accountId = ledger.funds[v]!.kind == FundKind.investment
                              ? investAccounts.firstOrNull?.id
                              : null;
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: AmountField(controller: r.amount, onChanged: (_) => setState(() {})),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _rows.removeAt(i).amount.dispose()),
                    ),
                  ]),
                  if (ledger.funds[r.fundId]?.kind == FundKind.investment && investAccounts.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: r.accountId ?? investAccounts.first.id,
                      decoration: const InputDecoration(
                          labelText: 'Into investment', isDense: true, border: OutlineInputBorder()),
                      items: [
                        for (final a in investAccounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                      ],
                      onChanged: (v) => setState(() => r.accountId = v),
                    ),
                ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: targets.isEmpty
                    ? null
                    : () => setState(() => _rows.add(_Row(targets.first.id, null, 0))),
                icon: const Icon(Icons.add),
                label: const Text('Add a line'),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(spacing: 12, children: [
            Expanded(
              child: Text('Total ${formatTaka(_rows.fold<Poisha>(0, (t, r) => t + (parseTaka(r.amount.text) ?? 0)))}'),
            ),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ]),
        ),
      ),
    );
  }
}
