import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../widgets/particle_background.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int _progress = 1;
  Timer? _timer;

  static const List<String> _messages = [
    'Booting AI floor engine…',
    'Calibrating neon renderer…',
    'Loading room templates…',
    'Warming up particle field…',
    'Almost there…',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 22), (t) {
      setState(() {
        _progress += 1;
      });
      if (_progress >= 100) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/dashboard');
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _message => _messages[(_progress ~/ 22).clamp(0, _messages.length - 1)];

  @override
  Widget build(BuildContext context) {
    final pct = _progress.clamp(0, 100) / 100;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground(particleCount: 25)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_progress%',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cyan,
                      shadows: [
                        Shadow(color: AppColors.cyan, blurRadius: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Container(
                            height: 14,
                            color: Colors.white.withOpacity(0.06),
                          ),
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 120),
                            widthFactor: pct,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: AppColors.cyanPurple,
                                boxShadow: AppTheme.neonGlow(AppColors.cyan, blur: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _message,
                    style: const TextStyle(color: AppColors.textSecondary, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fractionally sized box that animates its widthFactor changes.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final Widget child;
  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    required super.duration,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      alignment: Alignment.centerLeft,
      child: widget.child,
    );
  }
}
