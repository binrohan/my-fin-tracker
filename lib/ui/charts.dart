import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/money.dart';

/// One bar: what was spent in a month, against that month's budget.
typedef MonthBar = ({String label, Poisha actual, Poisha budget, bool current});

/// Spending per month as bars, with a tick for each month's budget.
/// Over-budget months are red; the month in progress is lighter.
class MonthBars extends StatelessWidget {
  const MonthBars({super.key, required this.bars, this.height = 120});

  final List<MonthBar> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final top = bars.fold<Poisha>(
      1,
      (m, b) => [m, b.actual, b.budget].reduce((a, c) => a > c ? a : c),
    );
    final summary = bars
        .map(
          (b) =>
              '${b.label}: ${formatTaka(b.actual)}${b.budget > 0 ? ' of ${formatTaka(b.budget)}' : ''}',
        )
        .join('; ');

    return Semantics(
      label: 'Spending by month. $summary',
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarsPainter(
                  bars: bars,
                  top: top,
                  bar: accent,
                  over: status.bad,
                  tick: StatusColors.of(context).muted,
                  grid: status.line,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final b in bars)
                  Expanded(
                    child: Text(
                      b.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: status.muted,
                        fontWeight: b.current ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.bars,
    required this.top,
    required this.bar,
    required this.over,
    required this.tick,
    required this.grid,
  });

  final List<MonthBar> bars;
  final Poisha top;
  final Color bar, over, tick, grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);

    final slot = size.width / bars.length;
    final width = slot * .46;
    for (final (i, b) in bars.indexed) {
      final x = slot * i + (slot - width) / 2;
      final h = size.height * b.actual / top;
      final isOver = b.budget > 0 && b.actual > b.budget;
      final paint = Paint()..color = (isOver ? over : bar).withValues(alpha: b.current ? .55 : 1);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - h, width, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );
      if (b.budget > 0) {
        final y = size.height - size.height * b.budget / top;
        canvas.drawLine(
          Offset(x - 4, y),
          Offset(x + width + 4, y),
          Paint()
            ..color = tick
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.bars != bars || old.bar != bar;
}
