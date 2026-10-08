import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: MyFinTrackerApp()));
}

class MyFinTrackerApp extends StatelessWidget {
  const MyFinTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'My Fin Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        routerConfig: router,
      );
}
