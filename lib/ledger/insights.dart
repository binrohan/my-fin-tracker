import '../core/money.dart';
import '../core/period.dart';
import '../data/database.dart';
import 'enums.dart';
import 'ledger.dart';

const insightsOffSetting = 'insights_off';

/// A change is worth showing when it is at least this share of last
/// month's amount and at least [notableAmount].
const notableShare = .10;
final Poisha notableAmount = taka(300);

/// Spending in one category this month against the same days last month.
class CategoryChange {
  const CategoryChange({required this.category, required this.now, required this.before});

  final CategoryRow category;
  final Poisha now;
  final Poisha before;

  Poisha get diff => now - before;

  /// Change as a share of last month; null when nothing was spent then.
  double? get share => before == 0 ? null : diff / before;

  bool get isNotable => before > 0 && diff.abs() >= notableAmount && (share!.abs() >= notableShare);
}

/// This month's expenses against last month's. While a month is running
/// it compares like with like: the 1st to [throughDay] of both months.
class MonthComparison {
  const MonthComparison({
    required this.period,
    required this.throughDay,
    required this.now,
    required this.before,
    required this.changes,
  });

  final Period period;
  Period get previous => period.previous;

  /// Last day compared in both months; null for whole months.
  final int? throughDay;

  final Poisha now;
  final Poisha before;

  /// Every expense category spent on in either month, parents included.
  /// Slots are left out: they exist for one month only.
  final Map<int, CategoryChange> changes;

  Poisha get diff => now - before;
  double? get share => before == 0 ? null : diff / before;

  /// The biggest rises and falls among top-level categories, largest first.
  List<CategoryChange> rises([int count = 3]) => _top((c) => c.diff > 0, count);
  List<CategoryChange> falls([int count = 2]) => _top((c) => c.diff < 0, count);

  List<CategoryChange> _top(bool Function(CategoryChange) test, int count) =>
      (changes.values.where((c) => c.category.parentId == null && c.isNotable && test(c)).toList()
            ..sort((a, b) => b.diff.abs().compareTo(a.diff.abs())))
          .take(count)
          .toList();
}

/// Compares [period] with the month before. Pass [today] while [period] is
/// running to compare only the days so far. Null when last month has no
/// expenses to compare with.
MonthComparison? compareMonths(Ledger ledger, Period period, {DateTime? today}) {
  final previous = period.previous;
  int? throughDay;
  if (today != null && period.contains(today) && today.day < period.daysInMonth) {
    throughDay = today.day;
  }
  DateTime endOf(Period p) => throughDay == null || throughDay >= p.daysInMonth
      ? p.end
      : DateTime(p.year, p.month, throughDay + 1);

  final now = _spent(ledger, period.start, endOf(period));
  final before = _spent(ledger, previous.start, endOf(previous));
  if (before.isEmpty) return null;

  // Roll each category's spending up to its parents.
  Map<int, Poisha> rolledUp(Map<int, Poisha> own) {
    final total = <int, Poisha>{};
    own.forEach((id, amount) {
      int? at = id;
      while (at != null) {
        total.update(at, (v) => v + amount, ifAbsent: () => amount);
        at = ledger.categories[at]?.parentId;
      }
    });
    return total;
  }

  final nowAll = rolledUp(now);
  final beforeAll = rolledUp(before);
  return MonthComparison(
    period: period,
    throughDay: throughDay,
    now: now.values.fold(0, (t, v) => t + v),
    before: before.values.fold(0, (t, v) => t + v),
    changes: {
      for (final id in {...nowAll.keys, ...beforeAll.keys})
        if (ledger.categories[id] case final c? when !ledger.isSlot(c))
          id: CategoryChange(category: c, now: nowAll[id] ?? 0, before: beforeAll[id] ?? 0),
    },
  );
}

Map<int, Poisha> _spent(Ledger ledger, DateTime from, DateTime before) {
  final result = <int, Poisha>{};
  for (final e in ledger.entries) {
    if (e.type == EntryType.expense &&
        e.categoryId != null &&
        !e.date.isBefore(from) &&
        e.date.isBefore(before)) {
      result.update(e.categoryId!, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
  }
  return result;
}

/// "↑ 25%" or "↓ 8%"; "↑ ৳1,200" when last month had nothing.
String changeLabel(Poisha diff, double? share) {
  final arrow = diff >= 0 ? '↑' : '↓';
  if (share == null) return '$arrow ${formatTaka(diff.abs())}';
  return '$arrow ${(share.abs() * 100).round()}%';
}
