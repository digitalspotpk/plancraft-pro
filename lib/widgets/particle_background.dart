import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class _Particle {
  Offset pos;
  Offset velocity;
  double radius;
  double opacity;
  Color color;
  _Particle({
    required this.pos,
    required this.velocity,
    required this.radius,
    required this.opacity,
    required this.color,
  });
}

/// Full-screen floating neon particle backdrop, purely CustomPainter-driven
/// (no image/GIF assets → stays 100% offline and tiny in bundle size).
class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color primary;
  final Color secondary;
  const ParticleBackground({
    super.key,
    this.particleCount = 45,
    this.primary = AppColors.cyan,
    this.secondary = AppColors.purple,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..repeat();
  }

  void _seed(Size size) {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        pos: Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        velocity: Offset((_rng.nextDouble() - 0.5) * 0.4, (_rng.nextDouble() - 0.5) * 0.4),
        radius: _rng.nextDouble() * 2.2 + 0.8,
        opacity: _rng.nextDouble() * 0.5 + 0.2,
        color: _rng.nextBool() ? widget.primary : widget.secondary,
      ));
    }
  }

  void _tick() {
    if (_lastSize == Size.zero) return;
    for (final p in _particles) {
      p.pos += p.velocity;
      if (p.pos.dx < 0 || p.pos.dx > _lastSize.width) {
        p.velocity = Offset(-p.velocity.dx, p.velocity.dy);
      }
      if (p.pos.dy < 0 || p.pos.dy > _lastSize.height) {
        p.velocity = Offset(p.velocity.dx, -p.velocity.dy);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (_lastSize != size) {
        _lastSize = size;
        if (_particles.isEmpty) _seed(size);
      }
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
            colors: [Color(0xFF10101E), AppColors.bg],
          ),
        ),
        child: CustomPaint(
          size: size,
          painter: _ParticlePainter(_particles),
        ),
      );
    });
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p.pos, p.radius, paint);
    }
    // faint connecting lines for a "circuit" feel
    final linePaint = Paint()..strokeWidth = 0.6;
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final d = (particles[i].pos - particles[j].pos).distance;
        if (d < 110) {
          linePaint.color = particles[i].color.withOpacity((1 - d / 110) * 0.12);
          canvas.drawLine(particles[i].pos, particles[j].pos, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
