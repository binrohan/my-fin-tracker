import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/collapsible.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../cash/cash_screen.dart';
import '../../ledger/reminders.dart';
import '../investments/investments_screen.dart';
import '../loans/loans_screen.dart';
import '../more/backup_screen.dart';
import '../plan/record_income_sheet.dart';
import '../setup/starting_balances_screen.dart';
import '../sms/sms_screen.dart';
import '../spend/save_budget_sheet.dart';
import '../spend/spend_screen.dart';
import 'month_tasks.dart';

/// Which Home to show: [homeStandard] (left to spend) or [homeAfterBills]
/// (free to spend once fixed bills and slots are taken off).
const homeStyleSetting = 'home_style';
const homeStandard = 'standard';
const homeAfterBills = 'after_bills';

/// Home sections folded away, by id, comma-separated.
const homeCollapsedSetting = 'home_collapsed';

/// Folded sections and how to fold or open one.
class _Fold {
  _Fold(this.closed, this.toggle);

  final Set<String> closed;
  final void Function(String id) toggle;

  bool call(String id) => closed.contains(id);
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(
      builder: (context, ledger) {
        final period = Period.of(today);
        final header = ScreenHeader(
          period.label,
          subtitle: 'Day ${today.day} of ${period.daysInMonth}',
          trailing: ledger.isBalanced
              ? const StatusChip('Balanced', tone: ChipTone.good, icon: Icons.check)
              : const StatusChip('Not balanced', tone: ChipTone.bad),
        );
        if (ledger.isEmpty) return PageList(children: [header, const _EmptyHome()]);

        final closed = {
          for (final id in (ledger.settings[homeCollapsedSetting] ?? '').split(','))
            if (id.isNotEmpty) id,
        };
        final fold = _Fold(closed, (id) {
          final next = {...closed};
          if (!next.remove(id)) next.add(id);
          ref.read(repositoryProvider).setSetting(homeCollapsedSetting, next.join(','));
        });
        final afterBills = ledger.settings[homeStyleSetting] == homeAfterBills;

        final s = ledger.summary(period);
        final toClose = ledger.monthToClose(today);
        // The Bills card lists bills on this Home; don't repeat them.
        final reminders = remindersFor(
          ledger,
          today,
        ).where((r) => !afterBills || r.kind != ReminderKind.bill).toList();
        final sms = ref.watch(smsSuggestionsProvider);
        final attention = reminders.isNotEmpty || sms.isNotEmpty
            ? _NeedsAttention(
                ledger: ledger,
                reminders: reminders,
                messages: sms.length,
                fold: fold,
                today: today,
              )
            : null;
        final ready = ledger.heldForNextMonth > 0
            ? CollapsibleCard(
                title: 'Ready for ${period.next.label}',
                collapsed: fold('ready'),
                onToggle: () => fold.toggle('ready'),
                summary: Money(ledger.heldForNextMonth),
                color: Theme.of(context).colorScheme.primaryContainer,
                children: [
                  Money(
                    ledger.heldForNextMonth,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Held apart; it becomes spending money on 1 ${period.next.label.split(' ').first}.',
                    style: TextStyle(color: StatusColors.of(context).muted, fontSize: 13),
                  ),
                ],
              )
            : null;

        return PageList(
          children: [
            header,
            if (toClose != null) _CloseMonthBanner(period: toClose),
            if (afterBills) ...[
              _FreeToSpend(ledger: ledger, summary: s, today: today),
              _BillsToPay(ledger: ledger, period: period, fold: fold),
              ?attention,
              ?ready,
            ] else ...[
              ?attention,
              ?ready,
              _LeftToSpend(summary: s, today: today),
            ],
            _ThisMonth(ledger: ledger, summary: s, fold: fold),
            _WhereAndWhat(ledger: ledger, fold: fold),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AmountRow('Net worth', ledger.netWorth(), detail: 'incl. investments & loans'),
            ),
          ],
        );
      },
    );
  }
}

