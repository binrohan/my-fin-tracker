import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/money.dart';
import '../core/period.dart';
import '../data/database.dart';
import '../ledger/enums.dart';
import '../ledger/insights.dart';
import '../ledger/ledger.dart';
import 'pdf_kit.dart';

String monthlyReportFileName(Period p) => 'myfin-report-$p.pdf';

/// The month's report as an A4 PDF, laid out like the example in the plan.
Future<Uint8List> buildMonthlyReport(
  Ledger ledger,
  Period p, {
  required ReportFonts fonts,
  required DateTime generatedAt,
}) {
  final doc = pw.Document(
    theme: fonts.theme(),
    title: 'Monthly Report ${p.label}',
    author: 'My Fin Tracker',
  );
  final label = 'Monthly Report · ${p.shortLabel}';
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 26),
      footer: (context) => reportFooter(context, label),
      build: (context) => [..._summary(ledger, p, generatedAt), ..._savingsAndAssets(ledger, p)],
    ),
  );
  final entries = ledger.entries.where((e) => p.contains(e.date)).toList().reversed.toList();
  if (entries.isNotEmpty) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 26),
        footer: (context) => reportFooter(context, label),
        build: (context) => [
          sectionTitle('All entries', note: '${entries.length} entries'),
          _ledgerTable(ledger, entries),
        ],
      ),
    );
  }
  return doc.save();
}

List<pw.Widget> _summary(Ledger ledger, Period p, DateTime generatedAt) {
  final s = ledger.summary(p);
  final netWorth = ledger.netWorth(before: p.end);
  final close = ledger.monthCloses.where((c) => c.year == p.year && c.month == p.month).firstOrNull;
  final other = s.closingLiquid - (s.openingLiquid + s.income - s.expenses - s.invested);

  final lastDay = p.end.subtract(const Duration(days: 1));
  final subtitle =
      'Period 1–${lastDay.day} ${DateFormat.MMM().format(p.start)} ${p.year} · '
      'Generated ${DateFormat('d MMM yyyy, HH:mm').format(generatedAt)}';

  final recon = StringBuffer(
    'Opening ${amt(s.openingLiquid)} + Income ${amt(s.income)} − Spent ${amt(s.expenses)} − '
    'Invested ${amt(s.invested)}',
  );
  if (other != 0) recon.write(' ${other > 0 ? '+' : '−'} Loans & other ${amt(other.abs())}');
  recon.write(' = Closing ${amt(s.closingLiquid)}');

  final bank = ledger.accountsOfType((t) => t == AccountType.bank).firstOrNull;
  final status = close == null
      ? 'Month not closed yet'
      : close.confirmedBank != null && bank != null
      ? 'Bank matched to statement (${amt(close.confirmedBank!)})'
      : 'Month closed ${dayMonthYear(close.closedAt)}';

  return [
    reportHeader(title: 'Monthly Report · ${p.label}', subtitle: subtitle),
    kpiRow([
      ('Opening', amt(s.openingLiquid)),
      ('Income', amt(s.income)),
      ('Spent', amt(s.expenses)),
      ('Invested', amt(s.invested)),
      ('Closing', amt(s.closingLiquid)),
      ('Net worth', amt(netWorth)),
    ]),
    pw.SizedBox(height: 8),
    noteBox(
      pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 8),
          children: [
            pw.TextSpan(text: '$recon  '),
            pw.TextSpan(
              text: ledger.isBalanced ? '✓ BALANCED' : 'NOT BALANCED',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: ledger.isBalanced ? ReportColors.good : ReportColors.bad,
              ),
            ),
            pw.TextSpan(text: ' · $status'),
          ],
        ),
      ),
    ),
    twoColumns(_income(ledger, p), _openingBalances(ledger, p, s)),
    ..._allocation(ledger, p, s),
    ..._expenses(ledger, p, s),
    ..._comparison(ledger, p, generatedAt),
  ];
}

