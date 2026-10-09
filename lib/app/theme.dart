import 'package:flutter/material.dart';

/// Good / warning / over-budget colours, kept apart from the brand accent.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.good,
    required this.goodSoft,
    required this.warn,
    required this.warnSoft,
    required this.bad,
    required this.badSoft,
    required this.muted,
    required this.line,
    required this.sunk,
  });

  final Color good, goodSoft, warn, warnSoft, bad, badSoft;

  /// Secondary text, hairlines, and recessed fills.
  final Color muted, line, sunk;

  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) => t < .5 ? this : (other ?? this);
}

/// Colour schemes you can pick in More → Appearance.
enum AppPalette {
  green('Ledger green'),
  blue('Ocean blue'),
  plum('Plum');

  const AppPalette(this.label);

  final String label;

  static AppPalette byName(String? name) =>
      values.firstWhere((p) => p.name == name, orElse: () => green);
}

/// The neutrals and accent of one palette in one brightness.
class _Tones {
  const _Tones({
    required this.accent,
    required this.onAccent,
    required this.soft,
    required this.bg,
    required this.surface,
    required this.fg,
    required this.muted,
    required this.line,
    required this.sunk,
  });

  final Color accent, onAccent, soft, bg, surface, fg, muted, line, sunk;
}

// Neutrals carry a slight tint of their accent so each scheme hangs
// together. The green set is the one in design/screens.html.
const _tones = {
  (AppPalette.green, Brightness.light): _Tones(
    accent: Color(0xFF0D6A55),
    onAccent: Colors.white,
    soft: Color(0xFFD9EEE6),
    bg: Color(0xFFF4F7F5),
    surface: Colors.white,
    fg: Color(0xFF14201A),
    muted: Color(0xFF56665E),
    line: Color(0xFFD5DED8),
    sunk: Color(0xFFE9EFEB),
  ),
  (AppPalette.green, Brightness.dark): _Tones(
    accent: Color(0xFF4EC2A0),
    onAccent: Color(0xFF07231A),
    soft: Color(0xFF173A30),
    bg: Color(0xFF0D1311),
    surface: Color(0xFF151D1A),
    fg: Color(0xFFE1EAE5),
    muted: Color(0xFF93A39B),
    line: Color(0xFF2A3631),
    sunk: Color(0xFF1C2622),
  ),
  (AppPalette.blue, Brightness.light): _Tones(
    accent: Color(0xFF1F5FAD),
    onAccent: Colors.white,
    soft: Color(0xFFDCE8F7),
    bg: Color(0xFFF4F6F9),
    surface: Colors.white,
    fg: Color(0xFF141A22),
    muted: Color(0xFF556070),
    line: Color(0xFFD5DCE6),
    sunk: Color(0xFFE8EDF3),
  ),
  (AppPalette.blue, Brightness.dark): _Tones(
    accent: Color(0xFF7DB2F0),
    onAccent: Color(0xFF0A1A2E),
    soft: Color(0xFF16304F),
    bg: Color(0xFF0C1118),
    surface: Color(0xFF141B24),
    fg: Color(0xFFE1E7EF),
    muted: Color(0xFF93A0B2),
    line: Color(0xFF283342),
    sunk: Color(0xFF1B2430),
  ),
  (AppPalette.plum, Brightness.light): _Tones(
    accent: Color(0xFF6B3FA0),
    onAccent: Colors.white,
    soft: Color(0xFFECE2F6),
    bg: Color(0xFFF7F5F9),
    surface: Colors.white,
    fg: Color(0xFF1C1622),
    muted: Color(0xFF645A6E),
    line: Color(0xFFDFD8E6),
    sunk: Color(0xFFEEE9F3),
  ),
  (AppPalette.plum, Brightness.dark): _Tones(
    accent: Color(0xFFC3A2EA),
    onAccent: Color(0xFF24123A),
    soft: Color(0xFF34204D),
    bg: Color(0xFF121015),
    surface: Color(0xFF1B1720),
    fg: Color(0xFFEAE4F0),
    muted: Color(0xFFA497B2),
    line: Color(0xFF332B3D),
    sunk: Color(0xFF231E2A),
  ),
};

/// Builds the app theme. With [pureBlack] in dark mode the background is
/// #000000, so an OLED screen switches those pixels off.
ThemeData buildTheme(
  Brightness brightness, {
  AppPalette palette = AppPalette.green,
  bool pureBlack = false,
}) {
  final dark = brightness == Brightness.dark;
  final black = dark && pureBlack;
  final t = _tones[(palette, brightness)]!;

  final accent = t.accent;
  final onAccent = t.onAccent;
  final bg = black ? Colors.black : t.bg;
  final surface = black ? const Color(0xFF0C0C0C) : t.surface;
  final fg = t.fg;
  final status = dark
      ? StatusColors(
          good: const Color(0xFF5BCB8A),
          goodSoft: const Color(0xFF16321F),
          warn: const Color(0xFFE3A64C),
          warnSoft: const Color(0xFF382913),
          bad: const Color(0xFFEF7A70),
          badSoft: const Color(0xFF3B1C19),
          muted: t.muted,
          line: black ? const Color(0xFF242424) : t.line,
          sunk: black ? const Color(0xFF161616) : t.sunk,
        )
      : StatusColors(
          good: const Color(0xFF1D7A4B),
          goodSoft: const Color(0xFFDCF0E3),
          warn: const Color(0xFF9C5A05),
          warnSoft: const Color(0xFFFAEACF),
          bad: const Color(0xFFB3322B),
          badSoft: const Color(0xFFF7DDDA),
          muted: t.muted,
          line: t.line,
          sunk: t.sunk,
        );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: t.soft,
    onPrimaryContainer: accent,
    secondary: accent,
    onSecondary: onAccent,
    error: status.bad,
    onError: onAccent,
    surface: surface,
    onSurface: fg,
    onSurfaceVariant: status.muted,
    outline: status.line,
    outlineVariant: status.line,
    surfaceContainerHighest: status.sunk,
  );

  // IBM Plex Sans as in the designs; Hind Siliguri covers ৳ and Bangla.
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'IBMPlexSans',
    fontFamilyFallback: const ['HindSiliguri'],
  );
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    extensions: [status],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    bottomAppBarTheme: BottomAppBarThemeData(color: surface, elevation: 0),
    dividerTheme: DividerThemeData(color: status.line, space: 1, thickness: 1),
    textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
  );
}