/// The "After bills" main card: what is free once the fixed bills still to
/// pay and money kept in slots are taken off, with the sum shown.
class _FreeToSpend extends StatelessWidget {
  const _FreeToSpend({required this.ledger, required this.summary, required this.today});

  final Ledger ledger;
  final PeriodSummary summary;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    final period = summary.period;
    final bills = ledger.unpaidFixedBills(period).fold<Poisha>(0, (t, b) => t + b.remaining);
    final slots = ledger.slotsIn(period).fold<Poisha>(0, (t, s) => t + (s.left > 0 ? s.left : 0));
    final free = summary.leftToSpend - bills - slots;
    final daysLeft = period.daysInMonth - today.day + 1;
    final perDay = free > 0 && period.contains(today)
        ? (free / daysLeft / poishaPerTaka).round() * poishaPerTaka
        : null;

    Widget line(String label, Poisha amount, {bool total = false}) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: on, fontWeight: total ? FontWeight.w700 : null),
          ),
        ),
        Money(
          amount,
          color: on,
          style: TextStyle(fontWeight: total ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );

    return SectionCard(
      color: scheme.primary,
      children: [
        Label(free >= 0 ? 'Free to spend' : 'Short after bills', color: on.withValues(alpha: .8)),
        Money(
          free.abs(),
          color: on,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.05),
        ),
        if (perDay != null)
          Text('≈ ${formatTaka(perDay)} a day for $daysLeft days', style: TextStyle(color: on)),
        if (free < 0)
          Text(
            'Bills still to pay are more than what is left to spend.',
            style: TextStyle(color: on),
          ),
        Divider(color: on.withValues(alpha: .3)),
        line('Left to spend', summary.leftToSpend),
        line('Bills still to pay', -bills),
        if (slots > 0) line('Kept in slots', -slots),
        Divider(color: on.withValues(alpha: .3), height: 4),
        line('Free to spend', free, total: true),
      ],
    );
  }
}

/// Fixed bills not yet paid this month, with Pay all.
class _BillsToPay extends ConsumerWidget {
  const _BillsToPay({required this.ledger, required this.period, required this.fold});

  final Ledger ledger;
  final Period period;
  final _Fold fold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = StatusColors.of(context);
    final today = ref.watch(todayProvider);
    final bills = ledger.unpaidFixedBills(period);
    final total = bills.fold<Poisha>(0, (t, b) => t + b.remaining);
    return CollapsibleCard(
      title: 'Bills to pay',
      collapsed: fold('bills'),
      onToggle: () => fold.toggle('bills'),
      summary: bills.isEmpty ? const Text('All paid') : Money(total),
      children: [
        if (bills.isEmpty)
          Text('Every fixed bill is paid this month.', style: TextStyle(color: status.good)),
        for (final b in bills)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            // Linked to a pot (e.g. Rice Bag): save it there instead.
            onTap: b.category.savingsFundId == null
                ? null
                : () => showSaveBudgetSheet(context, period, categoryId: b.category.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(child: Text(b.category.name)),
                  if (b.category.dueDay case final due?)
                    () {
                      final date = DateTime(
                        period.year,
                        period.month,
                        due.clamp(1, period.daysInMonth),
                      );
                      final days = date.difference(today).inDays;
                      return StatusChip(
                        days < 0
                            ? 'overdue'
                            : days == 0
                            ? 'today'
                            : 'due ${date.day} ${DateFormat.MMM().format(date)}',
                        tone: days <= 0 ? ChipTone.bad : ChipTone.warn,
                      );
                    }(),
                  Money(b.remaining, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        if (bills.isNotEmpty)
          FilledButton.tonal(
            onPressed: () => showPayBills(context, ref, ledger, bills),
            child: Text('Pay all · ${formatTaka(total)}'),
          ),
      ],
    );
  }
}

class _LeftToSpend extends StatelessWidget {
  const _LeftToSpend({required this.summary, required this.today});

  final PeriodSummary summary;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    final s = summary;
    final perDay = s.perDay(today);
    final daysLeft = s.period.daysInMonth - today.day + 1;
    final planned = s.leftToSpend <= 0 ? 1.0 : s.budgetLeft / s.leftToSpend;

