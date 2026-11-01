import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'database.dart';
import 'default_data.dart';
import 'receipts.dart';

/// A backup is a zip (`.mft`) holding:
/// - `data.json`: every row of every table
/// - `manifest.json`: format and schema version, creation time, row counts
///   and the SHA-256 of `data.json`
/// - `receipts/`: receipt photos of the entries (from schema version 5)
///
/// Rows are stored as JSON rather than a copy of the SQLite file, so an
/// older backup can be read by a newer app after the schema changes.
class Backup {
  static const formatVersion = 1;
  static const fileExtension = 'mft';

  static String fileName(DateTime now) =>
      'myfin-${DateFormat('yyyy-MM-dd-HHmm').format(now)}.$fileExtension';

  /// The tables in the order they can be inserted without breaking
  /// references.
  static List<TableInfo> _tables(AppDatabase db) => [
    db.accounts,
    db.funds,
    db.categories,
    db.loans,
    db.entries,
    db.postings,
    db.budgets,
    db.monthCloses,
    db.settings,
    db.investmentDetails,
    db.purchases,
    db.trackers,
    db.budgetMoves,
    db.trackerAmounts,
  ];

  static const _receiptsPrefix = 'receipts/';

  /// Pass [receipts] to include the receipt photos.
  static Future<Uint8List> export(AppDatabase db, {DateTime? now, ReceiptStore? receipts}) async {
    final data = <String, List<Map<String, dynamic>>>{};
    for (final table in _tables(db)) {
      final rows = await db.select(table).get();
      data[table.actualTableName] = [for (final row in rows) (row as DataClass).toJson()];
    }
    final dataBytes = utf8.encode(jsonEncode(data));
    final manifest = BackupManifest(
      formatVersion: formatVersion,
      schemaVersion: db.schemaVersion,
      createdAt: now ?? DateTime.now(),
      counts: {for (final e in data.entries) e.key: e.value.length},
      sha256: sha256.convert(dataBytes).toString(),
    );

    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest.toJson())))
      ..addFile(ArchiveFile.bytes('data.json', dataBytes));
    if (receipts != null) {
      final names = [
        for (final row in data[db.entries.actualTableName]!)
          if (row['receipt'] case final String name) name,
      ];
      for (final MapEntry(:key, :value) in (await receipts.read(names)).entries) {
        archive.addFile(ArchiveFile.bytes('$_receiptsPrefix$key', value));
      }
    }
    return ZipEncoder().encodeBytes(archive);
  }

  /// Reads and checks a backup without changing anything.
  static BackupContents read(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupException('This file is not a My Fin Tracker backup.');
    }
    final manifestFile = archive.findFile('manifest.json');
    final dataFile = archive.findFile('data.json');
    if (manifestFile == null || dataFile == null) {
      throw const BackupException('This file is not a My Fin Tracker backup.');
    }
    final manifest = BackupManifest.fromJson(
      jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>,
    );
    if (manifest.formatVersion > formatVersion) {
      throw const BackupException(
        'This backup was made by a newer version of the app. Update the app, then restore.',
      );
    }
    final dataBytes = dataFile.content;
    if (sha256.convert(dataBytes).toString() != manifest.sha256) {
      throw const BackupException('This backup is damaged: its checksum does not match.');
    }
    final data = (jsonDecode(utf8.decode(dataBytes)) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()),
    );
    for (final MapEntry(:key, :value) in manifest.counts.entries) {
      if ((data[key]?.length ?? 0) != value) {
        throw const BackupException('This backup is damaged: record counts do not match.');
      }
    }
    final photos = {
      for (final f in archive.files)
        if (f.isFile && f.name.startsWith(_receiptsPrefix))
          f.name.substring(_receiptsPrefix.length): f.content,
    };
    return BackupContents(manifest, data, receipts: photos);
  }

  /// Replaces everything in the database with the backup. All or nothing:
  /// if any row fails, the database is left as it was.
  /// Pass [receipts] to replace the receipt photos too.
  static Future<void> restore(
    AppDatabase db,
    BackupContents backup, {
    ReceiptStore? receipts,
  }) async {
    final data = backup.data;
    List<Map<String, dynamic>> rows(TableInfo t) => data[t.actualTableName] ?? const [];

    await db.transaction(() async {
      await db.deleteEverything();
      await db.batch((b) {
        b.insertAll(db.accounts, rows(db.accounts).map(Account.fromJson));
        b.insertAll(db.funds, rows(db.funds).map(Fund.fromJson));
        // Parents before their sub-categories.
        final categories = rows(db.categories).map(CategoryRow.fromJson).toList()
          ..sort((a, b) => (a.parentId == null ? 0 : 1).compareTo(b.parentId == null ? 0 : 1));
        b.insertAll(db.categories, categories);
        b.insertAll(db.loans, rows(db.loans).map(Loan.fromJson));
        b.insertAll(db.entries, rows(db.entries).map(Entry.fromJson));
        b.insertAll(db.postings, rows(db.postings).map(Posting.fromJson));
        b.insertAll(db.budgets, rows(db.budgets).map(Budget.fromJson));
        b.insertAll(db.monthCloses, rows(db.monthCloses).map(MonthClose.fromJson));
        b.insertAll(db.settings, rows(db.settings).map(Setting.fromJson));
        // Missing from backups made before these tables existed: empty.
        b.insertAll(
          db.investmentDetails,
          rows(db.investmentDetails).map(InvestmentDetail.fromJson),
        );
        b.insertAll(db.purchases, rows(db.purchases).map(Purchase.fromJson));
        b.insertAll(db.trackers, rows(db.trackers).map(Tracker.fromJson));
        b.insertAll(db.budgetMoves, rows(db.budgetMoves).map(BudgetMove.fromJson));
        b.insertAll(db.trackerAmounts, rows(db.trackerAmounts).map(TrackerAmount.fromJson));
      });
      // Backups made before these existed.
      await setupFloatingAndMisc(db, DateTime.now());
    });
    await receipts?.replaceAll(backup.receipts);
  }
}

class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.counts,
    required this.sha256,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    formatVersion: json['format_version'] as int,
    schemaVersion: json['schema_version'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    counts: (json['counts'] as Map<String, dynamic>).cast<String, int>(),
    sha256: json['sha256'] as String,
  );

  final int formatVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final Map<String, int> counts;
  final String sha256;

  Map<String, dynamic> toJson() => {
    'app': 'My Fin Tracker',
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'created_at': createdAt.toIso8601String(),
    'counts': counts,
    'sha256': sha256,
  };
}

class BackupContents {
  const BackupContents(this.manifest, this.data, {this.receipts = const {}});

  final BackupManifest manifest;
  final Map<String, List<Map<String, dynamic>>> data;

  /// Receipt photos by file name.
  final Map<String, Uint8List> receipts;

  int count(String table) => manifest.counts[table] ?? 0;
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
