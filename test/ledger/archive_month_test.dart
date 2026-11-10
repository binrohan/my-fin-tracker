import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/data/setup_repository.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/free_to_spend.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Archiving a category keeps this month as it is (budget, bill still to
/// pay) and stops it from next month, like the Monthly plan.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);
  const nov = Period(2026, 11);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String n) => ledger.categories.values.firstWhere((c) => c.name == n).id;
  Map<String, Poisha> bills(Period p) => {
    for (final b in ledger.unpaidFixedBills(p)) b.category.name: b.remaining,
  };

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  Future<void> archive(String name, {String? from}) async {
    final id = category(name);
    await SetupRepository(db).updateCategory(id, archived: true);
    if (from != null) await repo.setSetting(Ledger.archivedFromKey(id), from);
    await reload();
  }

  test('an unpaid bill archived from next month is still due this month', () async {
    final before = FreeToSpend.of(ledger, DateTime(2026, 10, 8));
    expect(bills(oct), contains('Electricity'));

    await archive('Electricity', from: '2026-11');
    final after = FreeToSpend.of(ledger, DateTime(2026, 10, 8));
    expect(bills(oct), contains('Electricity'));
    expect(after.bills, before.bills);
    expect(after.free, before.free);
    expect(after.summary.budget, before.summary.budget);

    expect(bills(nov), isNot(contains('Electricity')));
    expect(
      ledger.categoryLines(nov, CategoryKind.expense).expand((l) => [l, ...l.children]),
      isNot(contains(predicate<CategoryLine>((l) => l.category.name == 'Electricity'))),
    );
  });

  test('archived before this version (no month) stays hidden everywhere', () async {
    await archive('Electricity');
    expect(bills(oct), isNot(contains('Electricity')));
  });

  test('Misc keeps its budget this month when a subsection is archived', () async {
    await repo.setSetting(
      AllocationPlan.settingKey,
      AllocationPlan(categoryId: category('Salary'), expenseTarget: taka(80000)).encode(),
    );
    await repo.setSetting(
      'misc_category',
      '${await SetupRepository(db).addCategory('Misc', CategoryKind.expense)}',
    );
    await reload();
    final misc = ledger.miscBudget(oct);

    await archive('Electricity', from: '2026-11');
    expect(ledger.miscBudget(oct), misc);
  });

  test('quick add hides it at once', () async {
    await archive('Electricity', from: '2026-11');
    final names = ledger.leafCategories(CategoryKind.expense, month: oct).map((c) => c.name);
    expect(names, isNot(contains('Electricity')));
  });
}
