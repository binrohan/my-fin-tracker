import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/money.dart';
import '../core/period.dart';
import '../ledger/enums.dart';
import '../ledger/ledger.dart';
import 'pdf_kit.dart';

String annualReportFileName(int year) => 'myfin-annual-$year.pdf';

/// The months of [year] that have data, up to [today]'s month.
List<Period> reportMonths(Ledger ledger, int year, DateTime today) {
  final dated = ledger.entries.where((e) => e.type != EntryType.opening).map((e) => e.date);
  if (dated.isEmpty) return [];
  final first = Period.of(dated.reduce((a, b) => a.isBefore(b) ? a : b));
  final last = Period.of(today);
  return [
    for (var m = 1; m <= 12; m++)
      if (Period(year, m).compareTo(first) >= 0 && Period(year, m).compareTo(last) <= 0)
        Period(year, m),
  ];
}

Future<Uint8List> buildAnnualReport(
  Ledger ledger,
  int year, {
  required ReportFonts fonts,
  required DateTime generatedAt,
}) {
  final months = reportMonths(ledger, year, generatedAt);
  final doc = pw.Document(
    theme: fonts.theme(),
    title: 'Annual Report $year',
    author: 'My Fin Tracker',
  );
  final label = 'Annual Report · $year';
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 26),
      footer: (context) => reportFooter(context, label),
      build: (context) => months.isEmpty
          ? [reportHeader(title: 'Annual Report · $year', subtitle: 'No entries in $year.')]
          : _content(ledger, year, months, generatedAt),
    ),
  );
  return doc.save();
}

List<pw.Widget> _content(Ledger ledger, int year, List<Period> months, DateTime generatedAt) {
  final summaries = [for (final m in months) ledger.summary(m)];
  final start = months.first.start;
  final end = months.last.end;
  Poisha total(Poisha Function(PeriodSummary s) f) => summaries.fold(0, (t, s) => t + f(s));
  final income = total((s) => s.income);
  final spent = total((s) => s.expenses);
  final setAside = total((s) => s.setAside);
  final invested = total((s) => s.invested);
  final worthStart = ledger.netWorth(before: start);
  final worthEnd = ledger.netWorth(before: end);
  final inProgress = months.last == Period.of(generatedAt);

  return [
    reportHeader(
      title: 'Annual Report · $year',
      subtitle:
          '${DateFormat.yMMM().format(start)} – ${months.last.shortLabel}'
          '${inProgress ? ' (year in progress)' : ''} · '
          'Generated ${DateFormat('d MMM yyyy, HH:mm').format(generatedAt)}',
    ),
    kpiRow([
      ('Income', amt(income)),
      ('Spent', amt(spent)),
      ('Set aside', amt(setAside)),
      ('Invested', amt(invested)),
      ('Net worth then', amt(worthStart)),
      ('Net worth now', amt(worthEnd)),
    ]),
    pw.SizedBox(height: 8),
    noteBox(
      pw.Text(
        'Net worth ${worthEnd >= worthStart ? 'grew' : 'fell'} by ${amt((worthEnd - worthStart).abs())} '
        '(${worthStart == 0 ? '—' : pct((worthEnd - worthStart) / worthStart.abs() * 100)}). '
        'You kept ${income == 0 ? '—' : pct((income - spent) / income * 100)} of your income.',
        style: const pw.TextStyle(fontSize: 8.5),
      ),
      rule: worthEnd >= worthStart ? ReportColors.good : ReportColors.bad,
    ),
    sectionTitle('Month by month'),
    _monthChart(months, summaries),
    pw.SizedBox(height: 6),
    table(
      headers: ['Month', 'Income', 'Spent', 'Budget', 'Set aside', 'Left over', 'Net worth'],
      rows: [
        for (final (i, s) in summaries.indexed)
          ReportRow(
            [
              DateFormat.MMM().format(months[i].start),
              amt(s.income),
              amt(s.expenses),
              s.budget == 0 ? '' : amt(s.budget),
              amt(s.setAside),
              amt(s.leftToSpend),
              amt(ledger.netWorth(before: months[i].end)),
            ],
            colors: {if (s.budget > 0 && s.expenses > s.budget) 2: ReportColors.bad},
          ),
        ReportRow([
          'Total',
          amt(income),
          amt(spent),
          amt(total((s) => s.budget)),
          amt(setAside),
          '',
          amt(worthEnd),
        ], style: RowStyle.total),
      ],
    ),
    ..._categories(ledger, months, spent),
    ..._funds(ledger, start, end),
    ..._investments(ledger, end),
    ..._loans(ledger, end),
    ..._purchases(ledger, year),
    ..._trackers(ledger),
  ];
}

