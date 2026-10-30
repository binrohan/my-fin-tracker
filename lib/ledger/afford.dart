import 'dart:math' as math;

import '../core/money.dart';
import '../core/period.dart';
import 'enums.dart';
import 'ledger.dart';

enum AffordVerdict {
  /// Fits in money no budget is waiting for.
  yes,

  /// Fits in this month's money, but takes some that budgets still need.
  tight,

  /// Needs money from savings as well.
  fromSavings,

  /// More than this month's money and your savings together.
  saveUp,
}

/// Whether [amount] can be spent today, worked out from this month's
/// figures and your savings.
class Affordability {
  const Affordability({
    required this.amount,
    required this.summary,
    required this.daysLeft,
    required this.savings,
    required this.chargeBp,
    required this.monthlySpare,
  });

  factory Affordability.of(Ledger ledger, Poisha amount, DateTime today) {
    final period = Period.of(today);
    final savings =
        ledger
            .fundsOfKind(FundKind.savings)
            .fold<Poisha>(0, (t, f) => t + math.max(0, ledger.fundBalance(f.id))) +
        math.max<Poisha>(0, ledger.unplannedMoney);
    return Affordability(
      amount: amount,
      summary: ledger.summary(period),
      daysLeft: period.daysInMonth - today.day + 1,
      savings: savings,
      chargeBp: ledger.borrowChargeBp,
      monthlySpare: _monthlySpare(ledger, period),
    );
  }

  final Poisha amount;
  final PeriodSummary summary;
  final int daysLeft;

  /// Money in your savings pots (not goals) and in Unplanned.
  final Poisha savings;
  final int chargeBp;

  /// What a month usually leaves over (the average of the last three
  /// finished months); null when it is nothing or there is no history.
  final Poisha? monthlySpare;

  Poisha get leftToSpend => math.max(0, summary.leftToSpend);
  Poisha get planned => summary.budgetLeft;
  Poisha get unplanned => math.max(0, summary.unplanned);

  /// Left to spend after buying it (negative: the part not covered).
  Poisha get after => leftToSpend - amount;

  /// Budgeted money it would take.
  Poisha get fromBudgets => math.max(0, math.min(amount, leftToSpend) - unplanned);

  /// What would have to come from savings.
  Poisha get fromSavingsAmount => math.max(0, amount - leftToSpend);

  /// The charge on borrowing [fromSavingsAmount] from savings.
  Poisha get charge => (fromSavingsAmount * chargeBp / 10000).round();

  AffordVerdict get verdict {
    if (amount <= unplanned) return AffordVerdict.yes;
    if (amount <= leftToSpend) return AffordVerdict.tight;
    if (amount <= leftToSpend + savings) return AffordVerdict.fromSavings;
    return AffordVerdict.saveUp;
  }

  /// A day for the rest of the month after buying it, in whole taka.
  Poisha? get perDayAfter {
    if (after <= 0) return null;
    return (after / daysLeft / poishaPerTaka).round() * poishaPerTaka;
  }

  /// Months of usual leftover it takes to save the whole amount.
  int? get monthsToSave => monthlySpare == null ? null : (amount / monthlySpare!).ceil();
}

/// Income meant for the month minus what was spent and set aside, averaged
/// over the last three finished months that had entries.
Poisha? _monthlySpare(Ledger ledger, Period current) {
  final spares = <Poisha>[];
  for (var p = current.previous; spares.length < 3; p = p.previous) {
    if (!ledger.entries.any((e) => e.date.isBefore(p.end))) break;
    if (!ledger.entries.any((e) => p.contains(e.date) && e.type != EntryType.opening)) continue;
    final s = ledger.summary(p);
    spares.add(s.monthIncome - s.spendingExpenses - s.setAside);
  }
  if (spares.isEmpty) return null;
  final average = spares.fold<Poisha>(0, (t, v) => t + v) ~/ spares.length;
  return average > 0 ? average : null;
}
