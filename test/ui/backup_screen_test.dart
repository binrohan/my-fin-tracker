import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/drive_backup.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/more/backup_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// The Google Drive card on Backup & restore.
void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {Map<String, String> settings = const {}}) async {
    final ledger = await tester.runAsync(() async {
      for (final MapEntry(:key, :value) in settings.entries) {
        await LedgerRepository(db).setSetting(key, value);
      }
      return Ledger.load(db);
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger!)),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 11, 9)),
        ],
        child: MaterialApp(theme: buildTheme(Brightness.light), home: const BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('GOOGLE DRIVE'), 300);
  }

  testWidgets('off: connect asks for a password twice, at least 8 characters', (tester) async {
    await pump(tester);
    final connect = find.text('Connect Google Drive');
    await tester.ensureVisible(connect);
    await tester.pumpAndSettle();
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(find.text('Choose a backup password'), findsOneWidget);
    FilledButton ok() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'));
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'short');
    await tester.pump();
    expect(ok().onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'long enough');
    await tester.enterText(find.widgetWithText(TextField, 'Same password again'), 'long enoug');
    await tester.pump();
    expect(ok().onPressed, isNull, reason: 'the two differ');
    await tester.enterText(find.widgetWithText(TextField, 'Same password again'), 'long enough');
    await tester.pump();
    expect(ok().onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('on: back up now, restore and turn off', (tester) async {
    await pump(
      tester,
      settings: {
        driveBackupOnSetting: 'true',
        driveBackupLastSetting: DateTime(2026, 11, 8, 9).toIso8601String(),
      },
    );
    expect(find.text('On'), findsOneWidget);
    expect(find.text('Back up to Drive now'), findsOneWidget);
    expect(find.text('Restore from Drive'), findsOneWidget);
    expect(find.text('Turn off'), findsOneWidget);
  });

  testWidgets('says when Drive needs signing in again', (tester) async {
    await pump(
      tester,
      settings: {
        driveBackupOnSetting: 'true',
        driveBackupErrorSetting: 'Connect Google Drive again to keep backing up.',
      },
    );
    expect(find.text('Needs you'), findsOneWidget);
    expect(find.text('Connect again and back up'), findsOneWidget);
  });
}