pw.Widget _income(Ledger ledger, Period p) {
  final s = ledger.summary(p);
  final lines = ledger.categoryLines(p, CategoryKind.income).where((l) => l.actual != 0).toList();
  final total = lines.fold<Poisha>(0, (t, l) => t + l.actual);
  final count = ledger.entries
      .where((e) => e.type == EntryType.income && p.contains(e.date))
      .length;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      sectionTitle('Income', note: '$count ${count == 1 ? 'entry' : 'entries'}'),
      if (lines.isEmpty) muted('No income recorded.'),
      table(
        rows: [
          for (final l in lines) ReportRow([l.category.name, amt(l.actual)]),
          ReportRow(['Total', amt(total)], style: RowStyle.total),
        ],
      ),
      if (s.heldForNext > 0)
        muted(
          'Of this, ${amt(s.heldForNext)} was held for ${p.next.label} (received for next month).',
        ),
      if (s.released > 0) muted('Plus ${amt(s.released)} received last month for ${p.label}.'),
    ],
  );
}

pw.Widget _openingBalances(Ledger ledger, Period p, PeriodSummary s) {
  final accounts = ledger
      .accountsOfType((t) => t.isLiquid)
      .where((a) => ledger.accountBalance(a.id, before: p.start) != 0 || !a.archived);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      sectionTitle('Opening balances', note: dayMonth(p.start)),
      table(
        rows: [
          for (final a in accounts)
            ReportRow([a.name, amt(ledger.accountBalance(a.id, before: p.start))]),
          ReportRow([
            'Total · incl. carried fwd ${amt(s.carriedForward)}',
            amt(s.openingLiquid),
          ], style: RowStyle.total),
        ],
      ),
    ],
  );
}

List<pw.Widget> _allocation(Ledger ledger, Period p, PeriodSummary s) {
  // The month's own income: what arrived for it, plus last month's income
  // released for it; income held for next month is left out.
  final income = s.monthIncome;
  if (income <= 0) return [];
  final byKind = ledger.setAsideByKind(p);
  final parts = <(String, Poisha)>[
    ('Expenses', s.expenses),
    ('Savings', byKind[FundKind.savings] ?? 0),
    ('Goals', byKind[FundKind.goal] ?? 0),
    ('Investments', byKind[FundKind.investment] ?? 0),
  ];
  final used = parts.fold<Poisha>(0, (t, x) => t + x.$2);
  final unspent = income - used;
  if (unspent > 0) parts.add(('Unspent', unspent));
  final shown = [
    for (final (i, x) in parts.indexed)
      if (x.$2 > 0) (i, x.$1, x.$2),
  ];
  final base = used > income ? used : income;

  return [
    sectionTitle('Where the income went', note: '% of ${amt(income)}'),
    pw.Container(
      height: 13,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: ReportColors.line)),
      child: pw.Row(
        children: [
          for (final (i, _, value) in shown)
            pw.Expanded(
              flex: (value * 1000 ~/ base).clamp(1, 1000000),
              child: pw.Container(color: ReportColors.allocation[i]),
            ),
        ],
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Wrap(
      spacing: 12,
      runSpacing: 3,
      children: [
        for (final (i, name, value) in shown)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(width: 7, height: 7, color: ReportColors.allocation[i]),
              pw.SizedBox(width: 3),
              pw.Text(
                '$name ${amt(value)} · ${pct(value / income * 100)}',
                style: pw.TextStyle(fontSize: 7.5, color: ReportColors.muted),
              ),
            ],
          ),
      ],
    ),
    if (used > income)
      muted(
        'More went out than came in: ${amt(used - income)} came from money carried forward or borrowed.',
      ),
  ];
}

