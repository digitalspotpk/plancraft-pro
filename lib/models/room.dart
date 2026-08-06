import 'package:flutter/material.dart';

/// A single rectangular room inside a generated floor plan.
/// Coordinates are stored in "feet" relative to the plot's top-left corner.
class Room {
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;

  const Room({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  Rect get rect => Rect.fromLTWH(x, y, width, height);
  double get area => width * height;

  Room copyWith({double? x, double? y, double? width, double? height}) => Room(
        name: name,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        color: color,
      );
}
