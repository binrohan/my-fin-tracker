import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/period.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../data/receipts.dart';
import '../data/sms_inbox.dart';
import '../data/setup_repository.dart';
import '../ledger/ledger.dart';
import '../ledger/sms.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(databaseProvider)),
);

/// The whole ledger, recalculated after every change. Screens watch this,
/// so every figure updates the moment an entry is added.
final ledgerProvider = StreamProvider<Ledger>((ref) => Ledger.watch(ref.watch(databaseProvider)));

final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

final setupRepositoryProvider = Provider<SetupRepository>(
  (ref) => SetupRepository(ref.watch(databaseProvider)),
);

final receiptStoreProvider = FutureProvider<ReceiptStore>((ref) => ReceiptStore.onDevice());

/// Messages from the inbox since SMS suggestions were turned on. Read
/// again when the app comes back to the front.
final smsInboxProvider = FutureProvider<List<SmsMessage>>((ref) async {
  final since = await ref.watch(
    ledgerProvider.selectAsync(
      (l) => l.settings[smsOnSetting] == 'true' ? l.settings[smsSinceSetting] : null,
    ),
  );
  final from = DateTime.tryParse(since ?? '');
  if (from == null || !await SmsInbox.hasPermission()) return const [];
  return SmsInbox.read(from);
});

/// Money messages waiting to be added or dismissed.
final smsSuggestionsProvider = Provider<List<SmsSuggestion>>((ref) {
  final ledger = ref.watch(ledgerProvider).value;
  final inbox = ref.watch(smsInboxProvider).value;
  if (ledger == null || inbox == null || ledger.settings[smsOnSetting] != 'true') return const [];
  return smsSuggestions(ledger, inbox);
});
