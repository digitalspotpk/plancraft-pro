import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/floor_plan.dart';
import '../models/room.dart';

/// Renders a [FloorPlan] as an isometric pseudo-3D scene: every room
/// rectangle is extruded upward into a box (walls) using a rotation matrix
/// (yaw + pitch controlled by drag = "orbit", scale controlled by
/// pinch/scroll = "zoom"). Pure CustomPainter — no WebGL, no Three.js, no
/// network fetch, so it survives 100% offline on GitHub Pages.
class Isometric3DPainter extends CustomPainter {
  final FloorPlan plan;
  final double yaw; // radians, left/right orbit
  final double pitch; // radians, up/down orbit
  final double zoom;
  final bool isNight;
  final double wallHeightFt;

  Isometric3DPainter({
    required this.plan,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.isNight,
    this.wallHeightFt = 9,
  });

  // Project a 3D point (x,y,z in feet) to 2D screen space.
  Offset _project(Vector3 p, Size size, Offset center) {
    // Rotate around Y (yaw) then X (pitch)
    final cosY = cos(yaw), sinY = sin(yaw);
    final x1 = p.x * cosY - p.z * sinY;
    final z1 = p.x * sinY + p.z * cosY;

    final cosX = cos(pitch), sinX = sin(pitch);
    final y2 = p.y * cosX - z1 * sinX;
    final z2 = p.y * sinX + z1 * cosX;

    // Simple orthographic-ish projection with slight perspective via z2
    final scale = zoom * 6.0;
    final perspective = 1 / (1 + z2 * 0.004);
    return Offset(
      center.dx + x1 * scale * perspective,
      center.dy + y2 * scale * perspective,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 30);
    final bg = isNight
        ? const RadialGradient(colors: [Color(0xFF0A0A18), AppColors.bg])
        : const RadialGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0D0D18)]);
    final bgPaint = Paint()..shader = bg.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Ground grid
    _drawGroundGrid(canvas, size, center);

    // Sort rooms back-to-front (painter's algorithm) using rotated depth
    final roomsWithDepth = plan.rooms.map((r) {
      final centerPt = Vector3(
        r.x + r.width / 2 - plan.lengthFt / 2,
        0,
        r.y + r.height / 2 - plan.widthFt / 2,
      );
      final cosY = cos(yaw), sinY = sin(yaw);
      final depth = centerPt.x * sinY + centerPt.z * cosY;
      return MapEntry(r, depth);
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in roomsWithDepth) {
      _drawBox(canvas, size, center, entry.key);
    }
  }

  void _drawGroundGrid(Canvas canvas, Size size, Offset center) {
    final gridPaint = Paint()
      ..color = (isNight ? AppColors.cyan : AppColors.purple).withOpacity(0.12)
      ..strokeWidth = 1;
    final halfL = plan.lengthFt / 2;
    final halfW = plan.widthFt / 2;
    const step = 5.0;
    for (double gx = -halfL; gx <= halfL + 0.01; gx += step) {
      final a = _project(Vector3(gx, 0, -halfW), size, center);
      final b = _project(Vector3(gx, 0, halfW), size, center);
      canvas.drawLine(a, b, gridPaint);
    }
    for (double gz = -halfW; gz <= halfW + 0.01; gz += step) {
      final a = _project(Vector3(-halfL, 0, gz), size, center);
      final b = _project(Vector3(halfL, 0, gz), size, center);
      canvas.drawLine(a, b, gridPaint);
    }
  }

  void _drawBox(Canvas canvas, Size size, Offset center, Room room) {
    final x0 = room.x - plan.lengthFt / 2;
    final x1 = room.x + room.width - plan.lengthFt / 2;
    final z0 = room.y - plan.widthFt / 2;
    final z1 = room.y + room.height - plan.widthFt / 2;
    final h = wallHeightFt;

    // 8 corners: bottom (y=0) and top (y=-h, since screen-y up is negative)
    final b0 = _project(Vector3(x0, 0, z0), size, center);
    final b1 = _project(Vector3(x1, 0, z0), size, center);
    final b2 = _project(Vector3(x1, 0, z1), size, center);
    final b3 = _project(Vector3(x0, 0, z1), size, center);
    final t0 = _project(Vector3(x0, -h, z0), size, center);
    final t1 = _project(Vector3(x1, -h, z0), size, center);
    final t2 = _project(Vector3(x1, -h, z1), size, center);
    final t3 = _project(Vector3(x0, -h, z1), size, center);

    final baseColor = room.color;
    final nightDim = isNight ? 0.55 : 1.0;

    Path quad(Offset a, Offset b, Offset c, Offset d) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();

    final strokePaint = Paint()
      ..color = (isNight ? AppColors.cyan : Colors.white).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Side walls (front/back/left/right) — shaded differently for depth cue
    final walls = [
      (quad(b0, b1, t1, t0), 0.85), // front
      (quad(b1, b2, t2, t1), 0.65), // right
      (quad(b2, b3, t3, t2), 0.85), // back
      (quad(b3, b0, t0, t3), 0.65), // left
    ];
    for (final (path, shade) in walls) {
      final fill = Paint()..color = baseColor.withOpacity(shade * nightDim * 0.55);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, strokePaint);
    }

    // Roof (top face) — brightest, plus a glow if "night" (simulating interior light)
    final roofPath = quad(t0, t1, t2, t3);
    final roofFill = Paint()..color = baseColor.withOpacity(0.9 * nightDim);
    canvas.drawPath(roofPath, roofFill);
    canvas.drawPath(roofPath, strokePaint);

    if (isNight) {
      final glowPaint = Paint()
        ..color = baseColor.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      final roofCenter = Offset(
        (t0.dx + t1.dx + t2.dx + t3.dx) / 4,
        (t0.dy + t1.dy + t2.dy + t3.dy) / 4,
      );
      canvas.drawCircle(roofCenter, 20, glowPaint);
    }

    // Label
    final tp = TextPainter(
      text: TextSpan(text: room.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelPos = Offset(
      (t0.dx + t1.dx + t2.dx + t3.dx) / 4 - tp.width / 2,
      (t0.dy + t1.dy + t2.dy + t3.dy) / 4 - tp.height / 2,
    );
    tp.paint(canvas, labelPos);
  }

  @override
  bool shouldRepaint(covariant Isometric3DPainter oldDelegate) => true;
}

class Vector3 {
  final double x, y, z;
  const Vector3(this.x, this.y, this.z);
}