List<pw.Widget> _expenses(Ledger ledger, Period p, PeriodSummary s) {
  final lines = ledger.categoryLines(p, CategoryKind.expense);
  final count = ledger.entries
      .where((e) => e.type == EntryType.expense && p.contains(e.date))
      .length;
  final rows = <ReportRow>[];
  final overNotes = <String>[];

  // Unused budget saved to a linked pot at close counts as used.
  var savedTotal = 0;
  ReportRow row(CategoryLine l, {required bool sub}) {
    final saved = ledger.savedAtClose(l, p);
    if (!sub) savedTotal += saved;
    final diff = l.actual + saved - l.budget;
    return ReportRow(
      [
        l.category.name,
        l.budget == 0 ? '' : amt(l.budget),
        amt(l.actual),
        saved == 0 ? '' : amt(saved),
        l.budget == 0 ? '' : signedAmt(diff).replaceFirst('+0', '0'),
        l.budget == 0 || sub ? '' : 'bar',
      ],
      style: sub ? RowStyle.sub : RowStyle.normal,
      colors: {
        if (l.isOver) 2: ReportColors.bad,
        if (saved > 0) 3: ReportColors.good,
        if (l.budget > 0 && diff > 0) 4: ReportColors.bad,
        if (l.budget > 0 && diff < 0) 4: ReportColors.good,
      },
    );
  }

  for (final l in lines.where((l) => l.actual != 0 || l.budget != 0)) {
    rows.add(row(l, sub: false));
    for (final c in l.children.where((c) => c.actual != 0 || c.budget != 0)) {
      rows.add(row(c, sub: true));
    }
    if (l.isOver) overNotes.add(_overNote(ledger, p, l));
  }
  // Loan repayments paid from a budget count as spent there.
  final repaid = ledger.repaidFromBudget(p).values.fold<Poisha>(0, (t, v) => t + v);
  final spent = s.expenses + repaid;
  final diff = spent + savedTotal - s.budget;
  rows.add(
    ReportRow(
      [
        'Total',
        amt(s.budget),
        amt(spent),
        savedTotal == 0 ? '' : amt(savedTotal),
        signedAmt(diff),
        s.budget == 0 ? '' : pct((spent + savedTotal) / s.budget * 100),
      ],
      style: RowStyle.total,
      colors: {if (diff > 0) 4: ReportColors.bad, if (diff < 0) 4: ReportColors.good},
    ),
  );

  final barFor = {for (final l in lines) l.category.name: l};
  return [
    sectionTitle('Expenses vs budget', note: '$count entries'),
    if (repaid > 0) muted('Actual includes ${amt(repaid)} of loans paid back from a budget.'),
    if (savedTotal > 0)
      muted(
        'Saved: unused budget sent to the category\'s pot when the month closed; it counts as used.',
      ),
    table(
      headers: ['Category', 'Budget', 'Actual', 'Saved', 'Diff', 'Used'],
      widths: {
        0: const pw.FlexColumnWidth(2.8),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.3),
        5: const pw.FlexColumnWidth(1.6),
      },
      rows: rows,
      custom: {
        5: (r) {
          if (r.cells[5] != 'bar') {
            return pw.Text(
              r.cells[5],
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: r.style == RowStyle.total ? pw.FontWeight.bold : null,
              ),
            );
          }
          final l = barFor[r.cells[0]]!;
          final used = l.budget == 0 ? 0.0 : (l.actual + ledger.savedAtClose(l, p)) / l.budget;
          return progress(used, over: l.isOver);
        },
      },
    ),
    for (final note in overNotes) muted(note),
  ];
}

