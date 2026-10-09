import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'providers.dart';
import 'theme.dart';

/// How the app looks. Stored in settings, so it is part of backups.
class Appearance {
  const Appearance({
    this.mode = ThemeMode.system,
    this.palette = AppPalette.green,
    this.pureBlack = false,
  });

  factory Appearance.fromSettings(Map<String, String> settings) => Appearance(
    mode: ThemeMode.values.firstWhere(
      (m) => m.name == settings[modeKey],
      orElse: () => ThemeMode.system,
    ),
    palette: AppPalette.byName(settings[paletteKey]),
    pureBlack: settings[pureBlackKey] == 'true',
  );

  static const modeKey = 'theme_mode';
  static const paletteKey = 'theme_palette';
  static const pureBlackKey = 'theme_pure_black';

  final ThemeMode mode;
  final AppPalette palette;

  /// Pitch-black background in dark mode, for OLED screens.
  final bool pureBlack;
}

final appearanceProvider = Provider<Appearance>((ref) {
  final settings = ref.watch(ledgerProvider).value?.settings;
  return settings == null ? const Appearance() : Appearance.fromSettings(settings);
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());
