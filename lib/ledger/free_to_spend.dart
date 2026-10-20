import 'dart:math' as math;

import '../core/money.dart';
import '../core/period.dart';
import 'ledger.dart';

/// Left to spend once the fixed bills still to pay and money kept in slots
/// are taken off: what you can really use. Shared by the After bills Home
/// and the home-screen widgets.
class FreeToSpend {
  const FreeToSpend({
    required this.summary,
    required this.bills,
    required this.slots,
    required this.daysLeft,
    required this.next,
  });

  factory FreeToSpend.of(Ledger ledger, DateTime today) {
    final period = Period.of(today);
    final unpaid = ledger.unpaidFixedBills(period);
    final slots = ledger.slotsIn(period);

    // What comes next: the nearest unpaid bill or slot with a date.
    final day = DateTime(today.year, today.month, today.day);
    final coming = <({String name, DateTime date, Poisha amount})>[
      for (final b in unpaid)
        if (b.category.dueDay case final due?)
          (
            name: b.category.name,
            date: DateTime(period.year, period.month, due.clamp(1, period.daysInMonth)),
            amount: b.remaining,
          ),
      for (final s in slots)
        if (s.left > 0)
          if (s.category.dueDay case final due?)
            (
              name: s.category.name,
              date: DateTime(period.year, period.month, due.clamp(1, period.daysInMonth)),
              amount: s.left,
            ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = coming.where((c) => !c.date.isBefore(day)).firstOrNull ?? coming.firstOrNull;

    return FreeToSpend(
      summary: ledger.summary(period),
      bills: unpaid.fold(0, (t, b) => t + b.remaining),
      slots: slots.fold(0, (t, s) => t + math.max(0, s.left)),
      daysLeft: period.daysInMonth - today.day + 1,
      next: upcoming,
    );
  }

  final PeriodSummary summary;

  /// Fixed bills not yet paid this month.
  final Poisha bills;

  /// Money still kept in this month's slots.
  final Poisha slots;

  /// Days left in the month, today included.
  final int daysLeft;

  /// The nearest unpaid bill or dated slot (overdue ones only if nothing
  /// is ahead).
  final ({String name, DateTime date, Poisha amount})? next;

  Poisha get leftToSpend => summary.leftToSpend;
  Poisha get free => leftToSpend - bills - slots;

  /// A day for the rest of the month, in whole taka; null when nothing is
  /// free.
  Poisha? get perDay =>
      free <= 0 ? null : (free / daysLeft / poishaPerTaka).round() * poishaPerTaka;

  /// Share of this month's budget spent, 0–1 (0 without a budget).
  double get spentShare =>
      summary.budget <= 0 ? 0 : (summary.expenses / summary.budget).clamp(0, 1).toDouble();
}