    return SectionCard(
      color: scheme.primary,
      children: [
        Label('Left to spend', color: on.withValues(alpha: .8)),
        Money(
          s.leftToSpend,
          color: on,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.05),
        ),
        if (perDay != null && perDay > 0)
          Text('≈ ${formatTaka(perDay)} a day for $daysLeft days', style: TextStyle(color: on)),
        Bar(planned, color: on, height: 6),
        DefaultTextStyle.merge(
          style: TextStyle(color: on, fontSize: 13),
          child: Row(
            children: [
              Expanded(child: Text('Budgeted ${formatTaka(s.budgetLeft)}')),
              Text(
                s.unplanned >= 0
                    ? 'Unplanned ${formatTaka(s.unplanned)}'
                    : 'Short ${formatTaka(-s.unplanned)}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThisMonth extends StatelessWidget {
  const _ThisMonth({required this.ledger, required this.summary, required this.fold});

  final Ledger ledger;
  final PeriodSummary summary;
  final _Fold fold;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final heldByCategory = <int, Poisha>{};
    for (final e in ledger.heldIncomes(summary.period)) {
      if (e.categoryId != null) {
        heldByCategory.update(e.categoryId!, (v) => v + e.amount, ifAbsent: () => e.amount);
      }
    }
    final income = ledger.categoryLines(s.period, CategoryKind.income).where((l) => l.actual != 0);
    return CollapsibleCard(
      title: 'This month',
      collapsed: fold('month'),
      onToggle: () => fold.toggle('month'),
      summary: Money(s.leftToSpend),
      children: [
        AmountRow('Carried forward', s.carriedForward),
        if (s.released != 0)
          AmountRow(
            'Income for ${s.period.label.split(' ').first}',
            s.released,
            detail: 'received last month',
            signed: true,
          ),
        // Income held for next month is not part of this month's flow.
        for (final line in income)
          if (line.actual - (heldByCategory[line.category.id] ?? 0) != 0)
            AmountRow(
              line.category.name,
              line.actual - (heldByCategory[line.category.id] ?? 0),
              signed: true,
            ),
        if (s.setAside != 0)
          AmountRow('Set aside', -s.setAside, detail: 'savings, goals, DPS', signed: true),
        AmountRow('Spent', -s.spendingExpenses, signed: true),
        if (s.loanNet != 0)
          AmountRow(s.loanNet > 0 ? 'Borrowed' : 'Loan repayment', s.loanNet, signed: true),
        if (s.startingNet != 0) AmountRow('Starting balance', s.startingNet, signed: true),
        if (s.adjustNet != 0) AmountRow('Adjustments', s.adjustNet, signed: true),
        AmountRow('Left to spend', s.leftToSpend, total: true),
      ],
    );
  }
}

class _WhereAndWhat extends StatelessWidget {
  const _WhereAndWhat({required this.ledger, required this.fold});

  final Ledger ledger;
  final _Fold fold;

  @override
  Widget build(BuildContext context) {
    final liquid = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived);
    final goals = ledger
        .fundsOfKind(FundKind.goal)
        .fold<Poisha>(0, (t, f) => t + ledger.fundBalance(f.id));
    final total = ledger.liquidTotal();

    // Stacked, not side by side: at phone width with Android's font sizes
    // two half-width cards wrap names like "Spending".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        CollapsibleCard(
          title: 'Where it is',
          collapsed: fold('where'),
          onToggle: () => fold.toggle('where'),
          summary: Money(total),
          children: [
            for (final a in liquid) AmountRow(a.name, ledger.accountBalance(a.id)),
            AmountRow('Total', total, total: true),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => showMatchBalance(context),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Match balance'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => openScreen(context, const CashScreen()),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Cash drawer'),
                ),
              ],
            ),
          ],
        ),
        CollapsibleCard(
          title: "What it's for",
          collapsed: fold('what'),
          onToggle: () => fold.toggle('what'),
          summary: Money(total),
          children: [
            AmountRow('Spending', ledger.fundBalance(ledger.spendingFund.id)),
            for (final f in ledger.fundsOfKind(FundKind.savings))
              AmountRow(f.name, ledger.fundBalance(f.id)),
            if (goals != 0) AmountRow('Goals', goals),
            if (ledger.heldForNextMonth != 0) AmountRow('For next month', ledger.heldForNextMonth),
            AmountRow('Total', total, total: true),
          ],
        ),
      ],
    );
  }
}

