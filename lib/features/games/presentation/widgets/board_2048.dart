import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/game_2048.dart';
import '../game_controls.dart';
import 'game_hud.dart';
import 'tilt_3d.dart';

/// Below this the drag reads as a stray touch rather than a deliberate swipe.
const double _minSwipeVelocity = 90;

/// The 2048 grid.
///
/// Purely a view of the engine: what is drawn is always exactly what the
/// engine — and therefore the server — thinks the position is.
class Board2048 extends StatelessWidget {
  const Board2048({required this.game, required this.controls, super.key});

  final Game2048 game;
  final GameControls controls;

  void _swipe(String dir) {
    if (!controls.active) return;
    if (game.move(dir)) controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final board = game.board;
    final size = game.size;

    // Horizontal and vertical drags are separate recognisers: a single pan
    // recogniser loses the gesture arena to any scrollable ancestor, which
    // turns up/down swipes into scrolling.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final vx = details.velocity.pixelsPerSecond.dx;
        if (vx.abs() < _minSwipeVelocity) return;
        _swipe(vx > 0 ? Move.right : Move.left);
      },
      onVerticalDragEnd: (details) {
        final vy = details.velocity.pixelsPerSecond.dy;
        if (vy.abs() < _minSwipeVelocity) return;
        _swipe(vy > 0 ? Move.down : Move.up);
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Tilt3D(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: glassDecoration(radius: 26, alpha: 0.2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 9.0;
                final cell = (constraints.maxWidth - gap * (size - 1)) / size;
                return Stack(
                  children: [
                    for (var i = 0; i < board.length; i++)
                      Positioned(
                        left: (i % size) * (cell + gap),
                        top: (i ~/ size) * (cell + gap),
                        width: cell,
                        height: cell,
                        // Keyed by value so a tile pops whenever it spawns or
                        // merges, and sits still otherwise.
                        child: _Tile(
                          key: ValueKey('$i:${board[i]}'),
                          value: board[i],
                          extent: cell,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.extent, super.key});

  final int value;
  final double extent;

  /// Sunrise ramp: warm creams through orange and gold into violet for the
  /// big numbers.
  static const Map<int, List<Color>> _fills = {
    2: [Color(0xFFFFF8EC), Color(0xFFFFEFD6)],
    4: [Color(0xFFFFE9C7), Color(0xFFFFD9A0)],
    8: [Color(0xFFFFC46B), Color(0xFFFF9F43)],
    16: [Color(0xFFFFA55C), Color(0xFFFF7A2F)],
    32: [Color(0xFFFF8A65), Color(0xFFFF5E3A)],
    64: [Color(0xFFFF6B6B), Color(0xFFEE3B3B)],
    128: [Color(0xFFFFE066), Color(0xFFFFC300)],
    256: [Color(0xFFFFD43B), Color(0xFFFFA600)],
    512: [Color(0xFFFFB800), Color(0xFFFF8C00)],
    1024: [Color(0xFFC77DFF), Color(0xFF9D4EDD)],
    2048: [Color(0xFF9D4EDD), Color(0xFF5A189A)],
  };

  List<Color> get _colors =>
      _fills[value] ?? const [Color(0xFF3C096C), Color(0xFF240046)];

  double get _fontSize {
    final base = extent * 0.4;
    if (value >= 1024) return base * 0.6;
    if (value >= 128) return base * 0.75;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      // Empty cells read as wells sunk into the board.
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
      );
    }

    final glow = value >= 128;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _colors,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            // The tile's side: a solid, darker slab under the face makes
            // each tile a raised 3D block.
            BoxShadow(
              color: extrusionShade(_colors.last),
              offset: Offset(0, extent * 0.07),
            ),
            BoxShadow(
              color: (glow ? _colors.last : Colors.black).withValues(
                alpha: glow ? 0.6 : 0.2,
              ),
              blurRadius: glow ? 18 : 10,
              offset: Offset(0, extent * 0.12),
            ),
          ],
        ),
        // A glossy highlight across the top of the face.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, 0.1),
            colors: [
              Colors.white.withValues(alpha: 0.38),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$value',
              style: AppTypography.display(
                _fontSize,
                color: value >= 8 ? Colors.white : const Color(0xFF8A4B08),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
