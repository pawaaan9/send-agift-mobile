import 'package:flutter/material.dart';

/// Leans a flat board back in perspective, like a game board on a table,
/// so it reads as a 3D object rather than a flat panel.
///
/// Hit testing follows the transform, so taps still land on the tile under
/// the finger.
class Tilt3D extends StatelessWidget {
  const Tilt3D({required this.child, this.angle = 0.2, super.key});

  final Widget child;

  /// How far the top edge leans away, in radians.
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.95,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(angle),
        child: child,
      ),
    );
  }
}

/// A darker shade of [color], for the extruded side of a 3D tile.
Color extrusionShade(Color color, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}
