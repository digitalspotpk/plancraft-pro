import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../core/web_download.dart';
import '../models/floor_plan.dart';
import '../providers/plan_provider.dart';
import '../widgets/floor_plan_painter.dart';
import '../widgets/glass_card.dart';
import '../widgets/particle_background.dart';

class Generator2DScreen extends ConsumerStatefulWidget {
  const Generator2DScreen({super.key});

  @override
  ConsumerState<Generator2DScreen> createState() => _Generator2DScreenState();
}

class _Generator2DScreenState extends ConsumerState<Generator2DScreen> {
  late final TextEditingController _lengthCtrl;
  late final TextEditingController _widthCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(planProvider);
    _lengthCtrl = TextEditingController(text: s.lengthFt.toStringAsFixed(0));
    _widthCtrl = TextEditingController(text: s.widthFt.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    super.dispose();
  }

  void _applyDimensions() {
    final l = double.tryParse(_lengthCtrl.text) ?? ref.read(planProvider).lengthFt;
    final w = double.tryParse(_widthCtrl.text) ?? ref.read(planProvider).widthFt;
    ref.read(planProvider.notifier).setDimensions(l.clamp(10, 200), w.clamp(10, 200));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground()),
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
                      const Text('2D Floor Plan Generator',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Input row: Length x Width + Generate button
                  GlassCard(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _dimField('Length (ft)', _lengthCtrl),
                        const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 16),
                        _dimField('Width (ft)', _widthCtrl),
                        ElevatedButton.icon(
                          onPressed: () {
                            _applyDimensions();
                            ref.read(planProvider.notifier).generateFive();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Generate 5 Plans', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: state.generatedBatch.isEmpty
                        ? const _EmptyState()
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: state.generatedBatch.length,
                            itemBuilder: (context, i) => _PlanCard(
                              plan: state.generatedBatch[i],
                              index: i,
                            ),
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

  Widget _dimField(String label, TextEditingController ctrl) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cyan),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.architecture_rounded, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('Enter your plot size and hit "Generate 5 Plans"',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerStatefulWidget {
  final FloorPlan plan;
  final int index;
  const _PlanCard({required this.plan, required this.index});

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _exporting = false;

  Future<void> _exportPng() async {
    setState(() => _exporting = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      downloadPng(Uint8List.fromList(bytes), 'plancraft_plan_${widget.index + 1}.png');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      interactive: true,
      child: Column(
        children: [
          Row(
            children: [
              Text('Plan ${widget.index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh this plan',
                icon: const Icon(Icons.refresh_rounded, color: AppColors.purple, size: 20),
                onPressed: () => ref.read(planProvider.notifier).refreshOne(widget.index),
              ),
              IconButton(
                tooltip: 'Export as PNG',
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))
                    : const Icon(Icons.download_rounded, color: AppColors.cyan, size: 20),
                onPressed: _exporting ? null : _exportPng,
              ),
            ],
          ),
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: AppColors.bgElevated,
                child: CustomPaint(
                  painter: FloorPlanPainter(plan: widget.plan),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.square_foot_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${widget.plan.totalAreaSqFt.toStringAsFixed(0)} sq.ft total',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