/// Category by category against last month (the same days, for a month
/// still running), largest changes first.
List<pw.Widget> _comparison(Ledger ledger, Period p, DateTime generatedAt) {
  if (ledger.settings[insightsOffSetting] == 'true') return [];
  final c = compareMonths(ledger, p, today: generatedAt);
  if (c == null) return [];
  final month = DateFormat.MMM();
  final prev = c.previous;
  final top = c.changes.values.where((x) => x.category.parentId == null).toList()
    ..sort((a, b) => b.diff.abs().compareTo(a.diff.abs()));

  String change(Poisha diff, double? share) => share == null
      ? (diff == 0 ? '' : 'new')
      : '${share >= 0 ? '+' : '−'}${pct(share.abs() * 100)}';
  Map<int, PdfColor> colors(Poisha diff) => {
    if (diff > 0) 3: ReportColors.bad,
    if (diff < 0) 3: ReportColors.good,
  };

  return [
    sectionTitle(
      'Compared with ${DateFormat.MMMM().format(prev.start)}',
      note: c.throughDay == null ? 'whole months' : '1–${c.throughDay} of each month',
    ),
    table(
      headers: ['Category', month.format(p.start), month.format(prev.start), 'Change', ''],
      widths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.8),
      },
      rows: [
        for (final x in top.where((x) => x.diff != 0))
          ReportRow([
            x.category.name,
            amt(x.now),
            amt(x.before),
            signedAmt(x.diff),
            change(x.diff, x.share),
          ], colors: colors(x.diff)),
        ReportRow(
          ['Total', amt(c.now), amt(c.before), signedAmt(c.diff), change(c.diff, c.share)],
          style: RowStyle.total,
          colors: colors(c.diff),
        ),
      ],
    ),
  ];
}

/// "Random over budget: Ceiling fan 3,400 · Medicine 2,600 · Other 850."
String _overNote(Ledger ledger, Period p, CategoryLine line) {
  final ids = <int>{line.category.id, ..._descendants(line)};
  final items = ledger.entries
      .where((e) => e.type == EntryType.expense && p.contains(e.date) && ids.contains(e.categoryId))
      .toList();
  final named = items.where((e) => e.note.isNotEmpty).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  final top = named.take(3).toList();
  final rest = items.where((e) => !top.contains(e)).fold<Poisha>(0, (t, e) => t + e.amount);
  final parts = [
    for (final e in top) '${e.note} ${amt(e.amount)}',
    if (rest > 0) 'Other ${amt(rest)}',
  ];
  return '${line.category.name} over budget by ${amt(-line.remaining)}: ${parts.join(' · ')}.';
}

Iterable<int> _descendants(CategoryLine line) sync* {
  for (final c in line.children) {
    yield c.category.id;
    yield* _descendants(c);
  }
}

List<pw.Widget> _savingsAndAssets(Ledger ledger, Period p) {
  final s = ledger.summary(p);
  return [
    ..._savingsPots(ledger, p),
    ..._goals(ledger, p),
    ..._loans(ledger, p),
    twoColumns(_closingBalances(ledger, p), _cash(ledger, p)),
    ..._investments(ledger, p),
    twoColumns(_purchases(ledger, p), _trackers(ledger, p)),
    pw.SizedBox(height: 10),
    noteBox(
      pw.Text(
        'Carried forward to ${p.next.label}: Spending ${amt(s.carriedForward)} + income ${amt(s.spendingIncome)} '
        '${s.released == 0 ? '' : '+ income for this month ${amt(s.released)} '}'
        '− set aside ${amt(s.setAside)} − spent ${amt(s.spendingExpenses)}'
        '${s.loanNet == 0 ? '' : ' ${s.loanNet > 0 ? '+' : '−'} loans ${amt(s.loanNet.abs())}'}'
        '${s.startingNet == 0 ? '' : ' + starting ${amt(s.startingNet)}'}'
        '${s.adjustNet == 0 ? '' : ' ${s.adjustNet > 0 ? '+' : '−'} adjustments ${amt(s.adjustNet.abs())}'}'
        ' = ${amt(s.leftToSpend)}',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: ReportColors.accent,
        ),
      ),
      rule: ReportColors.accent,
    ),
  ];
}

