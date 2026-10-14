import 'package:drift/drift.dart' hide isNull, isNotNull;
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
import 'package:my_fin_tracker/features/home/home_screen.dart';
import 'package:my_fin_tracker/features/sms/sms_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/sms.dart';

void main() {
  late AppDatabase db;
  late Ledger ledger;

  final inbox = [
    SmsMessage(
      sender: 'bKash',
      body: 'Payment Tk 450.00 to Shwapno successful. Balance Tk 763.50. TrxID BJ55AA11BB',
      date: DateTime(2026, 10, 7, 19, 40),
    ),
    SmsMessage(
      sender: 'CityBank',
      body:
          'Your A/C **1234 has been debited by BDT 5,000.00 for ATM withdrawal. '
          'Avl Bal BDT 2,01,651.00',
      date: DateTime(2026, 10, 6, 11),
    ),
    SmsMessage(
      sender: 'bKash',
      body: 'Your bKash verification code is 123456.',
      date: DateTime(2026, 10, 7),
    ),
    SmsMessage(sender: 'Nagad', body: 'Payment Tk 99.00 to Daraz.', date: DateTime(2026, 10, 7)),
    SmsMessage(
      sender: 'bKash',
      body: 'Payment Tk 120.00 to Tea stall successful.',
      date: DateTime(2026, 9, 20),
    ),
  ];

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    final repo = LedgerRepository(db);
    await repo.setSetting(smsOnSetting, 'true');
    await repo.setSetting(smsSinceSetting, DateTime(2026, 10).toIso8601String());
    ledger = await Ledger.load(db);
  });
  tearDown(() => db.close());

  test('only money messages from your senders since the start', () {
    final s = smsSuggestions(ledger, inbox);
    expect(
      [for (final x in s) (x.money.kind, x.money.amount)],
      [(SmsKind.expense, taka(450)), (SmsKind.toCash, taka(5000))],
    );
    expect(s.first.accountId, isNotNull, reason: 'linked to a wallet or bank by name');
  });

  test('added or dismissed messages are not suggested again', () async {
    final first = smsSuggestions(ledger, inbox).first;
    await LedgerRepository(db).setSetting(smsHandledSetting, encodeSmsHandled({first.money.key}));
    final again = smsSuggestions(await Ledger.load(db), inbox);
    expect(again.map((s) => s.money.amount), [taka(5000)]);
  });

  test('an entry of the same amount that day is flagged', () async {
    final s = smsSuggestions(ledger, inbox).first;
    final ration = ledger.categories.values.firstWhere((c) => c.name == 'Ration').id;
    await LedgerRepository(db).expense(
      DateTime(2026, 10, 7),
      taka(450),
      categoryId: ration,
      from: (account: s.accountId!, fund: ledger.spendingFund.id),
    );
    expect(smsSuggestions(await Ledger.load(db), inbox).first.maybeEntered, isTrue);
    expect(s.maybeEntered, isFalse);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
          smsInboxProvider.overrideWith((ref) async => inbox),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home says how many messages wait', (tester) async {
    await pump(tester, const Scaffold(body: HomeScreen()));
    expect(find.text('2 bank messages to add'), findsOneWidget);
  });

  testWidgets('Add opens quick add filled in', (tester) async {
    await pump(tester, const SmsScreen());
    expect(find.text('Paid · Shwapno'), findsOneWidget);
    expect(find.text('To cash'), findsOneWidget);
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('450', findRichText: true), findsWidgets);
    expect(find.widgetWithText(TextField, 'Shwapno'), findsOneWidget);
  });
}
