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
      trailing: entry.type == EntryType.move
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
          if (_isLoanCreation(entry))
            Text(
              'Loans are changed from the Loans screen (coming in Phase 3).',
              style: TextStyle(color: status.muted),
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
