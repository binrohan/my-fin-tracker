import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/tax.dart';

/// The app's tax figures, month by month: entries where there are some,
/// the Monthly plan for earlier months without entries and for the months
/// to come; each income type counted as salary, other taxable or not.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Ledger ledger;
  const year = IncomeYear(2026);
  final today = DateTime(2026, 10, 8);

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    ledger = await Ledger.load(db);
    final salary = ledger.categories.values.firstWhere((c) => c.name == 'Salary').id;
    await LedgerRepository(db).setSetting(
      AllocationPlan.settingKey,
      AllocationPlan(
        categoryId: salary,
        incomes: [IncomeSource(categoryId: salary, amount: taka(85000), day: 26)],
      ).encode(),
    );
    ledger = await Ledger.load(db);
  });
  tearDown(() => db.close());

  Poisha recorded(int category, Period p) => ledger.entries
      .where(
        (e) =>
            e.type == EntryType.income &&
            e.categoryId == category &&
            p.contains(e.date) &&
            !e.date.isAfter(today),
      )
      .fold(0, (t, e) => t + e.amount);

  test('every month of the year: recorded, else the plan', () {
    final main = ledger.latestPlan.categoryId!;
    final monthly = ledger.latestPlan.sourceFor(main)!.amount;
    var expected = 0, before = 0, after = 0, actual = 0;
    for (var p = Period.of(year.start); p.start.isBefore(year.end); p = p.next) {
      final r = recorded(main, p);
      actual += r;
      if (r > 0) {
        expected += r;
      } else {
        expected += monthly;
        if (p.compareTo(Period.of(today)) < 0) {
          before++;
        } else {
          after++;
        }
      }
    }
    final app = TaxFromApp.of(ledger, year, today);
    expect(app.salary, expected);
    expect(app.salarySoFar, actual);
    expect(app.monthsEstimated, before, reason: 'July, August and so on, before the example data');
    expect(app.monthsEstimated + app.monthsToCome + 12 - before - after, 12);
    expect(before, greaterThan(0));
    expect(app.salaryEstimated, monthly * before);
    expect(app.salaryToDate, actual + monthly * before);
  });

  test('a past year without entries is all estimate', () {
    final app = TaxFromApp.of(ledger, const IncomeYear(2024), today);
    final monthly = ledger.latestPlan.sourceFor(ledger.latestPlan.categoryId!)!.amount;
    expect(app.salary, monthly * 12);
    expect(app.monthsEstimated, 12);
    expect(app.monthsToCome, 0);
  });

  test('income types decide what counts', () async {
    final main = ledger.latestPlan.categoryId!;
    expect(incomeTaxType(ledger, main), IncomeTaxType.salary);
    final before = TaxFromApp.of(ledger, year, today);

    final repo = LedgerRepository(db);
    await repo.setSetting(
      incomeTaxTypesSetting,
      encodeIncomeTaxType(ledger, main, IncomeTaxType.exempt),
    );
    ledger = await Ledger.load(db);
    final exempt = TaxFromApp.of(ledger, year, today);
    expect(exempt.salary, 0);
    expect(exempt.other, before.other, reason: 'not taxable is left out, not moved');

    await repo.setSetting(
      incomeTaxTypesSetting,
      encodeIncomeTaxType(ledger, main, IncomeTaxType.taxable),
    );
    ledger = await Ledger.load(db);
    final other = TaxFromApp.of(ledger, year, today);
    expect(other.salary, 0);
    expect(other.other, before.other + before.salary);
  });
}
