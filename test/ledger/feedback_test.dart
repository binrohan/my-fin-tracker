import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/setup/starting_balances_screen.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/reminders.dart';

/// The four items in feedback.md, with the numbers given there.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('F1: starting balances in several banks', () {
    const cityBank = 1, bracBank = 2, cash = 3, spending = 10, savings = 11, laptop = 12;

    test('City Bank 20,000, BRAC Bank 75,000, cash 10,000', () {
      final pots = splitStartingBalances(
        totals: {cityBank: taka(20000), bracBank: taka(75000), cash: taka(10000)},
        saved: const [],
        spendingFund: spending,
      )!;
      expect(pots, [
        ((account: cityBank, fund: spending), taka(20000)),
        ((account: bracBank, fund: spending), taka(75000)),
        ((account: cash, fund: spending), taka(10000)),
      ]);
    });

    test('part of a bank is savings; the rest is for spending', () {
      final pots = splitStartingBalances(
        totals: {bracBank: taka(75000)},
        saved: [
          (fund: savings, account: bracBank, amount: taka(50000)),
          (fund: laptop, account: bracBank, amount: taka(15000)),
        ],
        spendingFund: spending,
      )!;
      expect(pots, [
        ((account: bracBank, fund: savings), taka(50000)),
        ((account: bracBank, fund: laptop), taka(15000)),
        ((account: bracBank, fund: spending), taka(10000)),
      ]);
    });

    test('savings bigger than the account are refused', () {
      final overdrawn = <int>[];
      expect(
        splitStartingBalances(
          totals: {cityBank: taka(20000)},
          saved: [(fund: savings, account: cityBank, amount: taka(25000))],
          spendingFund: spending,
          overdrawn: overdrawn,
        ),
        isNull,
      );
      expect(overdrawn, [cityBank]);
    });

    test('savings in an account with no amount entered are refused', () {
      final overdrawn = <int>[];
      expect(
        splitStartingBalances(
          totals: {cityBank: taka(20000)},
          saved: [(fund: savings, account: cash, amount: taka(1000))],
          spendingFund: spending,
          overdrawn: overdrawn,
        ),
        isNull,
      );
      expect(overdrawn, [cash]);
    });

    test('saved into the database as pots', () async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      );
      var l = await Ledger.load(db);
      final city = l.accounts.values.firstWhere((a) => a.name == 'Bank').id;
      final brac = await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: 'BRAC Bank', type: AccountType.bank));
      final cashId = l.accounts.values.firstWhere((a) => a.type == AccountType.cash).id;
      final ms = l.funds.values.firstWhere((f) => f.kind == FundKind.savings).id;
      final pots = splitStartingBalances(
        totals: {city: taka(20000), brac: taka(75000), cashId: taka(10000)},
        saved: [(fund: ms, account: brac, amount: taka(50000))],
        spendingFund: l.spendingFund.id,
      )!;
      await LedgerRepository(db).setStartingBalances(DateTime(2026, 11, 1), pots);
      l = await Ledger.load(db);
      expect(l.accountBalance(brac), taka(75000));
      expect(l.liquidTotal(), taka(105000));
      expect(l.fundBalance(ms), taka(50000));
      expect(l.summary(const Period(2026, 11)).carriedForward, taka(55000));
      await db.close();
    });
  });

  group('F2 + F3: monthly income and how it is split', () {
    test('income 50,000 + bonus 10,000; expenses 30,000, savings 10,000, laptop 20,000', () {
      const plan = AllocationPlan(
        categoryId: 1,
        incomes: [
          IncomeSource(categoryId: 1, amount: 5000000, day: 1, accountId: 7),
          IncomeSource(categoryId: 2, amount: 1000000, day: 15, accountId: 8),
        ],
        expenseTarget: 3000000,
        items: [
          AllocationItem(fundId: 3, amount: 1000000),
          AllocationItem(fundId: 4, amount: 2000000),
        ],
      );
      expect(plan.plannedIncome, taka(60000));
      expect(plan.total, taka(30000));
      expect(plan.unassigned, 0);
      final again = AllocationPlan.parse(plan.encode());
      expect(again.incomes.last.day, 15);
      expect(again.incomes.last.accountId, 8);
      expect(again.expenseTarget, taka(30000));
      expect(again.unassigned, 0);
    });

    test('a plan saved before incomes existed still loads', () {
      final old = AllocationPlan.parse('{"category":5,"items":[{"fund":3,"amount":2000000}]}');
      expect(old.categoryId, 5);
      expect(old.total, taka(20000));
      expect(old.incomes, isEmpty);
      expect(old.expenseTarget, isNull);
    });

    test('Home asks about an income from its day until it is recorded', () async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      );
      await loadSampleData(db);
      var l = await Ledger.load(db);
      final salary = l.categories.values.firstWhere((c) => c.name == 'Salary').id;
      final bonus = l.categories.values.firstWhere((c) => c.name == 'Bonus').id;
      final bank = l.accounts.values.firstWhere((a) => a.name == 'Bank').id;
      final repo = LedgerRepository(db);
      await repo.setSetting(
        AllocationPlan.settingKey,
        AllocationPlan(
          categoryId: salary,
          incomes: [
            IncomeSource(categoryId: salary, amount: taka(85000), day: 1, accountId: bank),
            IncomeSource(categoryId: bonus, amount: taka(10000), day: 5, accountId: bank),
          ],
        ).encode(),
      );
      l = await Ledger.load(db);
      // Salary already came on 1 Oct; the bonus has not.
      expect(l.incomesDue(DateTime(2026, 10, 4)), isEmpty);
      expect([for (final i in l.incomesDue(DateTime(2026, 10, 8))) i.categoryId], [bonus]);
      final reminder = remindersFor(
        l,
        DateTime(2026, 10, 8),
      ).firstWhere((r) => r.kind == ReminderKind.income);
      expect(reminder.title, 'Has your Bonus arrived this month?');
      expect(reminder.detail, 'Expected around 5 Oct: ৳10,000 in Bank · tap to record');

      await repo.income(
        DateTime(2026, 10, 8),
        taka(10000),
        categoryId: bonus,
        to: (account: bank, fund: l.spendingFund.id),
      );
      l = await Ledger.load(db);
      expect(l.incomesDue(DateTime(2026, 10, 8)), isEmpty);
      // Next month it asks again.
      expect([for (final i in l.incomesDue(DateTime(2026, 11, 2))) i.categoryId], [salary]);
      await db.close();
    });
  });

  group('F4: sections and subsections', () {
    test(
      'a section can have its own amount; without one it is the sum of its subsections',
      () async {
        final db = AppDatabase(
          DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
        );
        await loadSampleData(db);
        var l = await Ledger.load(db);
        const oct = Period(2026, 10);
        CategoryLine fixed() => l
            .categoryLines(oct, CategoryKind.expense)
            .firstWhere((c) => c.category.name == 'Fixed');
        expect(fixed().budget, taka(31280), reason: 'sum of its subsections');

        final repo = LedgerRepository(db);
        final fixedId = fixed().category.id;
        await repo.setBudget(oct, fixedId, taka(32000));
        l = await Ledger.load(db);
        expect(fixed().budget, taka(32000), reason: 'its own amount');

        await repo.setBudget(oct, fixedId, 0);
        l = await Ledger.load(db);
        expect(fixed().budget, taka(31280), reason: 'back to the sum');
        await db.close();
      },
    );

    test('a new subsection under a budgeted section', () async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      );
      await loadSampleData(db);
      var l = await Ledger.load(db);
      final ration = l.categories.values.firstWhere((c) => c.name == 'Ration');
      final fish = await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Fish & meat',
              kind: CategoryKind.expense,
              parentId: Value(ration.id),
            ),
          );
      await LedgerRepository(db).setBudget(const Period(2026, 10), fish, taka(6000));
      l = await Ledger.load(db);
      final line = l
          .categoryLines(const Period(2026, 10), CategoryKind.expense)
          .firstWhere((c) => c.category.name == 'Ration');
      expect(line.budget, taka(14000), reason: 'the section keeps its amount');
      expect(line.children.single.budget, taka(6000));
      await db.close();
    });
  });
}
