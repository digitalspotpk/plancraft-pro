import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/app_theme.dart';
import '../models/floor_plan.dart';
import '../models/room.dart';

/// "Which mode is the app in" — matches the Dashboard's 2-mode toggle.
enum AppMode { generator2D, viewer3D }

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.generator2D);

/// Dashboard stat counters (for the count-up cards).
class DashboardStats {
  final int plansGenerated;
  final int viewsRendered;
  const DashboardStats({required this.plansGenerated, required this.viewsRendered});
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final plans = await PlanRepository.plansGeneratedCount();
  final views = await PlanRepository.viewsRenderedCount();
  return DashboardStats(plansGenerated: plans, viewsRendered: views);
});

/// Holds the plot dimensions + the batch of generated plans currently shown
/// on the 2D Generator screen, plus which one is selected for the 3D Viewer.
class PlanState {
  final double lengthFt;
  final double widthFt;
  final List<FloorPlan> generatedBatch;
  final int selectedIndex;

  const PlanState({
    this.lengthFt = 40,
    this.widthFt = 30,
    this.generatedBatch = const [],
    this.selectedIndex = 0,
  });

  FloorPlan? get selectedPlan =>
      generatedBatch.isEmpty ? null : generatedBatch[selectedIndex.clamp(0, generatedBatch.length - 1)];

  PlanState copyWith({
    double? lengthFt,
    double? widthFt,
    List<FloorPlan>? generatedBatch,
    int? selectedIndex,
  }) {
    return PlanState(
      lengthFt: lengthFt ?? this.lengthFt,
      widthFt: widthFt ?? this.widthFt,
      generatedBatch: generatedBatch ?? this.generatedBatch,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier() : super(const PlanState());
  final Random _rng = Random();
  final Uuid _uuid = const Uuid();

  void setDimensions(double length, double width) {
    state = state.copyWith(lengthFt: length, widthFt: width);
  }

  /// Generates 5 randomized room layouts for the current plot size.
  /// Simple constructive algorithm: split the plot into a grid of rooms
  /// with slight randomized proportions each pass, so every one of the 5
  /// plans looks distinct while always fitting inside L x W.
  void generateFive() {
    final batch = List.generate(5, (_) => _generateOne(state.lengthFt, state.widthFt));
    state = state.copyWith(generatedBatch: batch, selectedIndex: 0);
    for (final p in batch) {
      PlanRepository.savePlan(p);
    }
  }

  void refreshOne(int index) {
    if (state.generatedBatch.isEmpty) return;
    final updated = [...state.generatedBatch];
    updated[index] = _generateOne(state.lengthFt, state.widthFt);
    state = state.copyWith(generatedBatch: updated);
    PlanRepository.savePlan(updated[index]);
  }

  void selectIndex(int i) => state = state.copyWith(selectedIndex: i);

  FloorPlan _generateOne(double L, double W) {
    // Room name pool + weighted target-area fractions of total plot area.
    const template = [
      ['Living Room', 0.28, AppColors.cyan],
      ['Master Bedroom', 0.20, AppColors.purple],
      ['Kitchen', 0.14, Color(0xFFFFD23E)],
      ['Bedroom 2', 0.16, Color(0xFF39FFB0)],
      ['Bathroom', 0.08, Color(0xFF3E8BFF)],
      ['Balcony', 0.14, Color(0xFFFF6B3E)],
    ];

    // Randomize the ordering / split slightly each generation for variety.
    final jitter = () => 0.85 + _rng.nextDouble() * 0.3;

    final rooms = <Room>[];
    double cursorY = 0;
    // Two-column layout: left column wider (living + kitchen stacked),
    // right column narrower (bedrooms + bath stacked). Randomize split ratio.
    final splitRatio = 0.55 + _rng.nextDouble() * 0.12; // 0.55 - 0.67
    final leftW = L * splitRatio;
    final rightW = L - leftW;

    // LEFT column: Living Room + Kitchen
    final livingH = W * (0.55 * jitter()).clamp(0.3, 0.7);
    rooms.add(Room(
      name: 'Living Room',
      x: 0,
      y: 0,
      width: leftW,
      height: livingH,
      color: (template[0][2] as Color),
    ));
    rooms.add(Room(
      name: 'Kitchen',
      x: 0,
      y: livingH,
      width: leftW,
      height: W - livingH,
      color: (template[2][2] as Color),
    ));

    // RIGHT column: Master Bedroom, Bedroom 2, Bathroom stacked with jitter
    final masterH = W * (0.42 * jitter()).clamp(0.28, 0.5);
    final bathH = W * (0.18 * jitter()).clamp(0.12, 0.24);
    final bed2H = W - masterH - bathH;
    cursorY = 0;
    rooms.add(Room(name: 'Master Bedroom', x: leftW, y: cursorY, width: rightW, height: masterH, color: template[1][2] as Color));
    cursorY += masterH;
    rooms.add(Room(name: 'Bedroom 2', x: leftW, y: cursorY, width: rightW, height: bed2H.clamp(2, W), color: template[3][2] as Color));
    cursorY += bed2H;
    rooms.add(Room(name: 'Bathroom', x: leftW, y: cursorY, width: rightW, height: bathH, color: template[4][2] as Color));

    return FloorPlan(
      id: _uuid.v4(),
      lengthFt: L,
      widthFt: W,
      rooms: rooms,
      createdAt: DateTime.now(),
    );
  }
}

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>((ref) => PlanNotifier());
