import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/insights.dart';
import '../../ledger/ledger.dart';
import '../../data/ledger_repository.dart';
import '../../ui/charts.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import 'slots.dart';
import '../entries/entries_screen.dart';
import '../plan/monthly_plan_screen.dart';

class SpendScreen extends ConsumerWidget {
  const SpendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final period = Period.of(today);
    return LedgerBuilder(
      builder: (context, ledger) {
        final s = ledger.summary(period);
        final compared = ledger.settings[insightsOffSetting] == 'true'
            ? null
            : compareMonths(ledger, period, today: today);
        final lines = ledger.categoryLines(period, CategoryKind.expense);
        final recent = ledger.entries
            .where((e) => e.type == EntryType.expense && period.contains(e.date))
            .take(10);
        final status = StatusColors.of(context);

        final bills = ledger.unpaidFixedBills(period);
        final history = <MonthBar>[
          for (
            var p = Period.of(DateTime(period.year, period.month - 5));
            p.compareTo(period) <= 0;
            p = p.next
          )
            if (ledger.entries.any((e) => p.contains(e.date) && e.type != EntryType.opening))
              () {
                final s = ledger.summary(p);
                return (
                  label: DateFormat.MMM().format(p.start),
                  actual: s.expenses,
                  budget: s.budget,
                  current: p == period,
                );
              }(),
        ];
        final billsTotal = bills.fold<Poisha>(0, (t, b) => t + b.remaining);
        return PageList(
          children: [
            ScreenHeader(
              'Expenses',
              subtitle: period.label,
              trailing: OutlinedButton.icon(
                onPressed: () => openScreen(context, const MonthlyPlanScreen(initialTab: 2)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Budgets'),
              ),
            ),
            SectionCard(
              children: [
                Row(
                  children: [
                    const Expanded(child: Label('Spent of budget')),
                    if (s.budget > 0)
                      Text(
                        '${(s.expenses / s.budget * 100).round()}%',
                        style: TextStyle(color: status.muted),
                      ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Money(
                        s.expenses,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('of ${formatTaka(s.budget)}', style: TextStyle(color: status.muted)),
                  ],
                ),
                Bar(s.budget == 0 ? 0 : s.expenses / s.budget),
              ],
            ),
            SectionCard(
              children: [
                for (final (i, line) in lines.indexed) ...[
                  if (i > 0) const Divider(),
                  _CategoryTile(
                    line: line,
                    period: period,
                    change: compared?.changes[line.category.id],
                  ),
                ],
              ],
            ),
            if (compared != null) ComparisonCard(compared: compared),
            if (history.length > 1)
              SectionCard(
                children: [
                  const Label('Last 6 months'),
                  MonthBars(bars: history),
                ],
              ),
            SlotsCard(ledger: ledger, period: period),
            if (bills.isNotEmpty)
              FilledButton.tonal(
                onPressed: () => _payBills(context, ref, ledger, bills),
                child: Text(
                  'Pay ${bills.length} remaining fixed '
                  '${bills.length == 1 ? 'bill' : 'bills'} · ${formatTaka(billsTotal)}',
                ),
              ),
            if (recent.isNotEmpty)
              SectionCard(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Label('Recent')),
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => openScreen(context, EntriesScreen(initial: period)),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  for (final e in recent)
                    InkWell(
                      onTap: () => showEntryDetails(context, e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AmountRow(
                          entryTitle(ledger, e),
                          -e.amount,
                          detail: [
                            if (e.note.isNotEmpty) ledger.categories[e.categoryId]?.name,
                            DateFormat.MMMd().format(e.date),
                          ].whereType<String>().join(' · '),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.line, required this.period, this.change});

  final CategoryLine line;
  final Period period;
  final CategoryChange? change;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    Color barColor(CategoryLine l) => l.isOver
        ? status.bad
        : l.usage >= .9
        ? status.warn
        : Theme.of(context).colorScheme.primary;

    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: line.category.name,
              children: [
                if (line.category.slotYear != null)
                  TextSpan(
                    text: line.category.dueDay == null
                        ? '  slot'
                        : '  slot · ${line.category.dueDay} ${DateFormat.MMM().format(period.start)}',
                    style: TextStyle(
                      color: status.muted,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Money(
          line.actual,
          color: line.isOver ? status.bad : null,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (line.budget > 0)
          Text(
            ' / ${formatTaka(line.budget, symbol: false)}',
            style: TextStyle(color: status.muted),
          ),
      ],
    );
    final bar = Bar(line.usage, color: barColor(line));
    final c = change;
    final head = [
      title,
      bar,
      if (c != null && c.isNotable)
        Text(
          '${changeLabel(c.diff, c.share)} vs ${DateFormat.MMM().format(period.previous.start)}',
          style: TextStyle(fontSize: 12, color: c.diff > 0 ? status.warn : status.good),
        ),
    ];

    if (line.children.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: head);
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
        title: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: head),
        initiallyExpanded: true,
        children: [for (final child in line.children) _SubCategoryRow(line: child, period: period)],
      ),
    );
  }
}

/// This month's spending against last month's, so far.
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key, required this.compared});

  final MonthComparison compared;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = compared;
    final month = DateFormat.MMM();
    final prev = c.previous;
    final rises = c.rises();
    final falls = c.falls();
    Widget line(CategoryChange x) => Row(
      spacing: 8,
      children: [
        Expanded(child: Text(x.category.name)),
        Text(
          '${formatTaka(x.diff, showPlus: true)}  ${changeLabel(x.diff, x.share)}',
          style: TextStyle(color: x.diff > 0 ? status.warn : status.good),
        ),
      ],
    );
    return SectionCard(
      children: [
        Label('Compared with ${DateFormat.MMMM().format(prev.start)}'),
        if (c.throughDay != null)
          Text(
            '1–${c.throughDay} ${month.format(c.period.start)} against '
            '1–${c.throughDay! > prev.daysInMonth ? prev.daysInMonth : c.throughDay} '
            '${month.format(prev.start)}',
            style: TextStyle(color: status.muted, fontSize: 13),
          ),
        AmountRow('This month', c.now),
        AmountRow('Last month', c.before),
        Row(
          children: [
            const Expanded(
              child: Text('Change', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text(
              '${formatTaka(c.diff, showPlus: true)}'
              '${c.share == null ? '' : '  ${changeLabel(c.diff, c.share)}'}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: c.diff > 0 ? status.warn : status.good,
              ),
            ),
          ],
        ),
        if (rises.isNotEmpty || falls.isNotEmpty) const Divider(),
        if (rises.isNotEmpty) Text('Spending more on', style: TextStyle(color: status.muted)),
        for (final x in rises) line(x),
        if (falls.isNotEmpty) Text('Spending less on', style: TextStyle(color: status.muted)),
        for (final x in falls) line(x),
        if (rises.isEmpty && falls.isEmpty)
          Text('No category changed by much.', style: TextStyle(color: status.muted, fontSize: 13)),
      ],
    );
  }
}

class _SubCategoryRow extends StatelessWidget {
  const _SubCategoryRow({required this.line, required this.period});

  final CategoryLine line;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = line.category;
    final paid = line.budget > 0 && line.actual >= line.budget;
    Widget? chip;
    if (c.isFixed && line.budget > 0) {
      chip = paid
          ? const StatusChip('paid', tone: ChipTone.good)
          : c.dueDay != null
          ? StatusChip(
              'due ${c.dueDay} ${DateFormat.MMM().format(period.start)}',
              tone: ChipTone.warn,
            )
          : null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        spacing: 8,
        children: [
          Expanded(child: Text(c.name)),
          ?chip,
          Money(
            line.actual == 0 ? line.budget : line.actual,
            color: line.actual == 0 ? status.muted : (line.isOver ? status.bad : null),
          ),
        ],
      ),
    );
  }
}

Future<void> _payBills(
  BuildContext context,
  WidgetRef ref,
  Ledger ledger,
  List<CategoryLine> bills,
) async {
  final bank = defaultAccount(ledger, AccountType.bank);
  Pot from = (account: bank.id, fund: ledger.spendingFund.id);
  final total = bills.fold<Poisha>(0, (t, b) => t + b.remaining);
  final ok = await showModalBottomSheet<bool>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SheetBody(
        title: 'Pay fixed bills',
        children: [
          for (final b in bills) AmountRow(b.category.name, b.remaining),
          AmountRow('Total', total, total: true),
          PickerField(
            label: 'Paid from',
            value: potLabel(ledger, from),
            onTap: () async {
              final picked = await pickPot(context, ledger, title: 'Paid from', initial: from);
              if (picked != null) setState(() => from = picked);
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Pay ${formatTaka(total)} today'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return;
  await ref
      .read(repositoryProvider)
      .payBills(
        [for (final b in bills) (categoryId: b.category.id, amount: b.remaining)],
        ref.read(todayProvider),
        from,
      );
  if (context.mounted) showSnack(context, '${bills.length} bills paid');
}
