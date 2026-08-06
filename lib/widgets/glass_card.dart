import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Reusable frosted-glass card: blurred backdrop + soft border + optional
/// neon glow on hover/focus. This is the single visual building block used
/// across Dashboard, Generator, 3D Viewer and Theme Lab.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color glowColor;
  final bool interactive;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.glowColor = AppColors.cyan,
    this.interactive = false,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.interactive ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: (_hovering && widget.interactive)
              ? (Matrix4.identity()..translate(0.0, -3.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _hovering
                ? AppTheme.neonGlow(widget.glowColor, blur: 28)
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: AppColors.glassFill,
                  border: Border.all(
                    color: _hovering
                        ? widget.glowColor.withOpacity(0.7)
                        : AppColors.glassBorder,
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