List<pw.Widget> _savingsPots(Ledger ledger, Period p) {
  final funds = ledger.funds.values.where((f) => f.kind == FundKind.savings);
  return [
    for (final f in funds)
      ...() {
        final m = ledger.fundMovement(f.id, p);
        final owed = ledger.loans
            .where((l) => l.kind == LoanKind.ownSavings && l.fundId == f.id)
            .fold<Poisha>(
              0,
              (t, l) => t + ledger.loanStatus(l, before: p.end).remaining.clamp(0, 1 << 52),
            );
        final rows = [
          ReportRow(['Opening balance', amt(m.opening)]),
          if (m.deposits != 0)
            ReportRow(['Deposits', signedAmt(m.deposits)], colors: {1: ReportColors.good}),
          if (m.withdrawals != 0)
            ReportRow(['Withdrawals', signedAmt(m.withdrawals)], colors: {1: ReportColors.bad}),
          if (m.borrowedOut != 0)
            ReportRow(
              ['Borrowed to Spending', signedAmt(m.borrowedOut)],
              colors: {1: ReportColors.bad},
            ),
          if (m.repaidIn != 0)
            ReportRow(['Repayments', signedAmt(m.repaidIn)], colors: {1: ReportColors.good}),
          if (m.spent != 0)
            ReportRow(['Spent directly', signedAmt(m.spent)], colors: {1: ReportColors.bad}),
          if (m.other != 0) ReportRow(['Other', signedAmt(m.other)]),
          ReportRow([
            'Closing balance${owed > 0 ? ' · plus ${amt(owed)} still owed back' : ''}',
            amt(m.closing),
          ], style: RowStyle.total),
        ];
        return [sectionTitle(f.name), table(rows: rows)];
      }(),
  ];
}

List<pw.Widget> _goals(Ledger ledger, Period p) {
  final goals = ledger.funds.values
      .where(
        (f) =>
            f.kind == FundKind.goal &&
            (f.achievedAt == null || p.contains(f.achievedAt!)) &&
            (ledger.fundBalance(f.id, before: p.end, liquidOnly: false) != 0 ||
                ledger.fundMovement(f.id, p).opening != 0),
      )
      .toList();
  if (goals.isEmpty) return [];
  Poisha opening = 0, added = 0, closing = 0, target = 0;
  final rows = <ReportRow>[];
  for (final g in goals) {
    final m = ledger.fundMovement(g.id, p);
    final t = g.targetAmount ?? 0;
    opening += m.opening;
    closing += m.closing;
    added += m.closing - m.opening;
    target += t;
    rows.add(
      ReportRow([
        '${g.name}${g.targetDate == null ? '' : ' · by ${DateFormat.yMMM().format(g.targetDate!)}'}${g.achievedAt != null ? ' ✓' : ''}',
        amt(m.opening),
        signedAmt(m.closing - m.opening),
        amt(m.closing),
        t == 0 ? '' : amt(t),
        t == 0 ? '' : (m.closing / t).toString(),
      ]),
    );
  }
  rows.add(
    ReportRow([
      'Total',
      amt(opening),
      signedAmt(added),
      amt(closing),
      amt(target),
      '',
    ], style: RowStyle.total),
  );
  return [
    sectionTitle(
      'Saving for something',
      note: '${goals.length} ${goals.length == 1 ? 'goal' : 'goals'}',
    ),
    table(
      headers: ['Goal', 'Opening', 'Added', 'Closing', 'Target', 'Progress'],
      widths: {0: const pw.FlexColumnWidth(3.2), 5: const pw.FlexColumnWidth(1.8)},
      rows: rows,
      custom: {5: (r) => r.cells[5].isEmpty ? pw.SizedBox() : progress(double.parse(r.cells[5]))},
    ),
  ];
}