/// Income (green) and spending (rust) bars for each month.
pw.Widget _monthChart(List<Period> months, List<PeriodSummary> summaries) {
  final top = summaries.fold<Poisha>(
    1,
    (m, s) => [m, s.income, s.expenses].reduce((a, b) => a > b ? a : b),
  );
  const height = 70.0;
  pw.Widget bar(Poisha v, PdfColor c) => pw.Container(width: 9, height: height * v / top, color: c);
  return pw.Container(
    height: height + 14,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        for (final (i, s) in summaries.indexed)
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  bar(s.income, ReportColors.accent),
                  pw.SizedBox(width: 2),
                  bar(s.expenses, ReportColors.allocation[0]),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                DateFormat.MMM().format(months[i].start),
                style: pw.TextStyle(fontSize: 6.5, color: ReportColors.muted),
              ),
            ],
          ),
      ],
    ),
  );
}

List<pw.Widget> _categories(Ledger ledger, List<Period> months, Poisha spent) {
  final totals = <String, Poisha>{};
  for (final m in months) {
    for (final l in ledger.categoryLines(m, CategoryKind.expense)) {
      if (l.actual != 0) {
        totals.update(l.category.name, (v) => v + l.actual, ifAbsent: () => l.actual);
      }
    }
  }
  if (totals.isEmpty) return [];
  final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return [
    sectionTitle('Spending by category'),
    table(
      headers: ['Category', 'Total', 'A month', 'Share'],
      rows: [
        for (final e in sorted)
          ReportRow([
            e.key,
            amt(e.value),
            amt((e.value / months.length).round()),
            spent == 0 ? '' : pct(e.value / spent * 100),
          ]),
        ReportRow([
          'Total',
          amt(spent),
          amt((spent / months.length).round()),
          '100%',
        ], style: RowStyle.total),
      ],
    ),
  ];
}

List<pw.Widget> _funds(Ledger ledger, DateTime start, DateTime end) {
  final funds = ledger.funds.values.where(
    (f) =>
        (f.kind == FundKind.savings || f.kind == FundKind.goal) &&
        (ledger.fundBalance(f.id, before: end, liquidOnly: false) != 0 ||
            ledger.fundBalance(f.id, before: start, liquidOnly: false) != 0 ||
            (f.achievedAt != null && !f.achievedAt!.isBefore(start))),
  );
  if (funds.isEmpty) return [];
  return [
    sectionTitle('Savings and goals'),
    table(
      headers: ['Pot', 'Start', 'End', 'Change', 'Target'],
      widths: {0: const pw.FlexColumnWidth(3)},
      rows: [
        for (final f in funds)
          () {
            final a = ledger.fundBalance(f.id, before: start, liquidOnly: false);
            final b = ledger.fundBalance(f.id, before: end, liquidOnly: false);
            return ReportRow(
              [
                '${f.name}${f.achievedAt != null ? ' ✓ ${DateFormat.yMMM().format(f.achievedAt!)}' : ''}',
                amt(a),
                amt(b),
                signedAmt(b - a),
                f.targetAmount == null ? '' : amt(f.targetAmount!),
              ],
              colors: {3: b >= a ? ReportColors.good : ReportColors.bad},
            );
          }(),
      ],
    ),
  ];
}

