import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/floor_plan.dart';

class FloorPlanPainter extends CustomPainter {
  final FloorPlan plan;
  final Color wallColor;
  final bool showLabels;
  final double revealProgress;

  FloorPlanPainter({
    required this.plan,
    this.wallColor = AppColors.cyan,
    this.showLabels = true,
    this.revealProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = 24.0;
    final availW = size.width - margin * 2;
    final availH = size.height - margin * 2;
    final rawScale = (availW / plan.lengthFt).clamp(0, availH / plan.widthFt).toDouble();
    final scale = rawScale.isFinite && rawScale > 0 ? rawScale : 1.0;
    final offset = Offset(
      margin + (availW - plan.lengthFt * scale) / 2,
      margin + (availH - plan.widthFt * scale) / 2,
    );

    Rect toCanvasRect(Rect r) => Rect.fromLTWH(
          offset.dx + r.left * scale,
          offset.dy + r.top * scale,
          r.width * scale,
          r.height * scale,
        );

    final safeProgress = revealProgress.isFinite ? revealProgress.clamp(0.0, 1.0) : 1.0;
    final visibleCount = (plan.rooms.length * safeProgress).ceil().clamp(0, plan.rooms.length);

    for (int i = 0; i < visibleCount; i++) {
      final room = plan.rooms[i];
      final rect = toCanvasRect(room.rect);
      final fillPaint = Paint()..color = room.color.withOpacity(0.16);
      canvas.drawRect(rect, fillPaint);

      if (showLabels && rect.width > 40 && rect.height > 28) {
        final tp = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${room.name}\n',
                style: TextStyle(color: room.color, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              TextSpan(
                text: '${room.width.toStringAsFixed(0)}×${room.height.toStringAsFixed(0)} ft',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 8);
        tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
      }
    }

    final wallPaint = Paint()
      ..color = wallColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < visibleCount; i++) {
      canvas.drawRect(toCanvasRect(plan.rooms[i].rect), wallPaint);
    }

    final outerRect = Rect.fromLTWH(offset.dx, offset.dy, plan.lengthFt * scale, plan.widthFt * scale);
    final glow = Paint()
      ..color = wallColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final outerWall = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4;
    canvas.drawRect(outerRect, glow);
    canvas.drawRect(outerRect, outerWall);

    _drawDimension(canvas, Offset(outerRect.left, outerRect.bottom + 6),
        Offset(outerRect.right, outerRect.bottom + 6), '${plan.lengthFt.toStringAsFixed(0)} ft');
    _drawDimension(canvas, Offset(outerRect.right + 6, outerRect.top),
        Offset(outerRect.right + 6, outerRect.bottom), '${plan.widthFt.toStringAsFixed(0)} ft', vertical: true);
  }

  void _drawDimension(Canvas canvas, Offset a, Offset b, String label, {bool vertical = false}) {
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1;
    canvas.drawLine(a, b, paint);
    final tp = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    tp.paint(canvas, vertical ? Offset(mid.dx + 4, mid.dy - tp.height / 2) : Offset(mid.dx - tp.width / 2, mid.dy + 2));
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) =>
      oldDelegate.plan != plan || oldDelegate.revealProgress != revealProgress || oldDelegate.wallColor != wallColor;
}
