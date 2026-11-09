import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:intl/intl.dart';

import 'backup.dart';
import 'database.dart';
import 'ledger_repository.dart';
import 'receipts.dart';

const driveBackupOnSetting = 'drive_backup_on';
const driveBackupLastSetting = 'drive_backup_last';
const driveBackupErrorSetting = 'drive_backup_error';

/// The key that locks backups sent to Google Drive, made from a password
/// only you know. Kept on this phone; the password itself is not.
class DriveKey {
  const DriveKey(this.salt, this.key);

  factory DriveKey.fromJson(Map<String, dynamic> j) =>
      DriveKey(base64Decode(j['salt'] as String), base64Decode(j['key'] as String));

  final List<int> salt;
  final List<int> key;

  Map<String, dynamic> toJson() => {'salt': base64Encode(salt), 'key': base64Encode(key)};
}

/// Encrypts a backup with AES-256-GCM. The file holds the salt, so the same
/// password opens it on a new phone:
/// `MFTE1` | salt (16) | nonce (12) | mac (16) | encrypted .mft.
class BackupCipher {
  static const _magic = 'MFTE1';
  static const _iterations = 120000;
  static final _aes = AesGcm.with256bits();

  static Future<DriveKey> deriveKey(String password, {List<int>? salt}) async {
    final s = salt ?? _random(16);
    final secret = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: s);
    return DriveKey(s, await secret.extractBytes());
  }

  static Future<Uint8List> encrypt(Uint8List plain, DriveKey key) async {
    final box = await _aes.encrypt(plain, secretKey: SecretKey(key.key), nonce: _random(12));
    return Uint8List.fromList([
      ...ascii.encode(_magic),
      ...key.salt,
      ...box.nonce,
      ...box.mac.bytes,
      ...box.cipherText,
    ]);
  }

  /// The .mft inside [data]; a wrong password or a damaged file throws.
  static Future<Uint8List> decrypt(Uint8List data, String password) async {
    if (data.length < 49 || ascii.decode(data.sublist(0, 5), allowInvalid: true) != _magic) {
      throw const BackupException('This is not an encrypted My Fin Tracker backup.');
    }
    final key = await deriveKey(password, salt: data.sublist(5, 21));
    try {
      final plain = await _aes.decrypt(
        SecretBox(data.sublist(49), nonce: data.sublist(21, 33), mac: Mac(data.sublist(33, 49))),
        secretKey: SecretKey(key.key),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const BackupException('Wrong password, or the backup is damaged.');
    }
  }

  static List<int> _random(int n) {
    final r = Random.secure();
    return [for (var i = 0; i < n; i++) r.nextInt(256)];
  }
}

class DriveFile {
  const DriveFile({required this.id, required this.name, required this.size, required this.at});

  final String id;
  final String name;
  final int size;
  final DateTime at;
}

/// Google said no: sign in to Drive again.
class DriveAuthException implements Exception {
  const DriveAuthException();
}

/// Files in the app's own hidden folder on Google Drive.
abstract class DriveStore {
  Future<List<DriveFile>> list();
  Future<void> upload(String name, Uint8List bytes);
  Future<Uint8List> download(String id);
  Future<void> delete(String id);
}

/// [DriveStore] over the Drive REST API, in the app data folder only
/// (scope `drive.appdata`): the app sees nothing else in your Drive.
class GoogleDriveStore implements DriveStore {
  GoogleDriveStore(this.accessToken, {HttpClient? client}) : _http = client ?? HttpClient();

  final String accessToken;
  final HttpClient _http;
  static const _api = 'https://www.googleapis.com';

  Future<(int, Uint8List)> _send(
    String method,
    String url, {
    List<int>? body,
    String? contentType,
  }) async {
    final request = await _http.openUrl(method, Uri.parse(url));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    if (contentType != null) request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    if (body != null) {
      request.contentLength = body.length;
      request.add(body);
    }
    final response = await request.close().timeout(const Duration(minutes: 2));
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    final bytes = builder.takeBytes();
    if (response.statusCode == 401 || response.statusCode == 403) throw const DriveAuthException();
    if (response.statusCode >= 300) {
      throw BackupException('Google Drive said ${response.statusCode}. Try again later.');
    }
    return (response.statusCode, bytes);
  }

  @override
  Future<List<DriveFile>> list() async {
    final (_, bytes) = await _send(
      'GET',
      '$_api/drive/v3/files?spaces=appDataFolder&pageSize=100'
          '&orderBy=createdTime%20desc&fields=files(id,name,size,createdTime)',
    );
    final files = (jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>)['files'] as List;
    return [
      for (final f in files.cast<Map<String, dynamic>>())
        DriveFile(
          id: f['id'] as String,
          name: f['name'] as String,
          size: int.tryParse('${f['size']}') ?? 0,
          at: DateTime.parse(f['createdTime'] as String).toLocal(),
        ),
    ];
  }

  @override
  Future<void> upload(String name, Uint8List bytes) async {
    const boundary = 'myfin-backup-boundary';
    final body = BytesBuilder(copy: false)
      ..add(
        utf8.encode(
          '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
          '${jsonEncode({
            'name': name,
            'parents': ['appDataFolder'],
          })}\r\n'
          '--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n',
        ),
      )
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--'));
    await _send(
      'POST',
      '$_api/upload/drive/v3/files?uploadType=multipart',
      body: body.takeBytes(),
      contentType: 'multipart/related; boundary=$boundary',
    );
  }

  @override
  Future<Uint8List> download(String id) async =>
      (await _send('GET', '$_api/drive/v3/files/$id?alt=media')).$2;

  @override
  Future<void> delete(String id) => _send('DELETE', '$_api/drive/v3/files/$id');
}

/// Sends encrypted backups to Google Drive and brings them back.
class DriveBackup {
  DriveBackup(this.db, this.drive, {this.receipts, this.keep = 8});

  final AppDatabase db;
  final DriveStore drive;
  final ReceiptStore? receipts;
  final int keep;

  static const every = Duration(days: 7);
  static const suffix = '.mft.enc';

  static String fileName(DateTime at) => 'myfin-${DateFormat('yyyy-MM-dd-HHmm').format(at)}$suffix';

  /// Whether a weekly upload is due, from the last one in [settings].
  static bool isDue(Map<String, String> settings, DateTime now) {
    if (settings[driveBackupOnSetting] != 'true') return false;
    final last = DateTime.tryParse(settings[driveBackupLastSetting] ?? '');
    return last == null || now.difference(last) >= every;
  }

  /// Uploads a backup now, locked with [key], and keeps only the newest [keep].
  Future<void> upload(DriveKey key, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final plain = await Backup.export(db, now: at, receipts: receipts);
    await drive.upload(fileName(at), await BackupCipher.encrypt(plain, key));
    final repo = LedgerRepository(db);
    await repo.setSetting(driveBackupLastSetting, at.toIso8601String());
    await repo.setSetting(driveBackupErrorSetting, '');
    final ours = (await drive.list()).where((f) => f.name.endsWith(suffix)).toList()
      ..sort((a, b) => b.name.compareTo(a.name));
    for (final old in ours.skip(keep)) {
      await drive.delete(old.id);
    }
  }

  /// Backups on Drive, newest first.
  Future<List<DriveFile>> backups() async =>
      (await drive.list()).where((f) => f.name.endsWith(suffix)).toList()
        ..sort((a, b) => b.name.compareTo(a.name));

  /// The backup in [file], opened with [password].
  Future<BackupContents> open(DriveFile file, String password) async =>
      Backup.read(await BackupCipher.decrypt(await drive.download(file.id), password));
}
