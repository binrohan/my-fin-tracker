import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/reminders.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Ledger ledger;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    ledger = await Ledger.load(db);
  });
  tearDown(() => db.close());

  List<String> titles(DateTime day) => [for (final r in remindersFor(ledger, day)) r.title];

  test('on 8 Oct: water bill due soon, no backup yet', () {
    final list = remindersFor(ledger, DateTime(2026, 10, 8));
    expect(list.map((r) => r.title), ['No backup yet', 'Water & Service due in 2 days']);
    expect(list.last.detail, '${formatTaka(taka(1500))} · due on the 10th');
    expect(list.first.urgent, isTrue);
  });

  test('bills become overdue; paid bills disappear', () async {
    expect(
      titles(DateTime(2026, 10, 16)),
      containsAll(['Water & Service overdue', 'Electricity overdue']),
    );
    final repo = LedgerRepository(db);
    final bank = ledger.accounts.values.firstWhere((a) => a.name == 'Bank').id;
    final water = ledger.categories.values.firstWhere((c) => c.name == 'Water & Service').id;
    await repo.expense(
      DateTime(2026, 10, 9),
      taka(1500),
      categoryId: water,
      from: (account: bank, fund: ledger.spendingFund.id),
    );
    ledger = await Ledger.load(db);
    expect(titles(DateTime(2026, 10, 16)), isNot(contains('Water & Service overdue')));
  });

  test('a person loan past its due date', () {
    expect(titles(DateTime(2026, 12, 2)), contains('Karim has not paid you back'));
  });

  test('money borrowed from savings for 60 days', () {
    expect(titles(DateTime(2026, 11, 14)), contains('Pay back Monthly Savings'));
    expect(titles(DateTime(2026, 11, 12)), isNot(contains('Pay back Monthly Savings')));
  });

  test('an investment maturing within 30 days', () {
    expect(titles(DateTime(2029, 3, 1)), contains('Savings certificate matures in 14 days'));
  });

  test('a recent backup clears the backup reminder', () async {
    await LedgerRepository(db).setSetting(backupSetting, DateTime(2026, 10, 5).toIso8601String());
    ledger = await Ledger.load(db);
    expect(titles(DateTime(2026, 10, 8)), isNot(contains('No backup yet')));
    expect(titles(DateTime(2026, 10, 13)), contains('Last backup 8 days ago'));
  });
}
