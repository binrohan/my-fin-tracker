import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';

void main() {
  group('formatTaka', () {
    test('uses lakh grouping', () {
      expect(formatTaka(taka(0)), '৳0');
      expect(formatTaka(taka(350)), '৳350');
      expect(formatTaka(taka(1250)), '৳1,250');
      expect(formatTaka(taka(85620)), '৳85,620');
      expect(formatTaka(taka(376240)), '৳3,76,240');
      expect(formatTaka(taka(12345678)), '৳1,23,45,678');
    });

    test('signs and options', () {
      expect(formatTaka(taka(-37000)), '−৳37,000');
      expect(formatTaka(taka(85000), showPlus: true), '+৳85,000');
      expect(formatTaka(taka(123970), symbol: false), '1,23,970');
      expect(formatTaka(9950), '৳99.50');
      expect(formatTaka(-5), '−৳0.05');
    });
  });

  group('parseTaka', () {
    test('accepts what people type', () {
      expect(parseTaka('350'), taka(350));
      expect(parseTaka('1,23,970'), taka(123970));
      expect(parseTaka('৳ 2,250'), taka(2250));
      expect(parseTaka('99.5'), 9950);
      expect(parseTaka('99.05'), 9905);
      expect(parseTaka('-20'), taka(-20));
    });

    test('rejects nonsense', () {
      expect(parseTaka(''), isNull);
      expect(parseTaka('abc'), isNull);
      expect(parseTaka('1.234'), isNull);
      expect(parseTaka('1..2'), isNull);
    });
  });

  group('Period', () {
    test('month boundaries', () {
      const sep = Period(2026, 9);
      expect(sep.start, DateTime(2026, 9, 1));
      expect(sep.end, DateTime(2026, 10, 1));
      expect(sep.daysInMonth, 30);
      expect(sep.contains(DateTime(2026, 9, 30)), isTrue);
      expect(sep.contains(DateTime(2026, 10, 1)), isFalse);
      expect(const Period(2026, 12).next, const Period(2027, 1));
      expect(const Period(2026, 1).previous, const Period(2025, 12));
      expect(const Period(2028, 2).daysInMonth, 29);
    });
  });
}
