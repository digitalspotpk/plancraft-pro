import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../widgets/neon_house_painter.dart';
import '../widgets/particle_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _drawController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Draws the house outline over exactly 3 seconds.
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) context.go('/loading');
        });
      }
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground(particleCount: 30)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 220,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_drawController, _pulseController]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: NeonHousePainter(
                          progress: Curves.easeInOut.transform(_drawController.value),
                          glowPulse: _pulseController.value,
                          color: AppColors.cyan,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.cyanPurple.createShader(bounds),
                  child: const Text(
                    'PLANCRAFT PRO AI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI FLOOR PLAN ARCHITECT',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
