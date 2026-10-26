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
              // Moves, and loans between your own pots, change no total: show
              // the amount plainly rather than a net of ৳0.
              child: () {
                final signed = entrySigned(ledger, e);
                final plain = e.type == EntryType.move || signed == 0;
                return AmountRow(
                  entryTitle(ledger, e),
                  plain ? e.amount : signed,
                  detail: DateFormat.MMMd().format(e.date),
                  signed: !plain,
                );
              }(),
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

    // A lighter panel inside the card, for the two figures side by side.
    Widget tile(String label, Poisha amount, String? detail, {bool alert = false}) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: on.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(label, style: TextStyle(color: soft, fontSize: 12)),
            Money(
              amount,
              color: on,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (detail != null)
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: alert ? on : soft, fontSize: 12),
              ),
          ],
        ),
      ),
    );
    Widget chip(String text, {bool strong = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: on.withValues(alpha: strong ? .22 : .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: on,
          fontSize: 12.5,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );

    final toPay = f.bills + f.slots;
    return SectionCard(
      color: scheme.primary,
      children: [
        // The headline is what you can really use: left to spend once the
        // bills still to pay (and slot money) are taken off.
        Label(f.free >= 0 ? 'Left to spend after bills' : 'Short after bills', color: soft),
        Money(
          f.free.abs(),
          color: on,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.05),
        ),
        Text(
          [
            if (f.perDay case final perDay?) '≈ ${formatTaka(perDay)} a day',
            '${f.daysLeft} ${f.daysLeft == 1 ? 'day' : 'days'} left',
          ].join(' · '),
          style: TextStyle(color: soft),
        ),
        const SizedBox(height: 2),
        Row(
          spacing: 8,
          children: [
            tile(
              'Left to spend',
              s.leftToSpend,
              (s.perDay(today) ?? 0) > 0 ? '≈ ${formatTaka(s.perDay(today)!)} a day' : null,
            ),
            tile('Bills to pay', toPay, toPay == 0 ? 'all paid' : 'still this month'),
          ],
        ),
        if (cells.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final c in cells) chip('${c.name} ${formatTaka(c.amount)}')],
          ),
        Divider(color: on.withValues(alpha: .25), height: 6),
        InkWell(
          onTap: () => fold.toggle('breakdown+'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    open ? 'Hide budget by category' : 'Budget by category',
                    style: TextStyle(color: on, fontWeight: FontWeight.w600),
                  ),
                ),
                if (!open && s.unplanned < 0)
                  chip('Short ${formatTaka(-s.unplanned)}', strong: true),
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

/// What your money is for, as a table: each sector (Spending, Savings,
/// Goals…) across your bank, cash and wallets. Tap for every pot, how
/// this month adds up, and net worth.
class _WhatItsFor extends StatelessWidget {
  const _WhatItsFor({required this.ledger, required this.summary});

  final Ledger ledger;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final s = summary;
    final accounts = [
      for (final a in ledger.accountsOfType((t) => t.isLiquid))
        if (!a.archived && ledger.accountBalance(a.id) != 0) a,
    ];
    // Sector name → the funds it adds up.
    final sectors = <(String, List<int>)>[
      ('Spending', [ledger.spendingFund.id]),
      for (final f in ledger.fundsOfKind(FundKind.savings)) (f.name, [f.id]),
      ('Goals', [for (final f in ledger.fundsOfKind(FundKind.goal)) f.id]),
      (
        'For ${s.period.next.label.split(' ').first}',
        [
          for (final f in ledger.funds.values)
            if (f.kind == FundKind.nextMonth) f.id,
        ],
      ),
    ];
    Poisha cell(List<int> funds, int account) =>
        funds.fold(0, (t, f) => t + ledger.cell(account, f));
    final rows = [
      for (final (name, funds) in sectors)
        if (accounts.any((a) => cell(funds, a.id) != 0)) (name, funds),
    ];

    final numbers = TextStyle(
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
    final head = TextStyle(color: status.muted, fontSize: 12, fontWeight: FontWeight.w600);
    final bold = numbers.copyWith(fontWeight: FontWeight.w700);
    // Numbers shrink to fit their column rather than wrap.
    Widget pad(Widget child, {bool right = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: right ? FittedBox(fit: BoxFit.scaleDown, child: child) : child,
      ),
    );
    String amount(Poisha v) => v == 0 ? '–' : formatTaka(v, symbol: false);

    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FlexColumnWidth(1.3),
        for (var i = 1; i <= accounts.length + 1; i++) i: const FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: status.line)),
          ),
          children: [
            pad(Text('Sector', style: head), right: false),
            for (final a in accounts)
              pad(Text(a.name, style: head, maxLines: 1, overflow: TextOverflow.ellipsis)),
            pad(Text('Total', style: head)),
          ],
        ),
        for (final (name, funds) in rows)
          TableRow(
            children: [
              pad(Text(name, maxLines: 2, overflow: TextOverflow.ellipsis), right: false),
              for (final a in accounts) pad(Text(amount(cell(funds, a.id)), style: numbers)),
              pad(
                Text(
                  amount(accounts.fold(0, (t, a) => t + cell(funds, a.id))),
                  style: numbers.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        TableRow(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: status.line)),
          ),
          children: [
            pad(const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)), right: false),
            for (final a in accounts) pad(Text(amount(ledger.accountBalance(a.id)), style: bold)),
            pad(Text(amount(ledger.liquidTotal()), style: bold)),
          ],
        ),
      ],
    );

    return SectionCard(
      onTap: () => openScreen(context, const MoneyDetailsScreen()),
      children: [
        Row(
          children: [
            const Expanded(child: Label('What your money is for')),
            Text('৳', style: TextStyle(color: status.muted, fontSize: 12)),
            Icon(Icons.chevron_right, size: 20, color: status.muted),
          ],
        ),
        // Many accounts: scroll sideways rather than squeeze.
        if (accounts.length > 3)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 110 + 90.0 * (accounts.length + 1), child: table),
          )
        else
          table,
        const SizedBox(height: 2),
        AmountRow('Carried forward', s.carriedForward, detail: 'from last month'),
        AmountRow(
          s.unplanned >= 0 ? 'Unplanned' : 'Short',
          s.unplanned.abs(),
          detail: s.unplanned >= 0 ? 'no budget waiting for it' : 'budgets need more',
          color: s.unplanned < 0 ? status.bad : null,
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
