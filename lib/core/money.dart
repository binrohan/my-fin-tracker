/// Money is stored as whole poisha (1 taka = 100 poisha) so that no amount
/// ever goes through floating point.
typedef Poisha = int;

const int poishaPerTaka = 100;

/// Converts a taka value to poisha: `taka(1250)` → 125000.
Poisha taka(num value) => (value * poishaPerTaka).round();

const String takaSymbol = '৳';
const String _minus = '−'; // U+2212, lines up with digits better than '-'

/// Formats with South Asian (lakh) grouping: 3,76,240 and 1,23,45,678.
/// Poisha are shown only when the amount is not a whole taka.
String formatTaka(
  Poisha amount, {
  bool symbol = true,
  bool showPlus = false,
}) {
  final abs = amount.abs();
  final whole = abs ~/ poishaPerTaka;
  final fraction = abs % poishaPerTaka;

  final buffer = StringBuffer();
  if (amount < 0) {
    buffer.write(_minus);
  } else if (showPlus && amount > 0) {
    buffer.write('+');
  }
  if (symbol) buffer.write(takaSymbol);
  buffer.write(groupLakh(whole));
  if (fraction != 0) {
    buffer.write('.${fraction.toString().padLeft(2, '0')}');
  }
  return buffer.toString();
}

/// 1234567 → "12,34,567". The last three digits form one group, every
/// group before that has two digits.
String groupLakh(int value) {
  assert(value >= 0);
  final digits = value.toString();
  if (digits.length <= 3) return digits;

  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Parses user input such as "1,23,970", "৳ 350" or "99.50" into poisha.
/// Returns null when the text is not a valid amount.
Poisha? parseTaka(String input) {
  final cleaned = input.replaceAll(RegExp('[,\\s$takaSymbol]'), '');
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.parse(match.group(2)!);
  final fraction = int.parse((match.group(3) ?? '0').padRight(2, '0'));
  final value = whole * poishaPerTaka + fraction;
  return match.group(1) == '-' ? -value : value;
}

/// Basis points as a percentage: 500 → "5%", 250 → "2.5%".
String formatPercentBp(int bp) {
  final text = (bp / 100).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text%';
}
