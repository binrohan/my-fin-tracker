import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/free_to_spend.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// What the After bills Home and the widgets show.
void main() {
  late Ledger ledger;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await loadSampleData(db);
    ledger = await Ledger.load(db);
    await db.close();
  });

  test('left to spend minus bills still to pay', () {
    final f = FreeToSpend.of(ledger, DateTime(2026, 10, 8));
    expect(f.leftToSpend, taka(24420));
    expect(f.bills, taka(4000));
    expect(f.slots, 0);
    expect(f.free, taka(20420));
    expect(f.daysLeft, 24);
    expect(f.perDay, taka(851), reason: '20,420 / 24, whole taka');
    expect(f.spentShare, closeTo(f.summary.expenses / f.summary.budget, 1e-9));
  });

  test('the next bill is the nearest one still ahead', () {
    final f = FreeToSpend.of(ledger, DateTime(2026, 10, 8));
    expect(f.next, isNotNull);
    expect(f.next!.name, 'Water & Service');
    expect(f.next!.date, DateTime(2026, 10, 10));
  });
}
