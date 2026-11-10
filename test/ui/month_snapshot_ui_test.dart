import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/setup/category_editor.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Editing a category keeps this month as it began.
void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
  });
  tearDown(() => db.close());

  testWidgets('turning a fixed bill off leaves it due this month', (tester) async {
    final ledger = (await tester.runAsync(() => Ledger.load(db)))!;
    final electricity = ledger.categories.values.firstWhere((c) => c.name == 'Electricity');
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showCategoryEditor(context, ref, ledger, existing: electricity),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixed bill'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    final after = (await tester.runAsync(() => Ledger.load(db)))!;
    expect(after.categories[electricity.id]!.isFixed, isFalse);
    expect(after.hasSnapshot(const Period(2026, 10)), isTrue);
    final names = after.unpaidFixedBills(const Period(2026, 10)).map((b) => b.category.name);
    expect(names, contains('Electricity'));
    expect(
      after.unpaidFixedBills(const Period(2026, 11)).map((b) => b.category.name),
      isNot(contains('Electricity')),
    );
  });
}
