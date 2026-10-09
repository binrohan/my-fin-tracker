import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../core/money.dart';
import '../data/database.dart';
import '../ledger/ledger.dart';

String csvFileName(int? year) => year == null ? 'myfin-entries-all.csv' : 'myfin-entries-$year.csv';

/// Every entry as a CSV that Excel opens directly (UTF-8 with a byte
/// order mark, so ৳ and Bangla text show correctly). Amounts are signed
/// from your point of view: expenses negative, income positive; moves
/// show the amount moved.
Uint8List entriesCsv(Ledger ledger, {int? year}) {
  final rows = <List<String>>[
    ['Date', 'Type', 'Category', 'Amount', 'From', 'To', 'Note', 'Tracker', 'Loan'],
  ];
  final dateFormat = DateFormat('yyyy-MM-dd');
  final entries = ledger.entries
      .where((e) => year == null || e.date.year == year)
      .toList()
      .reversed;

  String pot(PostingLine l) =>
      '${ledger.accounts[l.accountId]?.name} · ${ledger.funds[l.fundId]?.name}';
  String plain(Poisha amount) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    return '$sign${abs ~/ poishaPerTaka}.${(abs % poishaPerTaka).toString().padLeft(2, '0')}';
  }

  for (final Entry e in entries) {
    final postings = ledger.postingsOf(e.id);
    final from = postings.where((l) => l.amount < 0).map(pot).join('; ');
    final to = postings.where((l) => l.amount > 0).map(pot).join('; ');
    final net = postings.fold<Poisha>(0, (t, l) => t + l.amount);
    rows.add([
      dateFormat.format(e.date),
      e.type.name,
      ledger.categories[e.categoryId]?.name ?? '',
      plain(net == 0 ? e.amount : net),
      from,
      to,
      e.note,
      ledger.trackers[e.trackerId]?.name ?? '',
      e.loanId == null ? '' : '#${e.loanId}',
    ]);
  }

  String cell(String v) => v.contains(RegExp('[",\n\r]')) ? '"${v.replaceAll('"', '""')}"' : v;
  final text = rows.map((r) => r.map(cell).join(',')).join('\r\n');
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(text), 13, 10]);
}
