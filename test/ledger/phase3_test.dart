import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  final today = DateTime(2026, 10, 8);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  List<({int account, Poisha amount})> goalMoney(int goal) => [
    for (final a in ledger.accountsOfType((t) => t.isLiquid)) (account: a.id, amount: ledger.cell(a.id, goal)),
  ];

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });

  tearDown(() => db.close());

  group('buying a goal', () {
    test('price above the goal: the rest comes from Spending', () async {
      final laptop = fund('New Laptop');
      await repo.buyGoal(
        goalId: laptop,
        spendingFund: fund('Spending'),
        payFromAccount: account('Bank'),
        goalMoney: goalMoney(laptop),
        date: today,
        price: taka(30000),
        categoryId: category('Random'),
        note: 'Laptop',
      );
      await reload();
      expect(ledger.fundBalance(laptop), 0);
      expect(ledger.fundBalance(fund('Spending')), taka(20920));
      expect(ledger.funds[laptop]!.achievedAt, today);
      expect(ledger.summary(const Period(2026, 10)).expenses, taka(62700));
      expect(ledger.isBalanced, isTrue);
    });

    test("goal money in cash is gathered into the paying account", () async {
      final bike = fund('Motorbike');
      await repo.buyGoal(
        goalId: bike,
        spendingFund: fund('Spending'),
        payFromAccount: account('Bank'),
        goalMoney: goalMoney(bike),
        date: today,
        price: taka(13000),
        categoryId: category('Random'),
      );
      await reload();
      expect(ledger.cell(account('Bank'), bike), 0);
      expect(ledger.cell(account('Cash'), bike), taka(1000));
      expect(ledger.fundBalance(fund('Spending')), taka(24420), reason: 'goal covered it all');
      expect(ledger.funds[bike]!.achievedAt, today);
    });

    test('achieved can be undone', () async {
      await repo.setGoalAchieved(fund('Motorbike'), today);
      await repo.setGoalAchieved(fund('Motorbike'), null);
      await reload();
      expect(ledger.funds[fund('Motorbike')]!.achievedAt, isNull);
    });
  });

  test('a goal\'s history, newest first', () {
    final history = ledger.fundHistory(fund('New Laptop'));
    expect([for (final h in history) h.amount], [taka(8000), taka(8000), taka(10500)]);
    expect(history.last.entry.type, EntryType.opening);
  });

  test('cash withdrawals do not show in the Spending history twice', () {
    final history = ledger.fundHistory(fund('Spending'));
    expect(history.where((h) => h.entry.note == 'Cash withdrawal'), isEmpty);
  });

  test('a loan\'s entries, oldest first', () {
    final own = ledger.loans.firstWhere((l) => l.kind == LoanKind.ownSavings);
    final entries = ledger.loanEntries(own.id);
    expect([for (final e in entries) e.type], [EntryType.borrow, EntryType.repay, EntryType.repay]);
    expect([for (final e in entries) e.amount], [taka(5000), taka(2000), taka(1000)]);
  });

  test('all loans, open first, newest first', () {
    final names = [
      for (final s in ledger.allLoans())
        s.loan.kind == LoanKind.ownSavings ? 'own' : ledger.accounts[s.loan.personAccountId]!.name,
    ];
    expect(names, ['own', 'Karim', 'Brother']);
  });

  test('deleting a loan removes its effect everywhere', () async {
    final own = ledger.loans.firstWhere((l) => l.kind == LoanKind.ownSavings);
    await repo.deleteLoan(own.id);
    await reload();
    expect(ledger.loans.where((l) => l.id == own.id), isEmpty);
    expect(ledger.entries.where((e) => e.loanId == own.id), isEmpty);
    expect(ledger.fundBalance(fund('Monthly Savings')), taka(70000));
    expect(ledger.fundBalance(fund('Spending')), taka(22420));
    expect(ledger.isBalanced, isTrue);
  });

  test('cash drawer sectors', () {
    final sectors = {for (final s in ledger.sectorsOf(account('Cash'))) s.fund.name: s.amount};
    expect(sectors, {'Spending': taka(2800), 'Monthly Savings': taka(2500), 'Motorbike': taka(2000)});
  });

  test('borrow charge comes from settings', () async {
    expect(ledger.borrowChargeBp, 500);
    await repo.setSetting('borrow_charge_bp', '300');
    await reload();
    expect(ledger.borrowChargeBp, 300);
  });
}
