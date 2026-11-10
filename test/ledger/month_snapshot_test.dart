import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/default_data.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/data/setup_repository.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/free_to_spend.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// A month keeps the plan, budgets and categories it began with: changes
/// made during it start next month.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late SetupRepository setup;
  late Ledger ledger;
  const oct = Period(2026, 10);
  const nov = Period(2026, 11);
  final day = DateTime(2026, 10, 8);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String n) => ledger.categories.values.firstWhere((c) => c.name == n).id;
  Map<String, Poisha> bills(Period p) => {
    for (final b in ledger.unpaidFixedBills(p)) b.category.name: b.remaining,
  };
  Iterable<CategoryLine> all(Period p) =>
      ledger.categoryLines(p, CategoryKind.expense).expand((l) => [l, ...l.children]);
  CategoryLine? line(Period p, String n) => all(p).where((l) => l.category.name == n).firstOrNull;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    setup = SetupRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  Future<void> snapshotOctober() async {
    await repo.ensureMonthSnapshot(oct);
    await reload();
    expect(ledger.hasSnapshot(oct), isTrue);
  }

  test('a snapshot alone changes nothing', () async {
    final before = FreeToSpend.of(ledger, day);
    final lines = all(oct).map((l) => (l.category.name, l.budget, l.actual)).toList();
    await snapshotOctober();
    final after = FreeToSpend.of(ledger, day);
    expect(after.bills, before.bills);
    expect(after.free, before.free);
    expect(after.summary.budget, before.summary.budget);
    expect(all(oct).map((l) => (l.category.name, l.budget, l.actual)).toList(), lines);
  });

  test('turning a fixed bill off or changing its due day waits for next month', () async {
    await snapshotOctober();
    await setup.updateCategory(category('Electricity'), isFixed: false, dueDay: const Value(3));
    await reload();
    expect(bills(oct), contains('Electricity'));
    expect(line(oct, 'Electricity')!.category.dueDay, isNot(3));
    expect(bills(nov), isNot(contains('Electricity')));
  });

  test('archiving keeps the bill this month, even without a month noted', () async {
    await snapshotOctober();
    await setup.updateCategory(category('Electricity'), archived: true);
    await reload();
    expect(bills(oct), contains('Electricity'));
    expect(bills(nov), isNot(contains('Electricity')));
  });

  test('a new section counts this month only if spent on', () async {
    await snapshotOctober();
    final budget = ledger.summary(oct).budget;
    final id = await setup.addCategory('Transport', CategoryKind.expense);
    await repo.setBudget(oct, id, taka(3000));
    await reload();
    expect(line(oct, 'Transport'), isNull);
    expect(ledger.summary(oct).budget, budget);
    expect(line(nov, 'Transport')!.budget, taka(3000));

    await repo.expense(
      day,
      taka(200),
      categoryId: id,
      from: (account: ledger.accounts.values.first.id, fund: ledger.spendingFund.id),
    );
    await reload();
    expect(line(oct, 'Transport')!.actual, taka(200));
    expect(line(oct, 'Transport')!.budget, 0);
  });

  test('budgets and the plan are frozen; Misc too', () async {
    await repo.setSetting(
      AllocationPlan.settingKey,
      AllocationPlan(categoryId: category('Salary'), expenseTarget: taka(80000)).encode(),
    );
    await repo.setSetting(
      miscCategorySetting,
      '${await setup.addCategory('Misc', CategoryKind.expense)}',
    );
    await reload();
    await snapshotOctober();
    final misc = ledger.miscBudget(oct);
    final ration = line(oct, 'Ration')!.budget;

    await repo.setBudget(oct, category('Ration'), taka(20000));
    await repo.setSetting(
      Ledger.planKeyFrom(oct),
      AllocationPlan(categoryId: category('Salary'), expenseTarget: taka(90000)).encode(),
    );
    await setup.updateCategory(category('Electricity'), archived: true);
    await reload();
    expect(line(oct, 'Ration')!.budget, ration);
    expect(ledger.planFor(oct).expenseTarget, taka(80000));
    expect(ledger.miscBudget(oct), misc);
    expect(line(nov, 'Ration')!.budget, taka(20000));
  });

  test('moving a subsection to its own section waits for next month', () async {
    await snapshotOctober();
    final rent = category('House Rent');
    final fixed = ledger.categories[rent]!.parentId;
    await (db.update(
      db.categories,
    )..where((c) => c.id.equals(rent))).write(const CategoriesCompanion(parentId: Value(null)));
    await reload();
    expect(line(oct, 'House Rent')!.category.parentId, fixed);
    expect(
      ledger.categoryLines(oct, CategoryKind.expense).map((l) => l.category.name),
      isNot(contains('House Rent')),
    );
    expect(
      ledger.categoryLines(nov, CategoryKind.expense).map((l) => l.category.name),
      contains('House Rent'),
    );
  });

  test('a pot link made during the month is used from next month', () async {
    await snapshotOctober();
    final laptop = ledger.funds.values.firstWhere((f) => f.name == 'New Laptop').id;
    await setup.updateCategory(category('Mine'), savingsFundId: Value(laptop));
    await reload();
    expect(ledger.unusedBudgetMoves(oct).where((m) => m.category.name == 'Mine'), isEmpty);
    expect(line(nov, 'Mine')!.category.savingsFundId, laptop);
  });

  test('without a snapshot the same pot link applies at once', () async {
    final laptop = ledger.funds.values.firstWhere((f) => f.name == 'New Laptop').id;
    await setup.updateCategory(category('Mine'), savingsFundId: Value(laptop));
    await reload();
    expect(ledger.unusedBudgetMoves(oct).where((m) => m.category.name == 'Mine'), isNotEmpty);
  });

  test('a snapshot is taken once and never replaced', () async {
    await snapshotOctober();
    final first = ledger.settings[Ledger.snapshotKey(oct)];
    await setup.updateCategory(category('Electricity'), isFixed: false);
    await repo.ensureMonthSnapshot(oct);
    await reload();
    expect(ledger.settings[Ledger.snapshotKey(oct)], first);
  });

  test('an unreadable snapshot falls back to the live values', () async {
    await repo.setSetting(Ledger.snapshotKey(oct), 'not json');
    await setup.updateCategory(category('Electricity'), isFixed: false);
    await reload();
    expect(bills(oct), isNot(contains('Electricity')));
  });
}
