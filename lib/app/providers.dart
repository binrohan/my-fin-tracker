import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/period.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../data/setup_repository.dart';
import '../ledger/ledger.dart';

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
