import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/insights.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const sep = Period(2026, 9);
  const oct = Period(2026, 10);
  const nov = Period(2026, 11);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  Poisha spent(DateTime from, DateTime before) => ledger.entries
      .where((e) => e.type == EntryType.expense && !e.date.isBefore(from) && e.date.isBefore(before))
      .fold(0, (t, e) => t + e.amount);

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  test('no comparison without last month', () {
    expect(compareMonths(ledger, sep), isNull);
  });

  test('a running month compares the same days of both months', () {
    final c = compareMonths(ledger, oct, today: DateTime(2026, 10, 8))!;
    expect(c.throughDay, 8);
    expect(c.now, spent(DateTime(2026, 10), DateTime(2026, 10, 9)));
    expect(c.before, spent(DateTime(2026, 9), DateTime(2026, 9, 9)));
  });

  test('a finished month compares whole months', () {
    final c = compareMonths(ledger, oct, today: DateTime(2026, 11, 2))!;
    expect(c.throughDay, isNull);
    expect(c.before, ledger.summary(sep).expenses);
    expect(c.now, ledger.summary(oct).expenses);
  });

  test('parents add up their sub-categories', () {
    final c = compareMonths(ledger, oct)!;
    for (final line in ledger.categoryLines(sep, CategoryKind.expense)) {
      expect(c.changes[line.category.id]?.before ?? 0, line.actual, reason: line.category.name);
    }
  });

  test('notable rises and falls', () async {
    final bank = ledger.accounts.values.firstWhere((a) => a.name == 'Bank').id;
    final from = (account: bank, fund: ledger.spendingFund.id);
    // December against November: Ration up, Mine down a little.
    for (final (date, name, amount) in [
      (DateTime(2026, 11, 3), 'Ration', 4000),
      (DateTime(2026, 11, 4), 'Mine', 2000),
      (DateTime(2026, 12, 3), 'Ration', 5000),
      (DateTime(2026, 12, 4), 'Mine', 1900),
    ]) {
      await repo.expense(date, taka(amount), categoryId: category(name), from: from);
    }
    await reload();
    final c = compareMonths(ledger, nov.next)!;
    final ration = c.changes[category('Ration')]!;
    expect((ration.now, ration.before, ration.diff), (taka(5000), taka(4000), taka(1000)));
    expect(ration.share, closeTo(.25, 1e-9));
    expect(ration.isNotable, isTrue);
    // ৳100 less is under the threshold.
    expect(c.changes[category('Mine')]!.isNotable, isFalse);
    expect(changeLabel(ration.diff, ration.share), '↑ 25%');
    expect(changeLabel(-taka(1200), null), '↓ ৳1,200');
  });
}
