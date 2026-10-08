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

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  // Same palette as design/screens.html.
  final accent = dark ? const Color(0xFF4EC2A0) : const Color(0xFF0D6A55);
  final onAccent = dark ? const Color(0xFF07231A) : Colors.white;
  final bg = dark ? const Color(0xFF0D1311) : const Color(0xFFF4F7F5);
  final surface = dark ? const Color(0xFF151D1A) : Colors.white;
  final fg = dark ? const Color(0xFFE1EAE5) : const Color(0xFF14201A);
  final status = dark
      ? const StatusColors(
          good: Color(0xFF5BCB8A),
          goodSoft: Color(0xFF16321F),
          warn: Color(0xFFE3A64C),
          warnSoft: Color(0xFF382913),
          bad: Color(0xFFEF7A70),
          badSoft: Color(0xFF3B1C19),
          muted: Color(0xFF93A39B),
          line: Color(0xFF2A3631),
          sunk: Color(0xFF1C2622),
        )
      : const StatusColors(
          good: Color(0xFF1D7A4B),
          goodSoft: Color(0xFFDCF0E3),
          warn: Color(0xFF9C5A05),
          warnSoft: Color(0xFFFAEACF),
          bad: Color(0xFFB3322B),
          badSoft: Color(0xFFF7DDDA),
          muted: Color(0xFF56665E),
          line: Color(0xFFD5DED8),
          sunk: Color(0xFFE9EFEB),
        );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: dark ? const Color(0xFF173A30) : const Color(0xFFD9EEE6),
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

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
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
