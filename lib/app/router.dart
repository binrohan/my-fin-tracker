import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/save/save_screen.dart';
import '../features/spend/spend_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        for (final (path, screen) in [
          ('/', const HomeScreen()),
          ('/spend', const SpendScreen()),
          ('/save', const SaveScreen()),
          ('/more', const MoreScreen()),
        ])
          StatefulShellBranch(routes: [
            GoRoute(path: path, builder: (_, _) => screen),
          ]),
      ],
    ),
  ],
);

/// Four tabs with the + button in the middle of the bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Spend'),
    (Icons.savings_outlined, Icons.savings, 'Save'),
    (Icons.more_horiz, Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget tab(int i) {
      final (icon, selectedIcon, label) = _tabs[i];
      final selected = shell.currentIndex == i;
      final color =
          selected ? Theme.of(context).colorScheme.primary : StatusColors.of(context).muted;
      return Expanded(
        child: InkWell(
          onTap: () => shell.goBranch(i, initialLocation: selected),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? selectedIcon : icon, color: color),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: shell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add expense',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick add arrives in the next build (Phase 2)')),
        ),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [tab(0), tab(1), const SizedBox(width: 72), tab(2), tab(3)]),
      ),
    );
  }
}
