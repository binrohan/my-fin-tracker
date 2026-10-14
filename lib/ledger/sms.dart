import 'dart:convert';

import '../core/money.dart';
import '../data/database.dart';
import 'enums.dart';
import 'ledger.dart';

const smsOnSetting = 'sms_on';
const smsSinceSetting = 'sms_since';
const smsHandledSetting = 'sms_handled';
const smsSendersSetting = 'sms_senders';

/// What a money message is about.
enum SmsKind {
  expense,
  income,

  /// Cash out from bKash or an ATM withdrawal: money to your cash.
  toCash,
}

/// A text message as read from the phone's inbox.
class SmsMessage {
  const SmsMessage({required this.sender, required this.body, required this.date});

  final String sender;
  final String body;
  final DateTime date;
}

/// A message that looks like money moving, ready to become an entry.
class SmsMoney {
  const SmsMoney({
    required this.message,
    required this.kind,
    required this.amount,
    this.fee = 0,
    this.balance,
    this.party,
    this.reference,
  });

  final SmsMessage message;
  final SmsKind kind;
  final Poisha amount;

  /// A charge mentioned in the message (bKash cash-out fee).
  final Poisha fee;

  /// The balance the message reports afterwards.
  final Poisha? balance;

  /// Shop, person or number the money went to or came from.
  final String? party;

  /// TrxID or reference number.
  final String? reference;

  /// Same message, same key: used to remember what was added or dismissed.
  String get key =>
      '${message.sender.toLowerCase()}|${message.date.millisecondsSinceEpoch}|$amount';
}

