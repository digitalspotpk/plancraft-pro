import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../providers/plan_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/particle_background.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => AppColors.cyanPurple.createShader(b),
                          child: const Text(
                            'PlanCraft Pro AI',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Design. Visualize. Deploy — 100% offline.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // ---- 2-mode toggle ----
                    _ModeToggle(mode: mode, onChanged: (m) => ref.read(appModeProvider.notifier).state = m),

                    const SizedBox(height: 32),

                    // ---- 2 count-up cards ----
                    LayoutBuilder(builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 560;
                      final cards = [
                        Expanded(
                          child: statsAsync.when(
                            data: (s) => _CountUpCard(
                              label: 'PLANS GENERATED',
                              icon: Icons.dashboard_customize_rounded,
                              value: s.plansGenerated,
                              color: AppColors.cyan,
                            ),
                            loading: () => const _CountUpCard(
                                label: 'PLANS GENERATED', icon: Icons.dashboard_customize_rounded, value: 0, color: AppColors.cyan),
                            error: (_, __) => const _CountUpCard(
                                label: 'PLANS GENERATED', icon: Icons.dashboard_customize_rounded, value: 0, color: AppColors.cyan),
                          ),
                        ),
                        SizedBox(width: isNarrow ? 0 : 20, height: isNarrow ? 20 : 0),
                        Expanded(
                          child: statsAsync.when(
                            data: (s) => _CountUpCard(
                              label: '3D VIEWS RENDERED',
                              icon: Icons.view_in_ar_rounded,
                              value: s.viewsRendered,
                              color: AppColors.purple,
                            ),
                            loading: () => const _CountUpCard(
                                label: '3D VIEWS RENDERED', icon: Icons.view_in_ar_rounded, value: 0, color: AppColors.purple),
                            error: (_, __) => const _CountUpCard(
                                label: '3D VIEWS RENDERED', icon: Icons.view_in_ar_rounded, value: 0, color: AppColors.purple),
                          ),
                        ),
                      ];
                      return isNarrow ? Column(children: cards) : Row(children: cards);
                    }),

                    const SizedBox(height: 32),

                    // ---- Launch button based on selected mode ----
                    SizedBox(
                      width: double.infinity,
                      child: _LaunchButton(
                        mode: mode,
                        onTap: () {
                          if (mode == AppMode.generator2D) {
                            context.go('/generator');
                          } else {
                            context.go('/viewer3d');
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.go('/theme-lab'),
                        icon: const Icon(Icons.palette_rounded, color: AppColors.textSecondary, size: 18),
                        label: const Text('Theme Lab', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final AppMode mode;
  final ValueChanged<AppMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(6),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(child: _seg(context, '2D Generator', Icons.grid_on_rounded, AppMode.generator2D)),
          Expanded(child: _seg(context, '3D Viewer', Icons.view_in_ar_rounded, AppMode.viewer3D)),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, IconData icon, AppMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? AppColors.cyanPurple : null,
          boxShadow: selected ? AppTheme.neonGlow(AppColors.cyan, blur: 16) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.black : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountUpCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final int value;
  final Color color;
  const _CountUpCard({required this.label, required this.icon, required this.value, required this.color});

  @override
  State<_CountUpCard> createState() => _CountUpCardState();
}

class _CountUpCardState extends State<_CountUpCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _count;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _count = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _CountUpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _count = IntTween(begin: oldWidget.value, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: widget.color,
      interactive: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: widget.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _count,
                  builder: (context, _) => Text(
                    '${_count.value}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [Shadow(color: widget.color, blurRadius: 12)],
                    ),
                  ),
                ),
                Text(widget.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchButton extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onTap;
  const _LaunchButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = mode == AppMode.generator2D ? 'Open 2D Generator' : 'Open 3D Viewer';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.cyanPurple,
            boxShadow: AppTheme.neonGlow(AppColors.cyan, blur: 22),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
