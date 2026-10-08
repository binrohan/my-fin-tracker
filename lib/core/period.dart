import 'package:intl/intl.dart';

/// Strips the time part so dates compare by calendar day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One calendar month, from the 1st (inclusive) to the 1st of the next
/// month (exclusive).
class Period implements Comparable<Period> {
  const Period(this.year, this.month);

  factory Period.of(DateTime date) => Period(date.year, date.month);

  factory Period.current() => Period.of(DateTime.now());

  final int year;
  final int month;

  DateTime get start => DateTime(year, month);

  /// First day of the next month; dates before this belong to the period.
  DateTime get end => DateTime(year, month + 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  Period get next => Period.of(DateTime(year, month + 1));
  Period get previous => Period.of(DateTime(year, month - 1));

  /// "October 2026"
  String get label => DateFormat.yMMMM().format(start);

  /// "Oct 2026"
  String get shortLabel => DateFormat.yMMM().format(start);

  @override
  int compareTo(Period other) =>
      year != other.year ? year.compareTo(other.year) : month.compareTo(other.month);

  @override
  bool operator ==(Object other) => other is Period && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}
