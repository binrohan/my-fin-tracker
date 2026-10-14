import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/afford.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  late Ledger ledger;
  final today = DateTime(2026, 10, 8);

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await loadSampleData(db);
    ledger = await Ledger.load(db);
    await db.close();
  });

  Affordability check(Poisha amount) => Affordability.of(ledger, amount, today);

  test('the example month', () {
    final a = check(taka(1000));
    expect(a.leftToSpend, taka(24420));
    expect(a.unplanned, ledger.summary(a.summary.period).unplanned.clamp(0, a.leftToSpend));
    expect(a.daysLeft, 24);
    expect(a.savings, greaterThan(0));
    expect(a.monthlySpare, isNotNull, reason: 'September is a finished month');
  });

  test('verdicts step up with the price', () {
    final base = check(1);
    final unplanned = base.unplanned;
    final left = base.leftToSpend;
    final savings = base.savings;
    expect(unplanned, greaterThan(0));

    expect(check(unplanned).verdict, AffordVerdict.yes);
    final tight = check(unplanned + taka(100));
    expect(tight.verdict, AffordVerdict.tight);
    expect(tight.fromBudgets, taka(100));

    final borrow = check(left + taka(2000));
    expect(borrow.verdict, AffordVerdict.fromSavings);
    expect(borrow.fromSavingsAmount, taka(2000));
    expect(borrow.charge, taka(100), reason: '5% of 2,000');
    expect(borrow.perDayAfter, isNull);

    expect(check(left + savings + 1).verdict, AffordVerdict.saveUp);
  });

  test('per day after buying', () {
    final a = check(taka(420));
    expect(a.after, taka(24000));
    expect(a.perDayAfter, taka(1000));
  });

  test('months to save', () {
    final spare = check(1).monthlySpare!;
    expect(check(spare * 10).monthsToSave, 10);
    expect(check(spare * 10 + 1).monthsToSave, 11);
  });
}
