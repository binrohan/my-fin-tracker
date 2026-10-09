import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/appearance.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
  // The bundled fonts are under the SIL Open Font License; list it on the
  // licences page with the packages.
  LicenseRegistry.addLicense(() async* {
    for (final (fonts, file) in [
      (['IBM Plex Sans', 'IBM Plex Mono'], 'OFL-IBMPlex.txt'),
      (['Hind Siliguri'], 'OFL-HindSiliguri.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks(fonts, await rootBundle.loadString('assets/fonts/$file'));
    }
  });
  runApp(const ProviderScope(child: MyFinTrackerApp()));
}

class MyFinTrackerApp extends ConsumerWidget {
  const MyFinTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(appearanceProvider);
    return MaterialApp.router(
      title: 'My Fin Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: look.mode,
      theme: buildTheme(Brightness.light, palette: look.palette),
      darkTheme: buildTheme(Brightness.dark, palette: look.palette, pureBlack: look.pureBlack),
      routerConfig: router,
    );
  }
}
