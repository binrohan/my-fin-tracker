import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../ledger/enums.dart';
import '../../ledger/free_to_spend.dart';
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
import '../entries/entries_screen.dart';
import '../spend/slots.dart';
import 'money_details_screen.dart';
import 'month_tasks.dart';

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
        final s = ledger.summary(period);
        final toClose = ledger.monthToClose(today);
        // Bills have their own card below; don't repeat them here.
        final reminders = remindersFor(
          ledger,
          today,
        ).where((r) => r.kind != ReminderKind.bill).toList();
        final sms = ref.watch(smsSuggestionsProvider);

        return PageList(
          children: [
            header,
            // Most important first: the month's number, then what needs
            // doing, then what happened, then the overview.
            if (toClose != null) _CloseMonthBanner(period: toClose),
            _MainCard(ledger: ledger, summary: s, today: today, fold: fold),
            if (reminders.isNotEmpty || sms.isNotEmpty)
              _NeedsAttention(
                ledger: ledger,
                reminders: reminders,
                messages: sms.length,
                fold: fold,
                today: today,
              ),
            _BillsToPay(ledger: ledger, period: period, fold: fold),
            _History(ledger: ledger, fold: fold),
            _WhereItIs(ledger: ledger, fold: fold),
            _WhatItsFor(ledger: ledger, summary: s),
          ],
        );
      },
    );
  }
}

/// The last five entries, with See all.
class _History extends StatelessWidget {
  const _History({required this.ledger, required this.fold});

  final Ledger ledger;
  final _Fold fold;

  @override
  Widget build(BuildContext context) {
    final recent = ledger.entries.where((e) => e.type != EntryType.opening).take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return CollapsibleCard(
      title: 'Recent',
      collapsed: fold('history'),
      onToggle: () => fold.toggle('history'),
      summary: Text('${recent.length}'),
      children: [
        for (final e in recent)
          InkWell(
            onTap: () => showEntryDetails(context, e),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: AmountRow(
                entryTitle(ledger, e),
                e.type == EntryType.move ? e.amount : entrySigned(ledger, e),
                detail: DateFormat.MMMd().format(e.date),
                signed: e.type != EntryType.move,
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => openScreen(context, const EntriesScreen()),
            child: const Text('See all'),
          ),
        ),
      ],
    );
  }
}

/// This month's spending money: what is left, what is left after the
/// bills still to pay, and where it sits. Opens to the budget breakdown.
class _MainCard extends ConsumerWidget {
  const _MainCard({
    required this.ledger,
    required this.summary,
    required this.today,
    required this.fold,
  });

  final Ledger ledger;
  final PeriodSummary summary;
  final DateTime today;
  final _Fold fold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    final soft = on.withValues(alpha: .8);
    final f = FreeToSpend.of(ledger, today);
    final s = summary;
    final period = s.period;
    // Opened by the user; folded by default.
    final open = fold.closed.contains('breakdown+');
    final spending = ledger.spendingFund.id;
    final cells = [
      for (final a in ledger.accountsOfType((t) => t.isLiquid))
        if (ledger.cell(a.id, spending) != 0) (name: a.name, amount: ledger.cell(a.id, spending)),
    ];

