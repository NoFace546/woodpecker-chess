import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/phase_stats.dart';
import '../../../widgets/empty_state.dart';

class PhaseRadar extends StatelessWidget {
  const PhaseRadar({super.key, required this.stats});

  final PhaseStats stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasAnyData) {
      return const EmptyState(
        icon: Icons.radar,
        title: 'No phase data yet',
        body:
            'Solve puzzles tagged opening, middlegame, or endgame to '
            'unlock the radar.',
        compact: true,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: CustomPaint(
            painter: _PhaseRadarPainter(
              stats: stats,
              axisColor: scheme.outlineVariant,
              fillColor: scheme.primary.withValues(alpha: 0.18),
              strokeColor: scheme.primary,
              labelStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: scheme.onSurface),
              dataLabelStyle: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PhaseLegend(stats: stats),
      ],
    );
  }
}

class _PhaseLegend extends StatelessWidget {
  const _PhaseLegend({required this.stats});
  final PhaseStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final p in [stats.opening, stats.middlegame, stats.endgame])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    p.phase,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    p.total == 0
                        ? 'no data'
                        : '${(p.accuracy * 100).round()}% · n=${p.total}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhaseRadarPainter extends CustomPainter {
  _PhaseRadarPainter({
    required this.stats,
    required this.axisColor,
    required this.fillColor,
    required this.strokeColor,
    required this.labelStyle,
    required this.dataLabelStyle,
  });

  final PhaseStats stats;
  final Color axisColor;
  final Color fillColor;
  final Color strokeColor;
  final TextStyle labelStyle;
  final TextStyle dataLabelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = math.min(size.width, size.height) / 2 - 36;

    // Three vertices: top (opening), bottom-left (middlegame),
    // bottom-right (endgame). Angles start at -π/2 (top).
    const angles = [
      -math.pi / 2, // top
      math.pi / 2 + math.pi / 3, // bottom-left
      math.pi / 2 - math.pi / 3, // bottom-right
    ];
    final phases = [stats.opening, stats.middlegame, stats.endgame];
    final labels = ['Opening', 'Middlegame', 'Endgame'];

    final gridPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Concentric grid rings at 25/50/75/100%.
    for (final t in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i < 3; i++) {
        final dx = center.dx + radius * t * math.cos(angles[i]);
        final dy = center.dy + radius * t * math.sin(angles[i]);
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis spokes.
    for (final a in angles) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(a),
          center.dy + radius * math.sin(a),
        ),
        gridPaint,
      );
    }

    // Data polygon.
    final dataPath = Path();
    final pointPositions = <Offset>[];
    for (var i = 0; i < 3; i++) {
      final acc = phases[i].total == 0 ? 0.0 : phases[i].accuracy;
      final dx = center.dx + radius * acc * math.cos(angles[i]);
      final dy = center.dy + radius * acc * math.sin(angles[i]);
      pointPositions.add(Offset(dx, dy));
      if (i == 0) {
        dataPath.moveTo(dx, dy);
      } else {
        dataPath.lineTo(dx, dy);
      }
    }
    dataPath.close();
    canvas.drawPath(
        dataPath, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(
        dataPath,
        Paint()
          ..color = strokeColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // Vertex dots.
    final dotPaint = Paint()..color = strokeColor;
    for (final p in pointPositions) {
      canvas.drawCircle(p, 4, dotPaint);
    }

    // Phase labels at vertices.
    for (var i = 0; i < 3; i++) {
      final outset = radius + 18;
      final labelCenter = Offset(
        center.dx + outset * math.cos(angles[i]),
        center.dy + outset * math.sin(angles[i]),
      );
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 90);
      // Center label at the vertex position.
      tp.paint(
        canvas,
        labelCenter.translate(-tp.width / 2, -tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PhaseRadarPainter old) =>
      old.stats != stats ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor;
}
