import 'package:flutter/services.dart';

import '../ledger/sms.dart';

/// The phone's SMS inbox, read through the app's own channel (see
/// MainActivity.kt). Nothing is sent anywhere; messages are only read.
class SmsInbox {
  static const _channel = MethodChannel('myfin/sms');

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Shows Android's permission prompt if needed.
  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Messages received from [since] on, newest first.
  static Future<List<SmsMessage>> read(DateTime since) async {
    try {
      final rows = await _channel.invokeListMethod<Map>('inbox', {
        'since': since.millisecondsSinceEpoch,
      });
      return [
        for (final r in rows ?? const <Map>[])
          SmsMessage(
            sender: r['sender'] as String,
            body: r['body'] as String,
            date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
          ),
      ];
    } on MissingPluginException {
      return const [];
    }
  }
}