List<pw.Widget> _loans(Ledger ledger, Period p) {
  final loans = ledger.loansDuring(p);
  if (loans.isEmpty) return [];
  String title(LoanStatus s) {
    final l = s.loan;
    final who = ledger.accounts[l.personAccountId]?.name;
    return switch (l.kind) {
      LoanKind.ownSavings => 'Borrowed from ${ledger.funds[l.fundId]?.name}',
      LoanKind.lent => 'Lent to $who · owes you',
      LoanKind.borrowed => 'Borrowed from $who · you owe',
    };
  }

  return [
    sectionTitle('Loans', note: 'own savings charge ${formatPercentBp(ledger.borrowChargeBp)}'),
    table(
      headers: ['Loan', 'Date', 'Amount', 'Charge', 'Due', 'Paid', 'Left'],
      textColumns: {0, 1},
      widths: {0: const pw.FlexColumnWidth(3.4), 1: const pw.FlexColumnWidth(1.2)},
      rows: [
        for (final s in loans)
          ReportRow(
            [
              title(s),
              dayMonth(s.loan.date),
              amt(s.loan.principal),
              amt(s.loan.charge),
              amt(s.due),
              amt(s.repaid),
              amt(s.remaining),
            ],
            colors: {
              6: s.remaining <= 0
                  ? ReportColors.muted
                  : (s.loan.kind == LoanKind.lent ? ReportColors.good : ReportColors.bad),
            },
          ),
      ],
    ),
  ];
}

pw.Widget _closingBalances(Ledger ledger, Period p) {
  final accounts = ledger
      .accountsOfType((t) => t.isLiquid)
      .where((a) => ledger.accountBalance(a.id, before: p.end) != 0 || !a.archived);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      sectionTitle('Closing balances', note: dayMonth(p.end.subtract(const Duration(days: 1)))),
      table(
        rows: [
          for (final a in accounts)
            ReportRow([a.name, amt(ledger.accountBalance(a.id, before: p.end))]),
          ReportRow(['Total', amt(ledger.liquidTotal(before: p.end))], style: RowStyle.total),
        ],
      ),
    ],
  );
}

pw.Widget _cash(Ledger ledger, Period p) {
  final cash = ledger.accountsOfType((t) => t == AccountType.cash).where((a) => !a.archived);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      for (final a in cash) ...[
        sectionTitle(cash.length == 1 ? 'Cash in drawer' : a.name, note: 'by sector'),
        table(
          rows: [
            for (final s in ledger.sectorsOf(a.id, before: p.end))
              ReportRow([s.fund.name, amt(s.amount)]),
            ReportRow([
              'Total',
              amt(ledger.accountBalance(a.id, before: p.end)),
            ], style: RowStyle.total),
          ],
        ),
      ],
    ],
  );
}

List<pw.Widget> _investments(Ledger ledger, Period p) {
  final list = [
    for (final a in ledger.accountsOfType((t) => t == AccountType.investment))
      if (ledger.accountBalance(a.id, before: p.end) != 0)
        ledger.investmentStatus(a, before: p.end),
  ];
  if (list.isEmpty) return [];
  String detail(InvestmentStatus i) {
    final d = i.details;
    if (d == null) return '';
    return [
      if (d.instalment != null) '${amt(d.instalment!)}/mo',
      if (d.totalInstalments != null) '${i.instalmentsPaid} of ${d.totalInstalments} paid',
      if (d.maturityDate != null) 'matures ${DateFormat.yMMM().format(d.maturityDate!)}',
    ].join(' · ');
  }

  final invested = list.fold<Poisha>(0, (t, i) => t + i.invested);
  final value = list.fold<Poisha>(0, (t, i) => t + i.value);
  return [
    sectionTitle('Investments'),
    table(
      headers: ['Name', 'Detail', 'Put in', 'Value'],
      textColumns: {0, 1},
      widths: {0: const pw.FlexColumnWidth(2.2), 1: const pw.FlexColumnWidth(3.4)},
      rows: [
        for (final i in list) ReportRow([i.account.name, detail(i), amt(i.invested), amt(i.value)]),
        ReportRow(['Total', '', amt(invested), amt(value)], style: RowStyle.total),
      ],
    ),
  ];
}