class _CloseMonthBanner extends StatelessWidget {
  const _CloseMonthBanner({required this.period});

  final Period period;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    return SectionCard(
      color: status.warnSoft,
      children: [
        Text(
          '${period.label} is over',
          style: TextStyle(fontWeight: FontWeight.w700, color: status.warn),
        ),
        Text(
          'Check the bank balance and decide what happens to the leftover.',
          style: TextStyle(color: status.warn),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: () => showCloseMonth(context, period),
            child: Text('Close ${period.label}'),
          ),
        ),
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) => SectionCard(
    children: [
      Text('Welcome', style: Theme.of(context).textTheme.titleMedium),
      Text(
        'Start by entering what you have today: your bank, cash and bKash balances, and '
        'how much of it is savings. Then add expenses with the + button.',
        style: TextStyle(color: StatusColors.of(context).muted),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: () => openScreen(context, const StartingBalancesScreen()),
            child: const Text('Enter starting balances'),
          ),
          OutlinedButton(
            onPressed: () => context.go('/more'),
            child: const Text('Try the example first'),
          ),
        ],
      ),
    ],
  );
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({
    required this.ledger,
    required this.reminders,
    required this.fold,
    required this.today,
    this.messages = 0,
  });

  final Ledger ledger;
  final DateTime today;
  final List<Reminder> reminders;
  final _Fold fold;

  /// Bank and bKash messages waiting to be added.
  final int messages;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    void open(Reminder r) => switch (r.kind) {
      ReminderKind.income => showRecordIncome(
        context,
        ledger.planFor(Period.of(today)).incomes.firstWhere((i) => i.categoryId == r.id),
      ),
      ReminderKind.bill || ReminderKind.slot => context.go('/spend'),
      ReminderKind.loanOverdue ||
      ReminderKind.loanLong => openScreen(context, LoanScreen(loanId: r.id!)),
      ReminderKind.maturity => openScreen(context, InvestmentScreen(accountId: r.id!)),
      ReminderKind.backup => openScreen(context, const BackupScreen()),
    };
    IconData icon(ReminderKind k) => switch (k) {
      ReminderKind.income => Icons.savings_outlined,
      ReminderKind.bill => Icons.receipt_long_outlined,
      ReminderKind.slot => Icons.event_outlined,
      ReminderKind.loanOverdue || ReminderKind.loanLong => Icons.handshake_outlined,
      ReminderKind.maturity => Icons.trending_up,
      ReminderKind.backup => Icons.backup_outlined,
    };
    Widget row({
      required IconData icon,
      required Color color,
      required String title,
      required String detail,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          spacing: 12,
          children: [
            Icon(icon, color: color),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(detail, style: TextStyle(color: status.muted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );

    final count = reminders.length + (messages > 0 ? 1 : 0);
    return CollapsibleCard(
      title: 'Needs attention',
      collapsed: fold('attention'),
      onToggle: () => fold.toggle('attention'),
      summary: Text('$count'),
      children: [
        if (messages > 0)
          row(
            icon: Icons.sms_outlined,
            color: status.warn,
            title: messages == 1 ? '1 bank message to add' : '$messages bank messages to add',
            detail: 'Check each one and save it as an entry',
            onTap: () => openScreen(context, const SmsScreen()),
          ),
        for (final r in reminders)
          row(
            icon: icon(r.kind),
            color: r.urgent ? status.bad : status.warn,
            title: r.title,
            detail: r.detail,
            onTap: () => open(r),
          ),
      ],
    );
  }
}
