import 'dart:math' as math;

import 'package:flutter/material.dart';

class TrendSeries {
  const TrendSeries({
    required this.label,
    required this.color,
    required this.values,
  });
  final String label;
  final Color color;
  final List<double> values;
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.title,
    required this.series,
    this.yLabel,
    this.yMin,
    this.yMax,
    this.height = 180,
  });

  final String title;
  final List<TrendSeries> series;
  final String? yLabel;
  final double? yMin;
  final double? yMax;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasData = series.any((s) => s.values.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final s in series) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(s.label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: hasData
              ? CustomPaint(
                  painter: _TrendPainter(
                    series: series,
                    yMin: yMin,
                    yMax: yMax,
                    yLabel: yLabel,
                    axisColor: Theme.of(context).colorScheme.outlineVariant,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  size: Size.infinite,
                )
              : Center(
                  child: Text(
                    'No data yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.series,
    required this.axisColor,
    required this.textColor,
    this.yMin,
    this.yMax,
    this.yLabel,
  });

  final List<TrendSeries> series;
  final double? yMin;
  final double? yMax;
  final String? yLabel;
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

    final allValues =
        series.expand((s) => s.values).toList();
    if (allValues.isEmpty) return;

    final dataMin = allValues.reduce(math.min);
    final dataMax = allValues.reduce(math.max);
    final lo = yMin ?? math.min(dataMin, 0);
    var hi = yMax ?? dataMax;
    if (hi - lo < 1e-6) hi = lo + 1;

    final maxLen = series.map((s) => s.values.length).reduce(math.max);

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.4)
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

    const ticks = 4;
    for (int i = 0; i <= ticks; i++) {
      final t = i / ticks;
      final y = padTop + plotH - t * plotH;
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(padLeft + plotW, y),
        gridPaint,
      );
      final value = lo + t * (hi - lo);
      final tp = TextPainter(
        text: TextSpan(
          text: _fmtTick(value),
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 4, y - tp.height / 2));
    }

    // Show at most ~6 evenly-spaced x-axis labels so they never overlap.
    const maxXLabels = 6;
    final labelStep = maxLen <= maxXLabels
        ? 1
        : (maxLen / maxXLabels).ceil();
    for (int i = 0; i < maxLen; i++) {
      final isLast = i == maxLen - 1;
      if (i % labelStep != 0 && !isLast) continue;
      // Avoid drawing a label too close to the final one.
      if (!isLast && maxLen > maxXLabels && (maxLen - 1 - i) < labelStep / 2) {
        continue;
      }
      final x = padLeft +
          (maxLen == 1 ? plotW / 2 : i * plotW / (maxLen - 1));
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, padTop + plotH + 4),
      );
    }

    for (final s in series) {
      if (s.values.isEmpty) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final dotPaint = Paint()..color = s.color;
      final path = Path();
      for (int i = 0; i < s.values.length; i++) {
        final x = padLeft +
            (s.values.length == 1
                ? plotW / 2
                : i * plotW / (s.values.length - 1));
        final norm = (s.values[i] - lo) / (hi - lo);
        final y = padTop + plotH - norm * plotH;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
      canvas.drawPath(path, paint);
    }
  }

  String _fmtTick(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax;
  }
}
