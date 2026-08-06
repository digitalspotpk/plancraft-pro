import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'room.dart';

/// A full generated floor plan: plot size + list of rooms.
/// We implement HiveObject manually (no build_runner needed) by storing
/// plans as plain Maps — keeps the offline build pipeline dependency-free.
class FloorPlan {
  final String id;
  final double lengthFt;
  final double widthFt;
  final List<Room> rooms;
  final DateTime createdAt;

  FloorPlan({
    required this.id,
    required this.lengthFt,
    required this.widthFt,
    required this.rooms,
    required this.createdAt,
  });

  double get totalAreaSqFt => lengthFt * widthFt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'lengthFt': lengthFt,
        'widthFt': widthFt,
        'createdAt': createdAt.toIso8601String(),
        'rooms': rooms
            .map((r) => {
                  'name': r.name,
                  'x': r.x,
                  'y': r.y,
                  'width': r.width,
                  'height': r.height,
                  'color': r.color.value,
                })
            .toList(),
      };

  factory FloorPlan.fromMap(Map map) => FloorPlan(
        id: map['id'] as String,
        lengthFt: (map['lengthFt'] as num).toDouble(),
        widthFt: (map['widthFt'] as num).toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        rooms: (map['rooms'] as List)
            .map((r) => Room(
                  name: r['name'] as String,
                  x: (r['x'] as num).toDouble(),
                  y: (r['y'] as num).toDouble(),
                  width: (r['width'] as num).toDouble(),
                  height: (r['height'] as num).toDouble(),
                  color: Color(r['color'] as int),
                ))
            .toList(),
      );
}

/// Hive box wrapper for saved plans + simple usage stats (used by Dashboard
/// count-up cards). Box type is untyped (Map) — no TypeAdapter/codegen
/// required, which keeps `flutter pub get` + `flutter build web` friction-free.
class PlanRepository {
  static const plansBoxName = 'plansBox';
  static const statsBoxName = 'statsBox';

  static Future<Box> _plansBox() => Hive.openBox(plansBoxName);
  static Future<Box> _statsBox() => Hive.openBox(statsBoxName);

  static Future<void> savePlan(FloorPlan plan) async {
    final box = await _plansBox();
    await box.put(plan.id, plan.toMap());
    await _bumpStat('plansGenerated');
  }

  static Future<List<FloorPlan>> loadPlans() async {
    final box = await _plansBox();
    return box.values.map((m) => FloorPlan.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  static Future<int> plansGeneratedCount() async {
    final box = await _statsBox();
    return (box.get('plansGenerated', defaultValue: 0)) as int;
  }

  static Future<int> viewsRenderedCount() async {
    final box = await _statsBox();
    return (box.get('viewsRendered', defaultValue: 0)) as int;
  }

  static Future<void> bumpViewsRendered() => _bumpStat('viewsRendered');

  static Future<void> _bumpStat(String key) async {
    final box = await _statsBox();
    final current = (box.get(key, defaultValue: 0)) as int;
    await box.put(key, current + 1);
  }
}
