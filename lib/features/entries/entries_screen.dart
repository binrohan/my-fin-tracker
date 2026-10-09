import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../buying/buying_screen.dart';
import '../loans/loans_screen.dart';
import '../quick_add/quick_add_sheet.dart';

/// Every entry in a month, newest first, grouped by day.
class EntriesScreen extends ConsumerStatefulWidget {
  const EntriesScreen({super.key, this.initial});

  final Period? initial;

  @override
  ConsumerState<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends ConsumerState<EntriesScreen> {
  late Period _period = widget.initial ?? Period.of(ref.read(todayProvider));

  @override
  Widget build(BuildContext context) {
    final current = Period.of(ref.watch(todayProvider));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entries'),
        actions: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _period = _period.previous),
          ),
          Center(child: Text(_period.shortLabel)),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right),
            onPressed: _period.compareTo(current) >= 0
                ? null
                : () => setState(() => _period = _period.next),
          ),
        ],
      ),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final entries = ledger.entries.where((e) => _period.contains(e.date)).toList();
          if (entries.isEmpty) {
            return Center(child: Text('No entries in ${_period.label}.'));
          }
          final byDay = <DateTime, List<Entry>>{};
          for (final e in entries) {
            byDay.putIfAbsent(e.date, () => []).add(e);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              for (final MapEntry(key: day, value: list) in byDay.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Label(DateFormat.MMMEd().format(day)),
                ),
                for (final e in list) EntryTile(ledger: ledger, entry: e),
              ],
            ],
          );
        },
      ),
    );
  }
}

String entryTitle(Ledger ledger, Entry e) {
  final category = ledger.categories[e.categoryId]?.name;
  if (e.note.isNotEmpty) return e.note;
  return switch (e.type) {
    EntryType.income || EntryType.expense => category ?? e.type.name,
    EntryType.move => 'Move',
    EntryType.opening => 'Starting balance',
    EntryType.adjust => 'Adjustment',
    EntryType.borrow => 'Borrowed',
    EntryType.repay => 'Repaid',
    EntryType.lend => 'Lent',
    EntryType.collect => 'Received back',
    EntryType.charge => 'Loan charge',
  };
}

/// The amount as it affects your money: − for expenses, + for income.
Poisha entrySigned(Ledger ledger, Entry e) => switch (e.type) {
  EntryType.expense => -e.amount,
  EntryType.income => e.amount,
  EntryType.move => 0,
  _ => ledger.postingsOf(e.id).fold(0, (t, p) => t + p.amount),
};

String entryDetail(Ledger ledger, Entry e) {
  final postings = ledger.postingsOf(e.id);
  final out = postings.where((p) => p.amount < 0).firstOrNull;
  final into = postings.where((p) => p.amount > 0).firstOrNull;
  String pot(PostingLine p) => potLabel(ledger, (account: p.accountId, fund: p.fundId));
  final category = ledger.categories[e.categoryId]?.name;
  return [
    if (e.note.isNotEmpty && category != null) category,
    if (out != null && into != null)
      '${pot(out)} → ${pot(into)}'
    else if (out != null)
      pot(out)
    else if (into != null)
      pot(into),
  ].join(' · ');
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.ledger, required this.entry});

  final Ledger ledger;
  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final signed = entrySigned(ledger, entry);
    final icon = switch (entry.type) {
      EntryType.expense => Icons.arrow_upward,
      EntryType.income => Icons.arrow_downward,
      EntryType.move => Icons.swap_horiz,
      _ => Icons.tune,
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: status.sunk,
        foregroundColor: status.muted,
        child: Icon(icon, size: 20),
      ),
      title: Text(entryTitle(ledger, entry), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(entryDetail(ledger, entry), maxLines: 1, overflow: TextOverflow.ellipsis),
      // Moves, and loans between your own pots, change no total: show the
      // amount in grey rather than a net of zero.
      trailing: entry.type == EntryType.move || signed == 0
          ? Money(entry.amount, color: status.muted)
          : Money(signed, showPlus: true, color: signed < 0 ? status.bad : status.good),
      onTap: () => showEntryDetails(context, entry),
    );
  }
}

/// What can happen to an entry from the details sheet.
bool _isLoanCreation(Entry e) =>
    e.loanId != null &&
    (e.type == EntryType.borrow ||
        e.type == EntryType.lend ||
        e.type == EntryType.charge ||
        e.type == EntryType.opening);

Future<void> showEntryDetails(BuildContext context, Entry entry) => showModalBottomSheet(
  useRootNavigator: true,
  context: context,
  showDragHandle: true,
  builder: (_) => Consumer(
    builder: (context, ref, _) {
      final ledger = ref.watch(ledgerProvider).value;
      if (ledger == null) return const SizedBox(height: 120);
      final repo = ref.read(repositoryProvider);
      final status = StatusColors.of(context);
      return SheetBody(
        title: entryTitle(ledger, entry),
        children: [
          AmountRow('Amount', entry.amount),
          Row(
            children: [
              const Expanded(child: Text('Date')),
              Text(DateFormat.yMMMEd().format(entry.date)),
            ],
          ),
          for (final p in ledger.postingsOf(entry.id))
            AmountRow(
              potLabel(ledger, (account: p.accountId, fund: p.fundId)),
              p.amount,
              signed: true,
            ),
          if (entry.type == EntryType.expense) ...[
            PickerField(
              label: 'Tracker',
              value: ledger.trackers[entry.trackerId]?.name ?? 'None',
              onTap: () async {
                final choice = await showDialog<int>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Count this expense in'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, -1),
                        child: const Text('No tracker'),
                      ),
                      for (final t in ledger.activeTrackers())
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, t.tracker.id),
                          child: Text(t.tracker.name),
                        ),
                    ],
                  ),
                );
                if (choice == null) return;
                await repo.setEntryTracker(entry.id, choice == -1 ? null : choice);
              },
            ),
            if (ledger.purchaseFor(entry.id) case final purchase?)
              OutlinedButton.icon(
                onPressed: () => editPurchase(context, ref, purchase),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text('In the Buying list: ${purchase.item}'),
              )
            else
              TextButton.icon(
                onPressed: () => repo.addPurchase(
                  item: entry.note.isNotEmpty
                      ? entry.note
                      : ledger.categories[entry.categoryId]?.name ?? 'Purchase',
                  date: entry.date,
                  amount: entry.amount,
                  entryId: entry.id,
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to the Buying list'),
              ),
          ],
          if (entry.loanId != null)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                openScreen(context, LoanScreen(loanId: entry.loanId!));
              },
              icon: const Icon(Icons.handshake_outlined),
              label: Text(_isLoanCreation(entry) ? 'Open the loan to change it' : 'Open the loan'),
            ),
          Row(
            spacing: 8,
            children: [
              if (canEditInQuickAdd(entry))
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(context);
                      showQuickAdd(context, editing: entry);
                    },
                    child: const Text('Edit'),
                  ),
                ),
              if (!_isLoanCreation(entry))
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: status.bad),
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        title: 'Delete this entry?',
                        body: 'Its amount will be removed from every balance.',
                        action: 'Delete',
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      await repo.deleteEntry(entry.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        showSnack(context, 'Entry deleted');
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  ),
);
