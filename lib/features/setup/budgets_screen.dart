import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// Monthly budget for each category. A budget applies to the chosen month
/// and every month after it until you change it.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  final _fields = <int, TextEditingController>{};
  Map<int, Poisha> _original = {};
  late final Period _period = Period.of(ref.read(todayProvider));

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(int categoryId) => _fields.putIfAbsent(
    categoryId,
    () => TextEditingController(text: amountText(_original[categoryId] ?? 0)),
  );

  @override
  void initState() {
    super.initState();
    final ledger = ref.read(ledgerProvider).value;
    if (ledger != null) _original = ledger.budgetsFor(_period);
  }

  /// Typed values where a field exists, saved budgets elsewhere. Parents
  /// are skipped: their budget is the sum of their sub-categories.
  Poisha _total(Ledger? ledger) {
    if (ledger == null) return 0;
    return ledger.leafCategories(CategoryKind.expense).fold(0, (t, c) {
      final field = _fields[c.id];
      return t + (field != null ? parseTaka(field.text) ?? 0 : _original[c.id] ?? 0);
    });
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    var changed = 0;
    for (final MapEntry(key: id, value: c) in _fields.entries) {
      final amount = parseTaka(c.text) ?? 0;
      if (amount != (_original[id] ?? 0)) {
        await repo.setBudget(_period, id, amount);
        changed++;
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, changed == 0 ? 'No changes' : 'Budgets saved from ${_period.label}');
  }

  String _groupOf(Ledger ledger, CategoryRow c) =>
      c.parentId == null ? 'Everyday' : ledger.categories[c.parentId]!.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          if (_original.isEmpty) _original = ledger.budgetsFor(_period);
          final leaves = ledger.leafCategories(CategoryKind.expense);
          final status = StatusColors.of(context);
          String? lastGroup;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Text(
                'Applies to ${_period.label} and later months until you change it. '
                'Leave a category empty for no budget.',
                style: TextStyle(color: status.muted),
              ),
              const SizedBox(height: 8),
              for (final c in leaves) ...[
                if (_groupOf(ledger, c) != lastGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: Label(lastGroup = _groupOf(ledger, c)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(child: Text(c.name)),
                      SizedBox(
                        width: 150,
                        child: AmountField(
                          controller: _field(c.id),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
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
                child: Text('Total ${formatTaka(_total(ref.watch(ledgerProvider).value))} a month'),
              ),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