    Widget line(String label, Poisha amount, {bool strong = false, String? detail}) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (detail != null)
                  TextSpan(
                    text: '  $detail',
                    style: TextStyle(color: soft, fontSize: 12, fontWeight: FontWeight.w400),
                  ),
              ],
            ),
            style: TextStyle(color: on, fontWeight: strong ? FontWeight.w700 : null),
          ),
        ),
        Money(
          amount,
          color: on,
          style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );

    return SectionCard(
      color: scheme.primary,
      children: [
        Label('Left to spend this month', color: soft),
        Money(
          s.leftToSpend,
          color: on,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.05),
        ),
        if (s.perDay(today) case final perDay? when perDay > 0)
          Text('≈ ${formatTaka(perDay)} a day for ${f.daysLeft} days', style: TextStyle(color: on)),
        Divider(color: on.withValues(alpha: .3), height: 8),
        line(
          f.free >= 0 ? 'Left after bills' : 'Short after bills',
          f.free.abs(),
          strong: true,
          detail: f.bills + f.slots == 0
              ? 'no bills left'
              : '${formatTaka(f.bills + f.slots)} still to pay'
                    '${f.perDay == null ? '' : ' · ≈ ${formatTaka(f.perDay!)}/day'}',
        ),
        if (cells.isNotEmpty)
          Text(
            [for (final c in cells) '${c.name} ${formatTaka(c.amount)}'].join(' · '),
            style: TextStyle(color: soft, fontSize: 13),
          ),
        InkWell(
          onTap: () => fold.toggle('breakdown+'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    open ? 'Hide budget by category' : 'Budget by category',
                    style: TextStyle(color: on, fontWeight: FontWeight.w600),
                  ),
                ),
                if (!open && s.unplanned < 0)
                  Text('Short ${formatTaka(-s.unplanned)}  ', style: TextStyle(color: on)),
                Icon(open ? Icons.expand_less : Icons.expand_more, color: on),
              ],
            ),
          ),
        ),
        if (open) ..._breakdown(context, ref, period, on, soft),
      ],
    );
  }

  /// Each budget: left of budget, or how far over with Cover (move budget
  /// in from elsewhere).
  List<Widget> _breakdown(
    BuildContext context,
    WidgetRef ref,
    Period period,
    Color on,
    Color soft,
  ) {
    final rows = <Widget>[];
    void add(CategoryLine l, {bool sub = false}) {
      final over = l.budget > 0 && l.actual > l.budget;
      rows.add(
        Padding(
          padding: EdgeInsets.only(left: sub ? 12 : 0, top: 2, bottom: 2),
          child: Row(
            spacing: 6,
            children: [
              Expanded(
                child: Text(
                  l.category.name,
                  style: TextStyle(color: on, fontWeight: sub ? null : FontWeight.w600),
                ),
              ),
              Text(
                l.budget == 0
                    ? '${formatTaka(l.actual)} spent'
                    : over
                    ? '${formatTaka(l.actual - l.budget)} over'
                    : '${formatTaka(l.remaining)} of ${formatTaka(l.budget, symbol: false)}',
                style: TextStyle(
                  color: over ? on : soft,
                  fontWeight: over ? FontWeight.w700 : null,
                ),
              ),
              if (over)
                InkWell(
                  onTap: () => showMoveBudgetSheet(
                    context,
                    period,
                    to: l.category.id,
                    amount: l.actual - l.budget,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: on.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Cover', style: TextStyle(color: on, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final budgets = ledger.budgetsFor(period);
    for (final l in ledger.categoryLines(period, CategoryKind.expense)) {
      if (l.budget == 0 && l.actual == 0) continue;
      add(l);
      // A section without a budget of its own is covered per subsection.
      if (l.children.isNotEmpty && (budgets[l.category.id] ?? 0) == 0) {
        for (final c in l.children) {
          if (c.budget > 0 && c.actual > c.budget) add(c, sub: true);
        }
      }
    }
    rows.add(
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          style: TextButton.styleFrom(foregroundColor: on, padding: EdgeInsets.zero),
          onPressed: () => context.go('/spend'),
          child: const Text('Open the Spend tab'),
        ),
      ),
    );
    return rows;
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

/// Bank, cash and wallets.
class _WhereItIs extends StatelessWidget {
  const _WhereItIs({required this.ledger, required this.fold});

  final Ledger ledger;
  final _Fold fold;

  @override
  Widget build(BuildContext context) {
    final liquid = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived);
    final total = ledger.liquidTotal();
    return CollapsibleCard(
      title: 'Where your money is',
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
    );
  }
}

/// A short "What it's for": the main pots and this month's two key
/// figures. Tap for every pot, how the month adds up, and net worth.
class _WhatItsFor extends StatelessWidget {
  const _WhatItsFor({required this.ledger, required this.summary});

  final Ledger ledger;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final savings = ledger
        .fundsOfKind(FundKind.savings)
        .fold<Poisha>(0, (t, f) => t + ledger.fundBalance(f.id));
    final goals = ledger
        .fundsOfKind(FundKind.goal)
        .fold<Poisha>(0, (t, f) => t + ledger.fundBalance(f.id));
    final next = ledger.heldForNextMonth;
    return SectionCard(
      onTap: () => openScreen(context, const MoneyDetailsScreen()),
      children: [
        Row(
          children: [
            const Expanded(child: Label('What your money is for')),
            Icon(Icons.chevron_right, size: 20, color: StatusColors.of(context).muted),
          ],
        ),
        AmountRow('Spending', ledger.fundBalance(ledger.spendingFund.id)),
        AmountRow('Savings', savings),
        if (goals != 0) AmountRow('Goals', goals),
        if (next != 0) AmountRow('For ${s.period.next.label.split(' ').first}', next),
        const Divider(),
        AmountRow('Carried forward', s.carriedForward, detail: 'from last month'),
        AmountRow(
          s.unplanned >= 0 ? 'Unplanned' : 'Short',
          s.unplanned.abs(),
          detail: s.unplanned >= 0 ? 'no budget waiting for it' : 'budgets need more',
          color: s.unplanned < 0 ? StatusColors.of(context).bad : null,
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
        ledger.incomesDue(today).firstWhere((i) => i.categoryId == r.id),
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
