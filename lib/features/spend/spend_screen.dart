import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/widgets.dart';

class SpendScreen extends ConsumerWidget {
  const SpendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = Period.of(ref.watch(todayProvider));
    return LedgerBuilder(builder: (context, ledger) {
      final s = ledger.summary(period);
      final lines = ledger.categoryLines(period, CategoryKind.expense);
      final recent = ledger.entries
          .where((e) => e.type == EntryType.expense && period.contains(e.date))
          .take(10);
      final status = StatusColors.of(context);

      return PageList(children: [
        ScreenHeader('Expenses', subtitle: period.label),
        SectionCard(children: [
          Row(children: [
            const Expanded(child: Label('Spent of budget')),
            if (s.budget > 0)
              Text('${(s.expenses / s.budget * 100).round()}%',
                  style: TextStyle(color: status.muted)),
          ]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Money(s.expenses,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              Text('of ${formatTaka(s.budget)}', style: TextStyle(color: status.muted)),
            ],
          ),
          Bar(s.budget == 0 ? 0 : s.expenses / s.budget),
        ]),
        SectionCard(children: [
          for (final (i, line) in lines.indexed) ...[
            if (i > 0) const Divider(),
            _CategoryTile(line: line, period: period),
          ],
        ]),
        if (recent.isNotEmpty)
          SectionCard(children: [
            const Label('Recent'),
            for (final e in recent)
              AmountRow(
                e.note.isEmpty ? ledger.categories[e.categoryId]?.name ?? 'Expense' : e.note,
                -e.amount,
                detail: [
                  if (e.note.isNotEmpty) ledger.categories[e.categoryId]?.name,
                  DateFormat.MMMd().format(e.date),
                ].whereType<String>().join(' · '),
              ),
          ]),
      ]);
    });
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.line, required this.period});

  final CategoryLine line;
  final Period period;

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
          child: Text(line.category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Money(line.actual,
            color: line.isOver ? status.bad : null,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        if (line.budget > 0)
          Text(' / ${formatTaka(line.budget, symbol: false)}',
              style: TextStyle(color: status.muted)),
      ],
    );
    final bar = Bar(line.usage, color: barColor(line));

    if (line.children.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: [title, bar]);
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
        title: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: [title, bar]),
        initiallyExpanded: true,
        children: [
          for (final child in line.children) _SubCategoryRow(line: child, period: period),
        ],
      ),
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
              ? StatusChip('due ${c.dueDay} ${DateFormat.MMM().format(period.start)}',
                  tone: ChipTone.warn)
              : null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(spacing: 8, children: [
        Expanded(child: Text(c.name)),
        ?chip,
        Money(line.actual == 0 ? line.budget : line.actual,
            color: line.actual == 0 ? status.muted : (line.isOver ? status.bad : null)),
      ]),
    );
  }
}
