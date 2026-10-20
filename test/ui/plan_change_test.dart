import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/plan/monthly_plan_screen.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    final l = await Ledger.load(db);
    final salary = l.categories.values.firstWhere((c) => c.name == 'Salary').id;
    await LedgerRepository(db).setSetting(
      AllocationPlan.settingKey,
      AllocationPlan(
        categoryId: salary,
        incomes: [IncomeSource(categoryId: salary, amount: taka(85000), day: 26)],
      ).encode(),
    );
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester) async {
    final ledger = await tester.runAsync(() => Ledger.load(db));
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger!)),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 20)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const MonthlyPlanScreen())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Save asks when; From November leaves October alone', (tester) async {
    await open(tester);
    expect(find.text('From November'), findsNothing, reason: 'no switch any more');

    await tester.enterText(find.widgetWithText(TextField, '85,000'), '100000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('When should this apply?'), findsOneWidget);
    await tester.tap(find.text('From November'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();

    final after = await tester.runAsync(() => Ledger.load(db));
    expect(after!.planChanges, [const Period(2026, 11)]);
    expect(after.planFor(const Period(2026, 10)).plannedIncome, taka(85000));
    expect(after.planFor(const Period(2026, 11)).plannedIncome, taka(100000));
  });

  testWidgets('waiting changes show on top, with view and cancel', (tester) async {
    await tester.runAsync(() async {
      final l = await Ledger.load(db);
      final salary = l.categories.values.firstWhere((c) => c.name == 'Salary').id;
      await LedgerRepository(db).setSetting(
        Ledger.planKeyFrom(const Period(2026, 11)),
        AllocationPlan(
          categoryId: salary,
          incomes: [IncomeSource(categoryId: salary, amount: taka(100000), day: 26)],
        ).encode(),
      );
    });
    await open(tester);
    expect(find.text('CHANGES FROM NOVEMBER 2026'), findsOneWidget);
    expect(find.text('৳85,000 → ৳1,00,000'), findsOneWidget);

    await tester.tap(find.text('View / edit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('October keeps its plan'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1,00,000'), findsOneWidget);
    await tester.tap(find.text('Back to October'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel changes'));
    await tester.pumpAndSettle();
    final after = await tester.runAsync(() => Ledger.load(db));
    expect(after!.planChanges, isEmpty);
  });
}
