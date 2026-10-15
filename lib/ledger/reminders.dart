import '../core/money.dart';
import '../core/period.dart';
import 'enums.dart';
import 'ledger.dart';

enum ReminderKind { income, bill, slot, loanOverdue, loanLong, maturity, backup }

/// Something that needs your attention, worst first.
class Reminder {
  const Reminder({
    required this.kind,
    required this.title,
    required this.detail,
    required this.urgent,
    this.id,
  });

  final ReminderKind kind;
  final String title;
  final String detail;

  /// Overdue or past due, rather than coming up.
  final bool urgent;

  /// The loan or investment account it is about.
  final int? id;
}

const backupSetting = 'last_backup_at';
const autoBackupSetting = 'last_auto_backup_at';

/// Bills due within [billDays] (or overdue), slots whose spending day is
/// that close (until their money is spent), loans past their due date,
/// own-savings loans open for 60+ days, investments maturing within 30
/// days, and no backup for 7+ days.
List<Reminder> remindersFor(Ledger ledger, DateTime today, {int billDays = 3}) {
  final day = dateOnly(today);
  final period = Period.of(day);
  final list = <Reminder>[];

  for (final income in ledger.incomesDue(day)) {
    final name = ledger.categories[income.categoryId]!.name;
    final where = ledger.accounts[income.accountId]?.name;
    list.add(
      Reminder(
        kind: ReminderKind.income,
        title: 'Has your $name arrived this month?',
        detail:
            'Expected around ${_date(DateTime(period.year, period.month, income.day!.clamp(1, period.daysInMonth)))}: '
            '${formatTaka(income.amount)}${where == null ? '' : ' in $where'} · tap to record',
        urgent: false,
        id: income.categoryId,
      ),
    );
  }

  for (final bill in ledger.unpaidFixedBills(period)) {
    final due = bill.category.dueDay;
    if (due == null) continue;
    final dueDate = DateTime(period.year, period.month, due.clamp(1, period.daysInMonth));
    final days = dueDate.difference(day).inDays;
    if (days > billDays) continue;
    list.add(
      Reminder(
        kind: ReminderKind.bill,
        title:
            '${bill.category.name} ${days < 0
                ? 'overdue'
                : days == 0
                ? 'due today'
                : 'due in $days ${days == 1 ? 'day' : 'days'}'}',
        detail: '${formatTaka(bill.remaining)} · due on the ${_ordinal(due)}',
        urgent: days <= 0,
      ),
    );
  }

  for (final slot in ledger.slotsIn(period)) {
    final on = slot.category.dueDay;
    if (on == null || slot.left <= 0) continue;
    final date = DateTime(period.year, period.month, on.clamp(1, period.daysInMonth));
    final days = date.difference(day).inDays;
    if (days > billDays) continue;
    list.add(
      Reminder(
        kind: ReminderKind.slot,
        title:
            '${slot.category.name} ${days < 0
                ? 'was planned for ${_date(date)}'
                : days == 0
                ? 'today'
                : 'in $days ${days == 1 ? 'day' : 'days'}'}',
        detail: slot.spent == 0
            ? '${formatTaka(slot.left)} set aside · ${_date(date)}'
            : '${formatTaka(slot.left)} left of ${formatTaka(slot.budget)} · ${_date(date)}',
        urgent: false,
        id: slot.category.id,
      ),
    );
  }

  for (final s in ledger.openLoans()) {
    final loan = s.loan;
    final who = ledger.accounts[loan.personAccountId]?.name;
    if (loan.dueDate != null && loan.dueDate!.isBefore(day)) {
      list.add(
        Reminder(
          kind: ReminderKind.loanOverdue,
          title: loan.kind == LoanKind.lent
              ? '$who has not paid you back'
              : 'Loan from ${who ?? 'savings'} is overdue',
          detail: '${formatTaka(s.remaining)} was due ${_date(loan.dueDate!)}',
          urgent: true,
          id: loan.id,
        ),
      );
    } else if (loan.kind == LoanKind.ownSavings && day.difference(loan.date).inDays >= 60) {
      list.add(
        Reminder(
          kind: ReminderKind.loanLong,
          title: 'Pay back ${ledger.funds[loan.fundId]?.name ?? 'savings'}',
          detail: '${formatTaka(s.remaining)} still owed, borrowed ${_date(loan.date)}',
          urgent: false,
          id: loan.id,
        ),
      );
    }
  }

  for (final i in ledger.maturingSoon(day)) {
    final days = i.daysToMaturity(day)!;
    list.add(
      Reminder(
        kind: ReminderKind.maturity,
        title:
            '${i.account.name} ${days < 0
                ? 'has matured'
                : days == 0
                ? 'matures today'
                : 'matures in $days days'}',
        detail: '${formatTaka(i.value)} to take out or renew',
        urgent: days <= 0,
        id: i.account.id,
      ),
    );
  }

  if (!ledger.isEmpty) {
    final last = [ledger.settings[backupSetting], ledger.settings[autoBackupSetting]]
        .map((v) => DateTime.tryParse(v ?? ''))
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    final days = last == null ? null : day.difference(dateOnly(last)).inDays;
    if (days == null || days >= 7) {
      list.add(
        Reminder(
          kind: ReminderKind.backup,
          title: days == null ? 'No backup yet' : 'Last backup $days days ago',
          detail: 'Keep a copy off this phone',
          urgent: days == null || days >= 30,
        ),
      );
    }
  }

  list.sort((a, b) => (b.urgent ? 1 : 0).compareTo(a.urgent ? 1 : 0));
  return list;
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String _date(DateTime d) => '${d.day} ${_months[d.month - 1]}';
