import 'dart:math' as math;

import 'package:flutter/material.dart';

class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.title,
    required this.values,
    required this.color,
    this.height = 160,
  });

  final String title;
  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(title,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        SizedBox(
          height: height,
          child: values.isEmpty
              ? Center(
                  child: Text(
                    'No data yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                )
              : CustomPaint(
                  painter: _BarPainter(
                    values: values,
                    color: color,
                    axisColor: Theme.of(context).colorScheme.outlineVariant,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  size: Size.infinite,
                ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.color,
    required this.axisColor,
    required this.textColor,
  });

  final List<double> values;
  final Color color;
  final Color axisColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 36.0;
    const padRight = 12.0;
    const padTop = 10.0;
    const padBottom = 22.0;
    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;
    if (plotW <= 0 || plotH <= 0) return;

    final hi = math.max(values.reduce(math.max), 1.0);

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padLeft, padTop + plotH),
      Offset(padLeft + plotW, padTop + plotH),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padLeft, padTop),
      Offset(padLeft, padTop + plotH),
      axisPaint,
    );

    const ticks = 3;
    for (int i = 0; i <= ticks; i++) {
      final t = i / ticks;
      final y = padTop + plotH - t * plotH;
      final value = t * hi;
      final tp = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(value < 10 ? 1 : 0),
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 4, y - tp.height / 2));
    }

    final barWidth = plotW / values.length * 0.65;
    final gap = plotW / values.length;
    final barPaint = Paint()..color = color;
    for (int i = 0; i < values.length; i++) {
      final norm = values[i] / hi;
      final h = norm * plotH;
      final cx = padLeft + (i + 0.5) * gap;
      final rect = Rect.fromLTWH(
        cx - barWidth / 2,
        padTop + plotH - h,
        barWidth,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        barPaint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, padTop + plotH + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
