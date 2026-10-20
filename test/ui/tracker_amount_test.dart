import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/trackers/trackers_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  late AppDatabase db;
  late Ledger ledger;
  late int trip;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    final l = await Ledger.load(db);
    trip = l.trackers.values.firstWhere((t) => t.name == 'Sylhet Trip').id;
    await LedgerRepository(db)
        .addTrackerAmount(trip, DateTime(2026, 10, 9), taka(3000), note: 'Paid by Abbu');
    ledger = await Ledger.load(db);
  });
  tearDown(() => db.close());

  for (final brightness in Brightness.values) {
    testWidgets('tracker shows outside amounts and adds one (${brightness.name})', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1080 / 384;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
            repositoryProvider.overrideWithValue(LedgerRepository(db)),
            todayProvider.overrideWithValue(DateTime(2026, 10, 20)),
          ],
          child: MaterialApp(
            theme: buildTheme(brightness),
            home: TrackerScreen(trackerId: trip),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Outside your accounts'), findsOneWidget, reason: 'by category row');
      await tester.scrollUntilVisible(find.text('Add amount'), 300);
      expect(find.text('OUTSIDE YOUR ACCOUNTS'), findsOneWidget);
      expect(find.textContaining('Paid by Abbu', findRichText: true), findsOneWidget);
      await tester.ensureVisible(find.text('Add amount'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add amount'));
      await tester.pumpAndSettle();
      expect(find.text('Add amount · Sylhet Trip'), findsOneWidget);
    });
  }
}
