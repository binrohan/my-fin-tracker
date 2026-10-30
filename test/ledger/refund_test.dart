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

/// A cancelled ticket: money back lowers what the category and the trip
/// spent, in the month it comes back.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);

  Future<void> reload() async => ledger = await Ledger.load(db);
  Poisha spent(String name, Period p) => ledger
      .categoryLines(p, CategoryKind.expense)
      .expand((l) => [l, ...l.children])
      .firstWhere((l) => l.category.name == name)
      .actual;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  test('full or part refund of a tagged expense', () async {
    final mine = ledger.categories.values.firstWhere((c) => c.name == 'Mine').id;
    final trip = ledger.trackers.values.firstWhere((t) => t.name == 'Sylhet Trip');
    final bank = ledger.accounts.values.firstWhere((a) => a.name == 'Bank').id;
    final from = (account: bank, fund: ledger.spendingFund.id);
    final id = await repo.expense(
      DateTime(2026, 10, 12),
      taka(1600),
      categoryId: mine,
      from: from,
      note: 'Ticket to Rajshahi',
      trackerId: trip.id,
    );
    await reload();
    final ticket = ledger.entries.firstWhere((e) => e.id == id);
    final mineSpent = spent('Mine', oct);
    final left = ledger.summary(oct).leftToSpend;
    final tripSpent = ledger.trackerStatus(trip).spent;

    // ৳200 cancellation fee kept: ৳1,400 back.
    await repo.refund(ticket, taka(1400), DateTime(2026, 10, 20), from);
    await reload();
    expect(spent('Mine', oct), mineSpent - taka(1400));
    expect(ledger.summary(oct).leftToSpend, left + taka(1400));
    expect(ledger.summary(oct).checks, isTrue);
    expect(ledger.trackerStatus(trip).spent, tripSpent - taka(1400));
    expect(ledger.isBalanced, isTrue);
    final refund = ledger.entries.firstWhere((e) => e.amount < 0);
    expect(refund.note, 'Refund: Ticket to Rajshahi');
  });
}
