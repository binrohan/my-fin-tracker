import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/database.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

/// Major purchases by year, for the annual report.
class BuyingScreen extends ConsumerStatefulWidget {
  const BuyingScreen({super.key});

  @override
  ConsumerState<BuyingScreen> createState() => _BuyingScreenState();
}

class _BuyingScreenState extends ConsumerState<BuyingScreen> {
  late int _year = ref.read(todayProvider).year;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buying'),
        actions: [
          IconButton(
            tooltip: 'Previous year',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Center(child: Text('$_year')),
          IconButton(
            tooltip: 'Next year',
            icon: const Icon(Icons.chevron_right),
            onPressed: _year >= today.year ? null : () => setState(() => _year++),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editPurchase(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add purchase'),
      ),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final list = ledger.purchasesIn(_year);
          final total = list.fold<Poisha>(0, (t, p) => t + p.amount);
          return PageList(
            children: [
              SectionCard(
                children: [
                  Label('Major purchases in $_year'),
                  Money(total, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  Text('${list.length} ${list.length == 1 ? 'item' : 'items'}'),
                ],
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Turn on "Major purchase" in quick add, or use "Buy it" on a goal. '
                    'You can also add one here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: status.muted),
                  ),
                ),
              for (final p in list)
                SectionCard(
                  onTap: () => editPurchase(context, ref, p),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.item,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        Money(p.amount, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text(
                      [
                        DateFormat.yMMMd().format(p.date),
                        if (p.shop.isNotEmpty) p.shop,
                      ].join(' · '),
                      style: TextStyle(color: status.muted),
                    ),
                    if (p.warrantyUntil != null)
                      _WarrantyChip(until: p.warrantyUntil!, today: today),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WarrantyChip extends StatelessWidget {
  const _WarrantyChip({required this.until, required this.today});

  final DateTime until;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = until.difference(today).inDays;
    final date = DateFormat.yMMM().format(until);
    final (text, tone) = days < 0
        ? ('Warranty ended $date', ChipTone.plain)
        : days <= 60
        ? ('Warranty ends in $days days', ChipTone.warn)
        : ('Warranty until $date', ChipTone.good);
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusChip(text, tone: tone),
    );
  }
}

/// Add a purchase record, or edit one. A record linked to an expense keeps
/// the expense's amount and date.
Future<void> editPurchase(BuildContext context, WidgetRef ref, Purchase? p) async {
  final item = TextEditingController(text: p?.item);
  final amount = TextEditingController(text: amountText(p?.amount ?? 0));
  final shop = TextEditingController(text: p?.shop);
  final note = TextEditingController(text: p?.note);
  final DateTime today = ref.read(todayProvider);
  DateTime date = p?.date ?? today;
  DateTime? warranty = p?.warrantyUntil;
  final linked = p?.entryId != null;

  final result = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SheetBody(
        title: p == null ? 'Add purchase' : 'Purchase',
        children: [
          TextField(
            controller: item,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Item', border: OutlineInputBorder()),
          ),
          if (linked)
            Text(
              'Paid through an expense: ${formatTaka(p!.amount)} on ${DateFormat.yMMMd().format(p.date)}.',
              style: TextStyle(color: StatusColors.of(context).muted),
            )
          else ...[
            AmountField(controller: amount, label: 'Price'),
            PickerField(
              label: 'Bought on',
              value: DateFormat.yMMMd().format(date),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
          ],
          TextField(
            controller: shop,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Shop (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          PickerField(
            label: 'Warranty until (optional)',
            value: warranty == null ? 'No warranty' : DateFormat.yMMMd().format(warranty!),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: warranty ?? DateTime(date.year + 1, date.month, date.day),
                firstDate: date,
                lastDate: DateTime(date.year + 15),
              );
              if (picked != null) setState(() => warranty = picked);
            },
          ),
          TextField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          Row(
            spacing: 8,
            children: [
              if (p != null)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: StatusColors.of(context).bad),
                    onPressed: () => Navigator.pop(context, 'delete'),
                    child: const Text('Remove from list'),
                  ),
                ),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, 'save'),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  final repo = ref.read(repositoryProvider);
  if (result == 'delete' && p != null) {
    await repo.deletePurchase(p.id);
    if (context.mounted) showSnack(context, 'Removed from the Buying list; the expense stays');
    return;
  }
  if (result != 'save' || item.text.trim().isEmpty) return;
  if (p == null) {
    final price = parseTaka(amount.text) ?? 0;
    if (price <= 0) return;
    await repo.addPurchase(
      item: item.text,
      date: date,
      amount: price,
      shop: shop.text,
      warrantyUntil: warranty,
      note: note.text.trim(),
    );
  } else {
    await repo.updatePurchase(
      p.id,
      PurchasesCompanion(
        item: Value(item.text.trim()),
        shop: Value(shop.text.trim()),
        warrantyUntil: Value(warranty),
        note: Value(note.text.trim()),
        amount: linked ? const Value.absent() : Value(parseTaka(amount.text) ?? p.amount),
        date: linked ? const Value.absent() : Value(date),
      ),
    );
  }
}
