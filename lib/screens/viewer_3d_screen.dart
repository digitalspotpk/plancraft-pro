import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../models/floor_plan.dart';
import '../providers/plan_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/isometric_3d_painter.dart';
import '../widgets/particle_background.dart';

class Viewer3DScreen extends ConsumerStatefulWidget {
  const Viewer3DScreen({super.key});

  @override
  ConsumerState<Viewer3DScreen> createState() => _Viewer3DScreenState();
}

class _Viewer3DScreenState extends ConsumerState<Viewer3DScreen> {
  double _yaw = -0.6;
  double _pitch = 0.5;
  double _zoom = 1.0;
  bool _isNight = false;
  bool _countedView = false;

  void _bumpViewOnce() {
    if (_countedView) return;
    _countedView = true;
    PlanRepository.bumpViewsRendered();
    ref.invalidate(dashboardStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);
    final plan = planState.selectedPlan;

    if (plan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bumpViewOnce());
    }

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground(particleCount: 20)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      const Text('3D Viewer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Spacer(),
                      if (planState.generatedBatch.isNotEmpty)
                        _PlanSwitcher(state: planState),
                    ],
                  ),
                ),
                Expanded(
                  child: plan == null
                      ? const _NoPlanState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _yaw += details.delta.dx * 0.01;
                                    _pitch = (_pitch + details.delta.dy * 0.01).clamp(-1.2, 1.2);
                                  });
                                },
                                child: Listener(
                                  onPointerSignal: (event) {
                                    // mouse wheel zoom
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: GestureDetector(
                                      onScaleUpdate: (details) {
                                        setState(() {
                                          _zoom = (_zoom * details.scale).clamp(0.4, 3.0);
                                        });
                                      },
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: CustomPaint(
                                          painter: Isometric3DPainter(
                                            plan: plan,
                                            yaw: _yaw,
                                            pitch: _pitch,
                                            zoom: _zoom,
                                            isNight: _isNight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                if (plan != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _Controls(
                      isNight: _isNight,
                      onToggleNight: (v) => setState(() => _isNight = v),
                      onZoomIn: () => setState(() => _zoom = (_zoom * 1.15).clamp(0.4, 3.0)),
                      onZoomOut: () => setState(() => _zoom = (_zoom / 1.15).clamp(0.4, 3.0)),
                      onResetOrbit: () => setState(() {
                        _yaw = -0.6;
                        _pitch = 0.5;
                        _zoom = 1.0;
                      }),
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

class _NoPlanState extends StatelessWidget {
  const _NoPlanState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.view_in_ar_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('No plan selected yet', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.go('/generator'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black),
            child: const Text('Generate a plan first'),
          ),
        ],
      ),
    );
  }
}

class _PlanSwitcher extends ConsumerWidget {
  final PlanState state;
  const _PlanSwitcher({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<int>(
      value: state.selectedIndex,
      dropdownColor: AppColors.bgElevated,
      underline: const SizedBox(),
      icon: const Icon(Icons.expand_more_rounded, color: AppColors.cyan),
      items: List.generate(
        state.generatedBatch.length,
        (i) => DropdownMenuItem(value: i, child: Text('Plan ${i + 1}', style: const TextStyle(color: Colors.white))),
      ),
      onChanged: (i) {
        if (i != null) ref.read(planProvider.notifier).selectIndex(i);
      },
    );
  }
}

class _Controls extends StatelessWidget {
  final bool isNight;
  final ValueChanged<bool> onToggleNight;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetOrbit;

  const _Controls({
    required this.isNight,
    required this.onToggleNight,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetOrbit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: isNight ? AppColors.purple : AppColors.cyan, size: 20),
          const SizedBox(width: 8),
          Text(isNight ? 'Night' : 'Day', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Switch(
            value: isNight,
            onChanged: onToggleNight,
            activeColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withOpacity(0.3),
          ),
          const Spacer(),
          IconButton(onPressed: onZoomOut, icon: const Icon(Icons.remove_circle_outline, color: Colors.white)),
          const Text('Zoom', style: TextStyle(color: AppColors.textSecondary)),
          IconButton(onPressed: onZoomIn, icon: const Icon(Icons.add_circle_outline, color: Colors.white)),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onResetOrbit,
            icon: const Icon(Icons.threed_rotation_rounded, color: AppColors.cyan, size: 18),
            label: const Text('Reset Orbit', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }
}