List<pw.Widget> _investments(Ledger ledger, DateTime end) {
  final list = [
    for (final a in ledger.accountsOfType((t) => t == AccountType.investment))
      if (ledger.accountBalance(a.id, before: end) != 0) ledger.investmentStatus(a, before: end),
  ];
  if (list.isEmpty) return [];
  return [
    sectionTitle('Investments at the end'),
    table(
      headers: ['Name', 'Matures', 'Put in', 'Growth', 'Value'],
      textColumns: {0, 1},
      rows: [
        for (final i in list)
          ReportRow([
            i.account.name,
            i.details?.maturityDate == null
                ? ''
                : DateFormat.yMMM().format(i.details!.maturityDate!),
            amt(i.invested),
            signedAmt(i.growth),
            amt(i.value),
          ]),
        ReportRow([
          'Total',
          '',
          amt(list.fold(0, (t, i) => t + i.invested)),
          signedAmt(list.fold(0, (t, i) => t + i.growth)),
          amt(list.fold(0, (t, i) => t + i.value)),
        ], style: RowStyle.total),
      ],
    ),
  ];
}

List<pw.Widget> _loans(Ledger ledger, DateTime end) {
  final open = [
    for (final l in ledger.loans)
      if (l.date.isBefore(end) && ledger.loanStatus(l, before: end).remaining > 0)
        ledger.loanStatus(l, before: end),
  ];
  if (open.isEmpty) return [];
  String who(LoanStatus s) => switch (s.loan.kind) {
    LoanKind.ownSavings => 'Owed to ${ledger.funds[s.loan.fundId]?.name}',
    LoanKind.lent => '${ledger.accounts[s.loan.personAccountId]?.name} owes you',
    LoanKind.borrowed => 'You owe ${ledger.accounts[s.loan.personAccountId]?.name}',
  };
  return [
    sectionTitle('Loans still open'),
    table(
      headers: ['Loan', 'Since', 'Due', 'Left'],
      textColumns: {0, 1},
      rows: [
        for (final s in open)
          ReportRow([who(s), dayMonthYear(s.loan.date), amt(s.due), amt(s.remaining)]),
      ],
    ),
  ];
}

List<pw.Widget> _purchases(Ledger ledger, int year) {
  final list = ledger.purchasesIn(year).reversed.toList();
  if (list.isEmpty) return [];
  final total = list.fold<Poisha>(0, (t, p) => t + p.amount);
  return [
    sectionTitle('Major purchases', note: '${list.length} items'),
    table(
      headers: ['Date', 'Item', 'Shop', 'Warranty', 'Amount'],
      textColumns: {0, 1, 2, 3},
      widths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2.6),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.3),
      },
      rows: [
        for (final p in list)
          ReportRow([
            dayMonth(p.date),
            p.item,
            p.shop,
            p.warrantyUntil == null ? '' : DateFormat.yMMM().format(p.warrantyUntil!),
            amt(p.amount),
          ]),
        ReportRow(['Total', '', '', '', amt(total)], style: RowStyle.total),
      ],
    ),
  ];
}

List<pw.Widget> _trackers(Ledger ledger) {
  final list = [for (final t in ledger.trackers.values) ledger.trackerStatus(t)];
  if (list.isEmpty) return [];
  return [
    sectionTitle('Trackers'),
    table(
      headers: ['Tracker', 'Kind', 'Spent', 'Budget', 'Left'],
      textColumns: {0, 1},
      rows: [
        for (final t in list)
          ReportRow(
            [
              '${t.tracker.name}${t.tracker.archived ? ' (finished)' : ''}',
              t.tracker.kind == TrackerKind.countdown ? 'Countdown' : 'Project',
              amt(t.spent),
              t.tracker.budget == null ? '' : amt(t.tracker.budget!),
              t.left == null ? '' : amt(t.left!),
            ],
            colors: {if ((t.left ?? 0) < 0) 4: ReportColors.bad},
          ),
      ],
    ),
  ];
}