final _amount = RegExp(r'(?:tk\.?|bdt|৳)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false);
final _notMain = RegExp(
  r'\b(bal(ance)?|avl|available|fee|charge|vat|limit|lmt|due)\b\W*\w*\W*$',
  caseSensitive: false,
);
final _balance = RegExp(
  r'(?:balance|bal\.?)\D{0,24}?(?:tk\.?|bdt|৳)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
  caseSensitive: false,
);
final _fee = RegExp(
  r'(?:fee|charge)\D{0,12}?(?:tk\.?|bdt|৳)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
  caseSensitive: false,
);
final _reference = RegExp(
  r'(?:trx\s*id|txn\s*id|ref(?:erence)?\.?(?:\s*no)?)[:\s]*([A-Z0-9]{6,})',
  caseSensitive: false,
);
final _party = RegExp(
  r'\b(?:at|to|from)\s+([A-Za-z0-9][A-Za-z0-9 &.\-]{1,40}?)(?=[.,;]|\s+(?:on|ref|trx|txn|via|fee|balance|bal|at|is|was|successful)\b|$)',
  caseSensitive: false,
);
final _ignore = RegExp(
  r'\b(otp|one[- ]time|verification code|password|pin|failed|unsuccessful|declined|reversed|offer|cashback offer)\b',
  caseSensitive: false,
);

const _toCashWords = ['cash out', 'cashout', 'atm', 'withdrawn', 'withdrawal'];
const _outWords = [
  'debited',
  'debit',
  'payment',
  'paid',
  'purchase',
  'spent',
  'sent',
  'send money',
  'transferred to',
  'transfer to',
  'bill pay',
  'recharge',
  'transaction of',
  'pos',
];
const _inWords = [
  'credited',
  'credit',
  'received',
  'deposited',
  'deposit',
  'cash in',
  'refund',
  'salary',
  'add money',
];

Poisha? _taka(String text) => parseTaka(text.replaceAll(',', ''));

/// Reads a bank or bKash message. Null when it isn't about money moving
/// (an OTP, an offer, a failed transaction).
SmsMoney? parseSms(SmsMessage message) {
  final body = message.body.replaceAll(RegExp(r'\s+'), ' ');
  if (_ignore.hasMatch(body)) return null;
  final lower = body.toLowerCase();

  Poisha? amount;
  for (final m in _amount.allMatches(body)) {
    final before = body.substring((m.start - 24).clamp(0, m.start), m.start);
    if (_notMain.hasMatch(before)) continue;
    amount = _taka(m.group(1)!);
    if (amount != null && amount > 0) break;
    amount = null;
  }
  if (amount == null) return null;

  int firstOf(List<String> words) {
    var best = -1;
    for (final w in words) {
      final i = RegExp('\\b${RegExp.escape(w)}\\b').firstMatch(lower)?.start ?? -1;
      if (i >= 0 && (best < 0 || i < best)) best = i;
    }
    return best;
  }

  final cash = firstOf(_toCashWords);
  final out = firstOf(_outWords);
  final into = firstOf(_inWords);
  final SmsKind kind;
  if (cash >= 0 && (into < 0 || cash <= into)) {
    kind = SmsKind.toCash;
  } else if (out >= 0 && (into < 0 || out < into)) {
    kind = SmsKind.expense;
  } else if (into >= 0) {
    kind = SmsKind.income;
  } else {
    return null;
  }

  final balance = _balance.firstMatch(body);
  final fee = _fee.firstMatch(body);
  final party = _party.firstMatch(body)?.group(1)?.trim();
  return SmsMoney(
    message: message,
    kind: kind,
    amount: amount,
    fee: fee == null ? 0 : _taka(fee.group(1)!) ?? 0,
    balance: balance == null ? null : _taka(balance.group(1)!),
    party: party == null || RegExp(r'^(your|the|a|you)$', caseSensitive: false).hasMatch(party)
        ? null
        : party,
    reference: _reference.firstMatch(body)?.group(1),
  );
}

/// A sender to read, and the account its messages are about.
class SmsSender {
  const SmsSender(this.match, this.accountId);

  /// Part of the sender's name or number, e.g. "bKash" or "CityBank".
  final String match;
  final int? accountId;

  bool matches(String sender) =>
      sender.toLowerCase().replaceAll(' ', '').contains(match.toLowerCase().replaceAll(' ', ''));

  Map<String, dynamic> toJson() => {'match': match, 'account': ?accountId};
}

/// Senders from the setting, or bKash and City Bank linked to the
/// accounts whose names fit.
List<SmsSender> smsSenders(Ledger ledger) {
  final json = ledger.settings[smsSendersSetting];
  if (json != null && json.isNotEmpty) {
    try {
      return [
        for (final s in jsonDecode(json) as List)
          SmsSender((s as Map)['match'] as String, s['account'] as int?),
      ];
    } catch (_) {}
  }
  int? account(String name, AccountType type) {
    final all = ledger.accounts.values.where((a) => !a.archived);
    return (all.where((a) => a.name.toLowerCase().contains(name)).firstOrNull ??
            all.where((a) => a.type == type).firstOrNull)
        ?.id;
  }

  return [
    SmsSender('bKash', account('bkash', AccountType.wallet)),
    SmsSender('CityBank', account('city', AccountType.bank)),
  ];
}

String encodeSmsSenders(List<SmsSender> senders) =>
    jsonEncode([for (final s in senders) s.toJson()]);

/// Keys of messages already added or dismissed.
Set<String> smsHandled(Ledger ledger) {
  try {
    return {...(jsonDecode(ledger.settings[smsHandledSetting] ?? '[]') as List).cast<String>()};
  } catch (_) {
    return {};
  }
}

/// Remembers the newest few hundred keys; older messages are before
/// [smsSinceSetting] by then anyway.
String encodeSmsHandled(Set<String> keys) {
  final list = keys.toList();
  return jsonEncode(list.length > 500 ? list.sublist(list.length - 500) : list);
}

/// A message waiting to be added, with what the app makes of it.
class SmsSuggestion {
  const SmsSuggestion({required this.money, required this.accountId, required this.maybeEntered});

  final SmsMoney money;
  final int? accountId;

  /// An entry of the same amount on that account within a day of it.
  final bool maybeEntered;
}

/// The money messages from your senders since [smsSinceSetting] that are
/// neither added nor dismissed, newest first.
List<SmsSuggestion> smsSuggestions(Ledger ledger, List<SmsMessage> inbox) {
  final senders = smsSenders(ledger);
  final handled = smsHandled(ledger);
  final since = DateTime.tryParse(ledger.settings[smsSinceSetting] ?? '');
  final result = <SmsSuggestion>[];
  for (final m in inbox) {
    if (since != null && m.date.isBefore(since)) continue;
    final sender = senders.where((s) => s.matches(m.sender)).firstOrNull;
    if (sender == null) continue;
    final money = parseSms(m);
    if (money == null || handled.contains(money.key)) continue;
    result.add(
      SmsSuggestion(
        money: money,
        accountId: sender.accountId,
        maybeEntered: _alreadyEntered(ledger, money, sender.accountId),
      ),
    );
  }
  result.sort((a, b) => b.money.message.date.compareTo(a.money.message.date));
  return result;
}

bool _alreadyEntered(Ledger ledger, SmsMoney money, int? accountId) {
  final day = DateTime(money.message.date.year, money.message.date.month, money.message.date.day);
  return ledger.entries.any((Entry e) {
    if (e.amount != money.amount || e.date.difference(day).inDays.abs() > 1) return false;
    if (accountId == null) return true;
    return ledger.postingsOf(e.id).any((p) => p.accountId == accountId);
  });
}
