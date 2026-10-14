import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Receipt photos, kept as files in the app's own folder. An entry holds
/// only the file name; backups carry the photos with the data.
class ReceiptStore {
  ReceiptStore(this.folder);

  final Directory folder;

  static Future<ReceiptStore> onDevice() async =>
      ReceiptStore(Directory('${(await getApplicationDocumentsDirectory()).path}/receipts'));

  /// Names are made by [add]; anything else (a path, "..") is refused so a
  /// backup can't write outside the folder.
  static bool isValidName(String name) => RegExp(r'^[\w-]+\.[a-z]{2,4}$').hasMatch(name);

  File file(String name) => File('${folder.path}/$name');

  /// Copies [photo] into the folder and returns its new name.
  Future<String> add(File photo, {DateTime? now}) async {
    await folder.create(recursive: true);
    final dot = photo.path.lastIndexOf('.');
    final ext = dot < 0 ? 'jpg' : photo.path.substring(dot + 1).toLowerCase();
    final name =
        'receipt-${(now ?? DateTime.now()).microsecondsSinceEpoch}.'
        '${RegExp(r'^[a-z]{2,4}$').hasMatch(ext) ? ext : 'jpg'}';
    await photo.copy(file(name).path);
    return name;
  }

  Future<void> remove(String? name) async {
    if (name == null || !isValidName(name)) return;
    final f = file(name);
    if (await f.exists()) await f.delete();
  }

  /// The photos with these names that are still on the phone.
  Future<Map<String, Uint8List>> read(Iterable<String> names) async {
    final result = <String, Uint8List>{};
    for (final name in names.where(isValidName)) {
      final f = file(name);
      if (await f.exists()) result[name] = await f.readAsBytes();
    }
    return result;
  }

  /// Replaces every photo with [photos], as a restore does.
  Future<void> replaceAll(Map<String, Uint8List> photos) async {
    if (await folder.exists()) await folder.delete(recursive: true);
    await folder.create(recursive: true);
    for (final MapEntry(:key, :value) in photos.entries) {
      if (isValidName(key)) await file(key).writeAsBytes(value, flush: true);
    }
  }
}
