import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';

import '../data/drive_backup.dart';

/// Only the app's own hidden folder in Drive: nothing else is visible.
const _scopes = ['https://www.googleapis.com/auth/drive.appdata'];

bool _ready = false;

/// A Drive access token. [interactive] asks you to choose an account and
/// allow access (only from a tap); otherwise null if you have not allowed it.
Future<String?> driveAccessToken({required bool interactive}) async {
  final signIn = GoogleSignIn.instance;
  if (!_ready) {
    await signIn.initialize();
    _ready = true;
  }
  final client = signIn.authorizationClient;
  final auth = interactive
      ? await client.authorizeScopes(_scopes)
      : await client.authorizationForScopes(_scopes);
  return auth?.accessToken;
}

/// Forgets the Drive access on this phone.
Future<void> disconnectDrive() async {
  try {
    await GoogleSignIn.instance.disconnect();
  } catch (_) {
    // Nothing to undo.
  }
}

/// The Drive key, in the app's private storage: not in the database, so it
/// is never inside a backup.
class DriveKeyStore {
  static Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/drive_key.json');

  static Future<DriveKey?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      return DriveKey.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(DriveKey key) async =>
      (await _file()).writeAsString(jsonEncode(key.toJson()), flush: true);

  static Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}
