import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/money.dart';

const _gramsPerTroyOunce = 31.1034768;

/// International gold and silver prices in taka a gram, from the free
/// currency-api (github.com/fawazahmed0/exchange-api). These are prices for
/// pure metal; jewellers' prices in Bangladesh (BAJUS) are usually higher.
class MetalPrices {
  const MetalPrices({required this.gold, required this.silver, required this.date});

  /// Taka a gram, in poisha.
  final Poisha gold;
  final Poisha silver;

  /// The day the prices are for.
  final DateTime date;

  /// The same data from two places, in case one is down.
  static const _sources = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies',
    'https://latest.currency-api.pages.dev/v1/currencies',
  ];

  /// Fetches today's prices. Only the metal codes are sent; nothing about
  /// you. Throws [MetalPriceException] when offline or the answer is odd.
  static Future<MetalPrices> fetch({HttpClient? client}) async {
    final http = client ?? HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    Object? lastError;
    try {
      for (final base in _sources) {
        try {
          final gold = await _perOunce(http, '$base/xau.json', 'xau');
          final silver = await _perOunce(http, '$base/xag.json', 'xag');
          return parse(gold.$1, silver.$1, gold.$2);
        } catch (e) {
          lastError = e;
        }
      }
    } finally {
      if (client == null) http.close();
    }
    throw MetalPriceException('Couldn\'t get prices. Check the internet connection. ($lastError)');
  }

  /// Taka per troy ounce to poisha per gram.
  static MetalPrices parse(double goldPerOunce, double silverPerOunce, DateTime date) {
    if (goldPerOunce <= 0 || silverPerOunce <= 0) {
      throw const MetalPriceException('The price service sent no prices.');
    }
    return MetalPrices(
      gold: taka(goldPerOunce / _gramsPerTroyOunce),
      silver: taka(silverPerOunce / _gramsPerTroyOunce),
      date: date,
    );
  }

  /// One currency-api file: `{"date": "2026-10-15", "xau": {"bdt": 511677.9, …}}`.
  static (double, DateTime) readBdt(String body, String code) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final rates = json[code] as Map<String, dynamic>;
    return (
      (rates['bdt'] as num).toDouble(),
      DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static Future<(double, DateTime)> _perOunce(HttpClient http, String url, String code) async {
    final request = await http.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 15));
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
    final body = await response.transform(utf8.decoder).join();
    return readBdt(body, code);
  }
}

class MetalPriceException implements Exception {
  const MetalPriceException(this.message);

  final String message;

  @override
  String toString() => message;
}
