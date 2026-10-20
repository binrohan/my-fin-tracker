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
import '../entries/entries_screen.dart';

/// Countdown budgets (how much is left) and projects (how much it cost).
class TrackersScreen extends ConsumerWidget {
  const TrackersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trackers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editTracker(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New tracker'),
      ),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final active = ledger.activeTrackers();
          final countdowns = active.where((t) => t.tracker.kind == TrackerKind.countdown);
          final projects = active.where((t) => t.tracker.kind == TrackerKind.project);
          final archived = ledger.trackers.values.where((t) => t.archived);
          return PageList(
            children: [
              if (active.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'A countdown is a budget with an end date, like a trip: it shows what is left. '
                    'A project, like renovating a room, shows what it cost so far. '
                    'Tag expenses to them in quick add.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: status.muted),
                  ),
                ),
              if (countdowns.isNotEmpty) const Label('Countdown'),
              for (final t in countdowns) TrackerCard(status: t, today: today, ledger: ledger),
              if (projects.isNotEmpty) const Label('Projects'),
              for (final t in projects) TrackerCard(status: t, today: today, ledger: ledger),
              if (archived.isNotEmpty)
                SectionCard(
                  children: [
                    const Label('Finished'),
                    for (final t in archived)
                      InkWell(
                        onTap: () => openScreen(context, TrackerScreen(trackerId: t.id)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: AmountRow(t.name, ledger.trackerStatus(t).spent),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class TrackerCard extends StatelessWidget {
  const TrackerCard({super.key, required this.status, required this.today, required this.ledger});

  final TrackerStatus status;
  final DateTime today;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final t = status.tracker;
    final days = status.daysLeft(today);
    final left = status.left;
    final isCountdown = t.kind == TrackerKind.countdown;
    final over = left != null && left < 0;

    return SectionCard(
      onTap: () => openScreen(context, TrackerScreen(trackerId: t.id)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (days != null)
              StatusChip(
                days < 0
                    ? 'Ended'
                    : days == 0
                    ? 'Today'
                    : '$days days to go',
                tone: days < 0 ? ChipTone.plain : ChipTone.accent,
              )
            else
              StatusChip('Since ${DateFormat.yMMM().format(t.startDate)}'),
          ],
        ),
        if (isCountdown && left != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Money(
                  over ? -left : left,
                  color: over ? colors.bad : null,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              Text(over ? 'over budget' : 'left', style: TextStyle(color: colors.muted)),
            ],
          ),
          Bar(status.progress, color: over ? colors.bad : null),
          Text(
            '${formatTaka(status.spent)} spent of ${formatTaka(t.budget!)}',
            style: TextStyle(color: colors.muted),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Money(
                  status.spent,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              Text('spent so far', style: TextStyle(color: colors.muted)),
            ],
          ),
          if (left != null) ...[
            Bar(status.progress, color: over ? colors.bad : null),
            Text(
              over
                  ? '${formatTaka(-left)} over the ${formatTaka(t.budget!)} budget'
                  : '${formatTaka(left)} left of ${formatTaka(t.budget!)}',
              style: TextStyle(color: over ? colors.bad : colors.muted),
            ),
          ],
        ],
        if (status.entries.isNotEmpty)
          Text(
            'Last: ${entryTitle(ledger, status.entries.first)} · ${formatTaka(status.entries.first.amount)} · '
            '${DateFormat.MMMd().format(status.entries.first.date)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
      ],
    );
  }
}

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key, required this.trackerId});

