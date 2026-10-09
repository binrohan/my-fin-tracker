import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Closing a month with the leftover split between pots and goals.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Ledger ledger;
  const sep = Period(2026, 9);
  const oct = Period(2026, 10);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  test('Spending money at month end: banks first, then the largest', () {
    expect(ledger.spendingCells(sep), [
      (account: account('Bank'), amount: taka(3920)),
      (account: account('Cash'), amount: taka(4200)),
      (account: account('bKash'), amount: taka(2000)),
    ]);
  });

  test('3,000 to Monthly Savings, 2,000 to New Laptop, the rest carried forward', () async {
    await LedgerRepository(db).closeMonth(
      sep,
      spendingFund: ledger.spendingFund.id,
      leftoverTo: [
        (fund: fund('Monthly Savings'), amount: taka(3000)),
        (fund: fund('New Laptop'), amount: taka(2000)),
      ],
      leftovers: ledger.spendingCells(sep),
    );
    await reload();
    expect(ledger.isClosed(sep), isTrue);
    expect(ledger.summary(oct).carriedForward, taka(5120));
    expect(ledger.fundBalance(fund('Monthly Savings'), before: sep.end), taka(50000));
    expect(ledger.fundBalance(fund('New Laptop'), before: sep.end), taka(20500));
    // Money stays where it is: the bank's 3,920 first, then cash.
    expect(ledger.cell(account('Bank'), fund('New Laptop'), before: sep.end), taka(18500 + 920));
    expect(ledger.cell(account('Cash'), fund('New Laptop'), before: sep.end), taka(1080));
    expect(ledger.liquidTotal(before: sep.end), taka(85620));
  });

  test('nothing split: everything carried forward', () async {
    await LedgerRepository(
      db,
    ).closeMonth(sep, spendingFund: ledger.spendingFund.id, leftovers: ledger.spendingCells(sep));
    await reload();
    expect(ledger.summary(oct).carriedForward, taka(10120));
  });

  test('asking for more than is left moves only what is there', () async {
    await LedgerRepository(db).closeMonth(
      sep,
      spendingFund: ledger.spendingFund.id,
      leftoverTo: [(fund: fund('Monthly Savings'), amount: taka(15000))],
      leftovers: ledger.spendingCells(sep),
    );
    await reload();
    expect(ledger.summary(oct).carriedForward, 0);
    expect(ledger.fundBalance(fund('Monthly Savings'), before: sep.end), taka(57120));
  });
}
