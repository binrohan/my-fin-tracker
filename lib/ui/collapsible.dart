import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'widgets.dart';

/// A card whose heading folds it away. Folded, it shows [summary] (a total,
/// a count) next to the heading.
class CollapsibleCard extends StatelessWidget {
  const CollapsibleCard({
    super.key,
    required this.title,
    required this.collapsed,
    required this.onToggle,
    required this.children,
    this.summary,
    this.color,
  });

  final String title;
  final bool collapsed;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Widget? summary;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final muted = StatusColors.of(context).muted;
    final header = Semantics(
      button: true,
      expanded: !collapsed,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            spacing: 8,
            children: [
              Expanded(child: Label(title)),
              if (collapsed && summary != null)
                DefaultTextStyle.merge(
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                  child: summary!,
                ),
              AnimatedRotation(
                turns: collapsed ? 0 : .5,
                duration: const Duration(milliseconds: 150),
                child: Icon(Icons.expand_more, size: 20, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
    return SectionCard(color: color, children: [header, if (!collapsed) ...children]);
  }
}