pw.Widget _purchases(Ledger ledger, Period p) {
  final list = ledger.purchases.where((x) => p.contains(x.date)).toList().reversed;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      sectionTitle('Major purchases'),
      if (list.isEmpty) muted('None this month.'),
      for (final x in list) ...[
        table(
          rows: [
            ReportRow(['${dayMonth(x.date)} · ${x.item}', amt(x.amount)]),
          ],
        ),
        if (x.shop.isNotEmpty || x.warrantyUntil != null)
          muted(
            [
              if (x.shop.isNotEmpty) x.shop,
              if (x.warrantyUntil != null)
                'warranty to ${DateFormat.yMMM().format(x.warrantyUntil!)}',
            ].join(' · '),
          ),
      ],
    ],
  );
}

pw.Widget _trackers(Ledger ledger, Period p) {
  final list = ledger.activeTrackers();
  final lastDay = p.end.subtract(const Duration(days: 1));
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      sectionTitle('Trackers'),
      if (list.isEmpty) muted('No trackers.'),
      table(
        rows: [
          for (final t in list)
            ReportRow([
              '${t.tracker.name}${t.tracker.kind == TrackerKind.countdown ? ' (countdown)' : ''}',
              () {
                final month = t.entries
                    .where((e) => p.contains(e.date))
                    .fold<Poisha>(0, (s, e) => s + e.amount);
                if (t.tracker.kind == TrackerKind.countdown && t.left != null) {
                  final days = t.daysLeft(lastDay);
                  return '${amt(t.left!)} left${days != null && days >= 0 ? ' · $days d' : ''}';
                }
                return '${month == 0 ? '' : '+${amt(month)} · '}${amt(t.spent)}';
              }(),
            ]),
        ],
      ),
    ],
  );
}

pw.Widget _ledgerTable(Ledger ledger, List<Entry> entries) {
  String kind(Entry e) => switch (e.type) {
    EntryType.income => 'Income',
    EntryType.expense => 'Expense',
    EntryType.move => 'Move',
    EntryType.opening => 'Starting',
    EntryType.adjust => 'Adjust',
    EntryType.borrow => 'Borrow',
    EntryType.repay => 'Repay',
    EntryType.lend => 'Lend',
    EntryType.collect => 'Received',
    EntryType.charge => 'Charge',
    EntryType.release => 'Released',
  };
  String where(Entry e) {
    final ps = ledger.postingsOf(e.id);
    String name(PostingLine l) =>
        '${ledger.accounts[l.accountId]?.name}·${ledger.funds[l.fundId]?.name}';
    final out = ps.where((l) => l.amount < 0).map(name).join(', ');
    final into = ps.where((l) => l.amount > 0).map(name).join(', ');
    if (out.isNotEmpty && into.isNotEmpty) return '$out → $into';
    return out.isNotEmpty ? out : into;
  }

  Poisha signed(Entry e) => switch (e.type) {
    EntryType.expense => -e.amount,
    EntryType.move => e.amount,
    _ => ledger.postingsOf(e.id).fold(0, (t, l) => t + l.amount),
  };

  return table(
    headers: ['Date', 'Type', 'Category / note', 'From → to', 'Amount'],
    textColumns: {0, 1, 2, 3},
    widths: {
      0: const pw.FlexColumnWidth(1),
      1: const pw.FlexColumnWidth(1.1),
      2: const pw.FlexColumnWidth(2.6),
      3: const pw.FlexColumnWidth(3.2),
      4: const pw.FlexColumnWidth(1.3),
    },
    rows: [
      for (final e in entries)
        ReportRow(
          [
            dayMonth(e.date),
            kind(e),
            [
              ledger.categories[e.categoryId]?.name,
              if (e.note.isNotEmpty) e.note,
            ].whereType<String>().join(' · '),
            where(e),
            e.type == EntryType.move || signed(e) == 0 ? amt(e.amount) : signedAmt(signed(e)),
          ],
          colors: {
            if (e.type == EntryType.expense) 4: ReportColors.bad,
            if (e.type == EntryType.income) 4: ReportColors.good,
          },
        ),
    ],
  );
}
