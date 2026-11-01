import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Every expected value here is a figure from the example report and the
/// screen designs in design/. If one of these fails, the app would show a
/// number that doesn't match the plan.
void main() {
  late AppDatabase db;
  late Ledger ledger;

  const sep = Period(2026, 9);
  const oct = Period(2026, 10);

  setUpAll(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    ledger = await Ledger.load(db);
  });

  tearDownAll(() => db.close());

  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  CategoryLine line(List<CategoryLine> lines, String name) =>
      lines.firstWhere((l) => l.category.name == name);

  group('September 2026 report, page 1', () {
    test('opening balances on 1 Sep', () {
      final before = sep.start;
      expect(ledger.accountBalance(account('Bank'), before: before), taka(42300));
      expect(ledger.accountBalance(account('Cash'), before: before), taka(6200));
      expect(ledger.accountBalance(account('bKash'), before: before), taka(1500));
      expect(ledger.liquidTotal(before: before), taka(50000));
    });

    test('summary tiles and reconciliation', () {
      final s = ledger.summary(sep);
      expect(s.openingLiquid, taka(50000));
      expect(s.income, taka(95000));
      expect(s.expenses, taka(54380));
      expect(s.invested, taka(5000));
      expect(s.closingLiquid, taka(85620));
      expect(s.openingLiquid + s.income - s.expenses - s.invested, s.closingLiquid);
      expect(ledger.netWorth(before: sep.end), taka(376240));
    });

    test('income by category', () {
      final income = ledger.categoryLines(sep, CategoryKind.income);
      expect(line(income, 'Salary').actual, taka(85000));
      expect(line(income, 'Bonus').actual, taka(10000));
    });

    test('expenses against budget', () {
      final lines = ledger.categoryLines(sep, CategoryKind.expense);
      final fixed = line(lines, 'Fixed');
      expect(fixed.budget, taka(31280));
      expect(fixed.actual, taka(30960));
      expect(line(fixed.children, 'House Rent').actual, taka(25000));
      expect(line(fixed.children, 'Electricity').actual, taka(2180));
      expect(line(fixed.children, 'Electricity').remaining, taka(320));

      expect(line(lines, 'Ration').actual, taka(13420));
      final random = line(lines, 'Random');
      expect(random.actual, taka(6850));
      expect(random.isOver, isTrue);
      expect(random.remaining, taka(-1850));
      expect((random.usage * 100).round(), 137);
      expect(line(lines, 'Mine').actual, taka(3150));

      final s = ledger.summary(sep);
      expect(s.budget, taka(54280));
      expect(s.expenses - s.budget, taka(100));
    });
  });

  group('September 2026 report, page 2', () {
    test('Monthly Savings and goals at month end', () {
      final end = sep.end;
      expect(ledger.fundBalance(fund('Monthly Savings'), before: end), taka(47000));
      expect(ledger.fundBalance(fund('New Laptop'), before: end), taka(18500));
      expect(ledger.fundBalance(fund('Motorbike'), before: end), taka(10000));
    });

    test('closing balances and cash by sector', () {
      final end = sep.end;
      expect(ledger.accountBalance(account('Bank'), before: end), taka(74920));
      expect(ledger.accountBalance(account('Cash'), before: end), taka(8700));
      expect(ledger.accountBalance(account('bKash'), before: end), taka(2000));

      final cash = account('Cash');
      expect(ledger.cell(cash, fund('This month'), before: end), taka(4200));
      expect(ledger.cell(cash, fund('Monthly Savings'), before: end), taka(2500));
      expect(ledger.cell(cash, fund('Motorbike'), before: end), taka(2000));
      expect(ledger.cell(account('Bank'), fund('This month'), before: end), taka(3920));
    });

    test('investments', () {
      expect(ledger.accountBalance(account('DPS · Bank'), before: sep.end), taka(94620));
      expect(ledger.investmentTotal(before: sep.end), taka(294620));
    });

    test('carried forward to October', () {
      final s = ledger.summary(sep);
      expect(s.carriedForward, taka(3500));
      expect(s.setAside, taka(37000));
      expect(s.loanNet, taka(3000)); // borrowed 5,000, repaid 2,000
      expect(s.leftToSpend, taka(10120));
      expect(s.checks, isTrue);
      expect(ledger.summary(oct).carriedForward, taka(10120));
    });
  });

  group('Loans', () {
    LoanStatus statusOf(LoanKind kind) =>
        ledger.loanStatus(ledger.loans.firstWhere((l) => l.kind == kind));

    test('borrowed from Monthly Savings with 5% charge', () {
      final own = statusOf(LoanKind.ownSavings);
      expect(own.loan.principal, taka(5000));
      expect(own.loan.charge, taka(250));
      expect(own.due, taka(5250));
      // 2,000 on 28 Sep + 1,000 on 5 Oct
      expect(own.repaid, taka(3000));
      expect(own.remaining, taka(2250));
      expect(ledger.owedToFund(fund('Monthly Savings')), taka(2250));
    });

    test('people', () {
      expect(statusOf(LoanKind.lent).remaining, taka(6000));
      expect(statusOf(LoanKind.borrowed).remaining, taka(10000));
      expect(ledger.accountBalance(account('Karim')), taka(6000));
      expect(ledger.accountBalance(account('Brother')), taka(-10000));
      expect(ledger.peopleNet(), taka(-4000));
    });
  });

  group('Home screen on 7 Oct 2026', () {
    test('left to spend and the month so far', () {
      final s = ledger.summary(oct);
      expect(s.leftToSpend, taka(24420));
      expect(s.income, taka(85000));
      expect(s.setAside, taka(37000));
      expect(s.expenses, taka(32700));
      expect(s.loanNet, taka(-1000));
      expect(s.checks, isTrue);
      expect(s.budget, taka(54280));
      expect(s.budgetLeft, taka(21580));
      expect(s.unplanned, taka(2840));
      // 8 Oct onwards: 24 days including today.
      expect(s.perDay(DateTime(2026, 10, 8)), taka(1018));
    });

    test('where it is and what it is for', () {
      expect(ledger.accountBalance(account('Bank')), taka(123970));
      expect(ledger.accountBalance(account('Cash')), taka(7300));
      expect(ledger.accountBalance(account('bKash')), taka(1650));
      expect(ledger.liquidTotal(), taka(132920));

      expect(ledger.fundBalance(fund('This month')), taka(24420));
      expect(ledger.fundBalance(fund('Monthly Savings')), taka(68000));
      expect(
        ledger.fundBalance(fund('New Laptop')) + ledger.fundBalance(fund('Motorbike')),
        taka(40500),
      );
      expect(ledger.isBalanced, isTrue);
    });

    test('cash drawer by sector', () {
      final cash = account('Cash');
      expect(ledger.cell(cash, fund('This month')), taka(2800));
      expect(ledger.cell(cash, fund('Monthly Savings')), taka(2500));
      expect(ledger.cell(cash, fund('Motorbike')), taka(2000));
    });

    test('net worth', () {
      expect(ledger.investmentTotal(), taka(299850));
      expect(ledger.netWorth(), taka(428770));
    });

    test('October expenses so far', () {
      final lines = ledger.categoryLines(oct, CategoryKind.expense);
      expect(line(lines, 'Fixed').actual, taka(27280));
      expect(line(lines, 'Ration').actual, taka(4350));
      expect(line(lines, 'Random').actual, taka(620));
      expect(line(lines, 'Mine').actual, taka(450));
    });
  });

  group('Goals on 7 Oct 2026', () {
    final today = DateTime(2026, 10, 7);
    GoalStatus goal(String name) =>
        ledger.goalStatus(ledger.funds.values.firstWhere((f) => f.name == name), today);

    test('New Laptop is behind', () {
      final g = goal('New Laptop');
      expect(g.saved, taka(26500));
      expect((g.progress * 1000).round(), 279); // 27.9%
      expect(g.monthsLeft, 5); // Nov to Mar
      expect(g.neededPerMonth, taka(13700));
      expect(g.monthly, taka(8000));
      expect(g.onTrack, isFalse);
      expect(g.projectedFinish, const Period(2027, 7));
    });

    test('Motorbike is on track', () {
      final g = goal('Motorbike');
      expect(g.saved, taka(14000));
      expect(g.neededPerMonth, taka(3579));
      expect(g.onTrack, isTrue);
    });
  });

  test('reset puts back only the defaults', () async {
    // A second, separate in-memory database is intended here.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final scratch = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await loadSampleData(scratch);
    await scratch.resetAllData();
    final empty = await Ledger.load(scratch);
    expect(empty.isEmpty, isTrue);
    expect(empty.accounts.values.map((a) => a.name), ['Bank', 'Cash', 'bKash']);
    expect(empty.netWorth(), 0);
    await scratch.close();
  });
}
