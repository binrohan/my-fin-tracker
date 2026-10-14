import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/ledger/sms.dart';

/// Messages in the usual bKash and City Bank shapes (numbers made up).
void main() {
  SmsMoney? parse(String sender, String body) =>
      parseSms(SmsMessage(sender: sender, body: body, date: DateTime(2026, 10, 14, 10)));

  group('bKash', () {
    test('money received', () {
      final m = parse(
        'bKash',
        'You have received Tk 1,500.00 from 01712345678. Ref rent. Fee Tk 0.00. '
            'Balance Tk 3,250.50. TrxID BJ12KL34MN at 12/10/2026 14:22',
      )!;
      expect((m.kind, m.amount, m.balance), (SmsKind.income, taka(1500), taka(3250.50)));
      expect(m.party, '01712345678');
      expect(m.reference, 'BJ12KL34MN');
    });

    test('cash out with a fee', () {
      final m = parse(
        'bKash',
        'Cash Out Tk 2,000.00 to 01812345678 successful. Fee Tk 37.00. '
            'Balance Tk 1,213.50. TrxID BJ98XY76ZW at 13/10/2026 10:05',
      )!;
      expect((m.kind, m.amount, m.fee), (SmsKind.toCash, taka(2000), taka(37)));
    });

    test('payment to a shop', () {
      final m = parse(
        'bKash',
        'Payment Tk 450.00 to Shwapno successful. Balance Tk 763.50. '
            'TrxID BJ55AA11BB at 13/10/2026 19:40',
      )!;
      expect((m.kind, m.amount, m.party), (SmsKind.expense, taka(450), 'Shwapno'));
    });

    test('send money', () {
      final m = parse(
        'bKash',
        'Send Money Tk 500.00 to 01912345678 successful. Ref gift. Fee Tk 5.00. '
            'Balance Tk 258.50. TrxID BJ77CC22DD at 13/10/2026 20:10',
      )!;
      expect((m.kind, m.amount, m.fee), (SmsKind.expense, taka(500), taka(5)));
    });

    test('codes and offers are not money', () {
      expect(parse('bKash', 'Your bKash verification code is 123456. Never share it.'), isNull);
      expect(parse('bKash', 'Get 10% cashback offer on Tk 500 payment at Daraz!'), isNull);
      expect(parse('bKash', 'Payment of Tk 450.00 to Shwapno failed.'), isNull);
    });
  });

  group('City Bank', () {
    test('ATM withdrawal goes to cash', () {
      final m = parse(
        'CityBank',
        'Dear Customer, your A/C **1234 has been debited by BDT 5,000.00 on 14-Oct-2026 '
            'for ATM withdrawal. Avl Bal BDT 2,01,651.00',
      )!;
      expect((m.kind, m.amount, m.balance), (SmsKind.toCash, taka(5000), taka(201651)));
    });

    test('salary credited', () {
      final m = parse(
        'CityBank',
        'Your A/C **1234 is credited with BDT 85,000.00 on 26-Oct-2026 SALARY OCT. '
            'Avl Bal BDT 2,86,651.00',
      )!;
      expect((m.kind, m.amount), (SmsKind.income, taka(85000)));
    });

    test('card purchase', () {
      final m = parse(
        'CityBank',
        'Card **5678 transaction of BDT 1,250.00 at SHWAPNO GULSHAN on 14-OCT-26. '
            'Avl Lmt BDT 48,750.00',
      )!;
      expect((m.kind, m.amount, m.party), (SmsKind.expense, taka(1250), 'SHWAPNO GULSHAN'));
    });
  });

  test('senders match loosely', () {
    expect(const SmsSender('CityBank', 1).matches('City Bank'), isTrue);
    expect(const SmsSender('bKash', 2).matches('BKASH'), isTrue);
    expect(const SmsSender('bKash', 2).matches('Nagad'), isFalse);
  });
}
