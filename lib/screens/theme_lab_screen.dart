import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/particle_background.dart';

class ThemeLabScreen extends ConsumerStatefulWidget {
  const ThemeLabScreen({super.key});

  @override
  ConsumerState<ThemeLabScreen> createState() => _ThemeLabScreenState();
}

class _ThemeLabScreenState extends ConsumerState<ThemeLabScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _apply(int index) {
    ref.read(themeIndexProvider.notifier).setIndex(index);
    _flashController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = ref.watch(themeIndexProvider);
    final activeScheme = ref.watch(currentSchemeProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ParticleBackground(primary: activeScheme.primary, secondary: activeScheme.secondary),
          ),
          // Full-screen flash overlay on apply — the "animated transition"
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, _) {
              final t = _flashController.value;
              final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
              return IgnorePointer(
                child: Container(
                  color: activeScheme.primary.withOpacity(opacity.clamp(0, 1) * 0.28),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      const Text('Theme Lab', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 48),
                    child: Text('Tap any scheme to apply instantly, app-wide.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: kColorSchemes.length,
                      itemBuilder: (context, i) {
                        final scheme = kColorSchemes[i];
                        final active = i == activeIndex;
                        return _SchemeTile(
                          scheme: scheme,
                          active: active,
                          onTap: () => _apply(i),
                        );
                      },
                    ),
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

class _SchemeTile extends StatelessWidget {
  final ColorScheme10 scheme;
  final bool active;
  final VoidCallback onTap;
  const _SchemeTile({required this.scheme, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      scale: active ? 1.03 : 1.0,
      child: GlassCard(
        interactive: true,
        glowColor: scheme.primary,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  boxShadow: AppTheme.neonGlow(scheme.primary, blur: 18),
                ),
                child: active
                    ? const Center(
                        child: Icon(Icons.check_circle_rounded, color: Colors.black, size: 30),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              scheme.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
