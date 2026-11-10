import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/drive_backup.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Drive in memory.
class FakeDrive implements DriveStore {
  final files = <String, (String, Uint8List, DateTime)>{};
  var _next = 0;

  @override
  Future<List<DriveFile>> list() async => [
    for (final MapEntry(key: id, value: (name, bytes, at)) in files.entries)
      DriveFile(id: id, name: name, size: bytes.length, at: at),
  ];

  @override
  Future<void> upload(String name, Uint8List bytes) async =>
      files['${_next++}'] = (name, bytes, DateTime.now());

  @override
  Future<Uint8List> download(String id) async => files[id]!.$2;

  @override
  Future<void> delete(String id) async => files.remove(id);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
  });
  tearDown(() => db.close());

  test('a password locks and opens a backup; a wrong one does not', () async {
    final plain = Uint8List.fromList(List.generate(5000, (i) => i % 251));
    final key = await BackupCipher.deriveKey('correct horse');
    final locked = await BackupCipher.encrypt(plain, key);
    expect(locked.sublist(49), isNot(plain), reason: 'not stored in the clear');
    expect(await BackupCipher.decrypt(locked, 'correct horse'), plain);
    expect(() => BackupCipher.decrypt(locked, 'wrong horse'), throwsA(isA<BackupException>()));
    expect(
      () => BackupCipher.decrypt(Uint8List.fromList(plain), 'correct horse'),
      throwsA(isA<BackupException>()),
    );
  });

  test('uploads weekly backups, keeps the newest, and restores one', () async {
    final drive = FakeDrive();
    final backup = DriveBackup(db, drive, keep: 3);
    final key = await BackupCipher.deriveKey('my password');
    for (var d = 1; d <= 5; d++) {
      await backup.upload(key, now: DateTime(2026, 11, d, 9));
    }
    final kept = await backup.backups();
    expect(kept.map((f) => f.name), [
      'myfin-2026-11-05-0900.mft.enc',
      'myfin-2026-11-04-0900.mft.enc',
      'myfin-2026-11-03-0900.mft.enc',
    ]);
    final ledger = await Ledger.load(db);
    expect(ledger.settings[driveBackupLastSetting], DateTime(2026, 11, 5, 9).toIso8601String());

    final contents = await backup.open(kept.first, 'my password');
    expect(contents.count('entries'), ledger.entries.length);
    expect(() => backup.open(kept.first, 'not it'), throwsA(isA<BackupException>()));
  });

  test('due weekly, and only when it is on', () {
    final now = DateTime(2026, 11, 9);
    expect(DriveBackup.isDue({}, now), isFalse);
    expect(DriveBackup.isDue({driveBackupOnSetting: 'true'}, now), isTrue);
    expect(
      DriveBackup.isDue({
        driveBackupOnSetting: 'true',
        driveBackupLastSetting: DateTime(2026, 11, 5).toIso8601String(),
      }, now),
      isFalse,
    );
    expect(
      DriveBackup.isDue({
        driveBackupOnSetting: 'true',
        driveBackupLastSetting: DateTime(2026, 11, 2).toIso8601String(),
      }, now),
      isTrue,
    );
  });
}
