import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/money.dart';
import '../ledger/ledger.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Waits for the ledger, then builds [builder]. Shows a spinner while the
/// database opens and a readable message if loading fails.
class LedgerBuilder extends ConsumerWidget {
  const LedgerBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Ledger ledger) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(ledgerProvider)
      .when(
        data: (ledger) => builder(context, ledger),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not read your data: $e'),
          ),
        ),
      );
}

class Money extends StatelessWidget {
  const Money(this.amount, {super.key, this.style, this.showPlus = false, this.color});

  final Poisha amount;
  final TextStyle? style;
  final bool showPlus;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    formatTaka(amount, showPlus: showPlus),
    style: (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: _tabular,
      color: color,
    ),
  );
}

/// Small uppercase heading inside a card: "THIS MONTH".
class Label extends StatelessWidget {
  const Label(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: color ?? StatusColors.of(context).muted,
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.color, this.onTap});

  final List<Widget> children;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: children),
    );
    // A Material (not a decorated Container) so tap ripples of tiles inside
    // the card stay visible.
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: color == null ? BorderSide(color: StatusColors.of(context).line) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// A label on the left and an amount on the right.
class AmountRow extends StatelessWidget {
  const AmountRow(
    this.label,
    this.amount, {
    super.key,
    this.detail,
    this.total = false,
    this.signed = false,
    this.color,
  });

  final String label;
  final Poisha amount;

  /// Muted text after the label.
  final String? detail;

  /// Draws a rule above and bolds the row.
  final bool total;

  /// Shows + / − and colours the amount green or red.
  final bool signed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final weight = total ? FontWeight.w700 : FontWeight.w400;
    final amountColor =
        color ?? (signed && amount != 0 ? (amount > 0 ? status.good : status.bad) : null);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 10,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (detail != null)
                  TextSpan(
                    text: '  $detail',
                    style: TextStyle(color: status.muted, fontSize: 12),
                  ),
              ],
            ),
            style: TextStyle(fontWeight: weight),
          ),
        ),
        Money(
          amount,
          showPlus: signed,
          color: amountColor,
          style: TextStyle(fontWeight: total ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
    if (!total) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [const Divider(), row],
    );
  }
}

class Bar extends StatelessWidget {
  const Bar(this.value, {super.key, this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      minHeight: height,
      color: color ?? Theme.of(context).colorScheme.primary,
      backgroundColor: StatusColors.of(context).sunk,
    ),
  );
}

enum ChipTone { good, warn, bad, accent, plain }

class StatusChip extends StatelessWidget {
  const StatusChip(this.text, {super.key, this.tone = ChipTone.plain});

  final String text;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final s = StatusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      ChipTone.good => (s.goodSoft, s.good),
      ChipTone.warn => (s.warnSoft, s.warn),
      ChipTone.bad => (s.badSoft, s.bad),
      ChipTone.accent => (scheme.primaryContainer, scheme.primary),
      ChipTone.plain => (s.sunk, scheme.onSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Screen title with an optional subtitle and trailing widget.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: StatusColors.of(context).muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Scrollable page body with the standard gutter and spacing.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          child,
        ],
      ],
    ),
  );
}