  final int trackerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(
      builder: (context, ledger) {
        final t = ledger.trackers[trackerId];
        if (t == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Removed.')),
          );
        }
        final s = ledger.trackerStatus(t);
        final colors = StatusColors.of(context);
        final byCategory = s.byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return Scaffold(
          appBar: AppBar(
            title: Text(t.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => editTracker(context, ref, t),
              ),
            ],
          ),
          body: PageList(
            children: [
              TrackerCard(status: s, today: today, ledger: ledger),
              SectionCard(
                children: [
                  const Label('By category'),
                  if (t.openingSpent > 0) AmountRow('Before the app', t.openingSpent),
                  if (s.outsideTotal > 0) AmountRow('Outside your accounts', s.outsideTotal),
                  for (final e in byCategory)
                    AmountRow(ledger.categories[e.key]?.name ?? 'No category', e.value),
                  AmountRow('Total', s.spent, total: true),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Outside your accounts'),
                  Text(
                    'Money for this tracker that did not come from your accounts, such as '
                    'something paid by family. It counts here only: no balance, budget or '
                    'report changes.',
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                  for (final a in s.outside)
                    InkWell(
                      onTap: () => editTrackerAmount(context, ref, t, a),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AmountRow(
                          a.note.isEmpty ? 'Outside amount' : a.note,
                          a.amount,
                          detail: DateFormat.yMMMd().format(a.date),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => editTrackerAmount(context, ref, t, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add amount'),
                    ),
                  ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Expenses'),
                  if (s.entries.isEmpty)
                    Text(
                      'Nothing tagged yet. Choose this tracker in quick add, or open an entry and tag it.',
                      style: TextStyle(color: colors.muted),
                    ),
                  for (final e in s.entries)
                    InkWell(
                      onTap: () => showEntryDetails(context, e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AmountRow(
                          entryTitle(ledger, e),
                          e.amount,
                          detail: DateFormat.yMMMd().format(e.date),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> editTracker(BuildContext context, WidgetRef ref, Tracker? t) async {
  final name = TextEditingController(text: t?.name);
  var kind = t?.kind ?? TrackerKind.countdown;
  final budget = TextEditingController(text: amountText(t?.budget ?? 0));
  final before = TextEditingController(text: amountText(t?.openingSpent ?? 0));
  final today = ref.read(todayProvider);
  var start = t?.startDate ?? today;
  DateTime? end = t?.endDate;
  var archived = t?.archived ?? false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Widget date(String label, DateTime? v, ValueChanged<DateTime> set) => PickerField(
          label: label,
          value: v == null ? 'Not set' : DateFormat.yMMMd().format(v),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: v ?? today,
              firstDate: DateTime(2000),
              lastDate: DateTime(today.year + 20),
            );
            if (picked != null) setState(() => set(picked));
          },
        );
        final countdown = kind == TrackerKind.countdown;
        return SheetBody(
          title: t == null ? 'New tracker' : 'Edit ${t.name}',
          children: [
            SegmentedButton<TrackerKind>(
              segments: const [
                ButtonSegment(value: TrackerKind.countdown, label: Text('Countdown')),
                ButtonSegment(value: TrackerKind.project, label: Text('Project')),
              ],
              selected: {kind},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => kind = s.single),
            ),
            Text(
              countdown
                  ? 'A budget with an end date: shows what is left and the days to go.'
                  : 'Long-term spending: shows what it cost so far. A budget is optional.',
              style: TextStyle(color: StatusColors.of(context).muted),
            ),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: countdown ? 'e.g. Sylhet Trip' : 'e.g. Home Office Setup',
                border: const OutlineInputBorder(),
              ),
            ),
            AmountField(controller: budget, label: countdown ? 'Budget' : 'Budget (optional)'),
            Row(
              spacing: 8,
              children: [
                Expanded(child: date('Starts', start, (v) => start = v)),
                Expanded(child: date(countdown ? 'Ends' : 'Ends (optional)', end, (v) => end = v)),
              ],
            ),
            AmountField(controller: before, label: 'Already spent before the app (optional)'),
            if (t != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Finished'),
                subtitle: const Text('Hide from quick add and the active list'),
                value: archived,
                onChanged: (v) => setState(() => archived = v),
              ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    ),
  );
  if (ok != true || name.text.trim().isEmpty) return;
  final budgetValue = parseTaka(budget.text);
  final budgetOrNull = budgetValue == null || budgetValue <= 0 ? null : budgetValue;
  final repo = ref.read(repositoryProvider);
  if (t == null) {
    await repo.addTracker(
      name: name.text,
      kind: kind,
      startDate: start,
      endDate: end,
      budget: budgetOrNull,
      openingSpent: parseTaka(before.text) ?? 0,
    );
  } else {
    await repo.updateTracker(
      t.id,
      TrackersCompanion(
        name: Value(name.text.trim()),
        kind: Value(kind),
        budget: Value(budgetOrNull),
        startDate: Value(start),
        endDate: Value(end),
        openingSpent: Value(parseTaka(before.text) ?? 0),
        archived: Value(archived),
      ),
    );
  }
}

/// Add an amount from outside your accounts to [tracker], or change or
/// delete [existing].
Future<void> editTrackerAmount(
  BuildContext context,
  WidgetRef ref,
  Tracker tracker,
  TrackerAmount? existing,
) async {
  final amount = TextEditingController(text: amountText(existing?.amount ?? 0));
  final note = TextEditingController(text: existing?.note);
  DateTime date = existing?.date ?? ref.read(todayProvider);
  final repo = ref.read(repositoryProvider);

  final result = await showModalBottomSheet<String>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SheetBody(
        title: existing == null ? 'Add amount · ${tracker.name}' : 'Edit amount',
        children: [
          Text(
            'From outside your accounts. It adds to ${tracker.name} only.',
            style: TextStyle(color: StatusColors.of(context).muted, fontSize: 13),
          ),
          AmountField(controller: amount, label: 'Amount', autofocus: existing == null),
          TextField(
            controller: note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Paid by Abbu',
              border: OutlineInputBorder(),
            ),
          ),
          PickerField(
            label: 'Date',
            value: DateFormat.yMMMEd().format(date),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(date.year + 5),
              );
              if (picked != null) setState(() => date = picked);
            },
          ),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
          if (existing != null)
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: StatusColors.of(context).bad),
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Delete'),
            ),
        ],
      ),
    ),
  );
  if (result == 'delete' && existing != null) {
    await repo.deleteTrackerAmount(existing.id);
    return;
  }
  final value = parseTaka(amount.text) ?? 0;
  if (result != 'save' || value <= 0) return;
  if (existing == null) {
    await repo.addTrackerAmount(tracker.id, date, value, note: note.text);
  } else {
    await repo.updateTrackerAmount(existing.id, date, value, note: note.text);
  }
}
