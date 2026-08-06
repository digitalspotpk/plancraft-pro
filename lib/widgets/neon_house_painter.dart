import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Draws a simple house outline (roof + walls + door + window) as a single
/// continuous path, then reveals it stroke-by-stroke using [progress]
/// (0.0 -> 1.0). This replaces a Lottie "neon house drawing" animation so
/// the splash screen has zero external asset / network dependency.
class NeonHousePainter extends CustomPainter {
  final double progress; // 0..1 draw progress
  final double glowPulse; // 0..1 pulsing glow intensity
  final Color color;

  NeonHousePainter({
    required this.progress,
    required this.glowPulse,
    this.color = AppColors.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // House geometry (normalized then scaled to canvas)
    final base = Offset(w * 0.2, h * 0.75);
    final roofPeak = Offset(w * 0.5, h * 0.2);
    final leftEave = Offset(w * 0.15, h * 0.48);
    final rightEave = Offset(w * 0.85, h * 0.48);
    final bottomRight = Offset(w * 0.8, h * 0.75);

    // Roof
    path.moveTo(leftEave.dx, leftEave.dy);
    path.lineTo(roofPeak.dx, roofPeak.dy);
    path.lineTo(rightEave.dx, rightEave.dy);
    // Right wall down
    path.moveTo(rightEave.dx, rightEave.dy);
    path.lineTo(bottomRight.dx, bottomRight.dy);
    // Base
    path.lineTo(base.dx, base.dy);
    // Left wall up
    path.lineTo(leftEave.dx, leftEave.dy);
    // Door
    final doorRect = Rect.fromLTWH(w * 0.44, h * 0.58, w * 0.12, h * 0.17);
    path.addRect(doorRect);
    // Window
    final winRect = Rect.fromLTWH(w * 0.6, h * 0.58, w * 0.1, h * 0.08);
    path.addRect(winRect);

    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    double lengthToDraw = totalLength * progress;

    final glow = Paint()
      ..color = color.withOpacity(0.5 + glowPulse * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final coreStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    for (final metric in metrics) {
      if (lengthToDraw <= 0) break;
      final drawLen = lengthToDraw.clamp(0, metric.length).toDouble();
      final extract = metric.extractPath(0, drawLen);
      canvas.drawPath(extract, glow);
      canvas.drawPath(extract, coreStroke);
      canvas.drawPath(extract, stroke..strokeWidth = 1.1);
      lengthToDraw -= metric.length;
    }
  }

  @override
  bool shouldRepaint(covariant NeonHousePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glowPulse != glowPulse;
}
