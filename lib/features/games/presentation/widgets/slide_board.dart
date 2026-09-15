import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/game_engine.dart';
import '../../domain/slide_puzzle.dart';
import '../game_controls.dart';
import 'game_hud.dart';
import 'tilt_3d.dart';

const double _minSwipeVelocity = 90;

/// The sliding puzzle. Tiles glide to their new cell; tap one in line with
/// the gap, or swipe it in.
class SlideBoard extends StatelessWidget {
  const SlideBoard({required this.game, required this.controls, super.key});

  final SlidePuzzle game;
  final GameControls controls;

  void _tap(int index) {
    if (!controls.active) return;
    if (game.moveTileAt(index)) controls.onChanged();
  }

  /// A swipe names the direction the tile travels, same as the move log.
  void _swipe(String dir) {
    if (!controls.active) return;
    if (game.move(dir)) controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final board = game.board;
    final n = game.size;
    final total = n * n - 1;
    final solved = game.solved;

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
                final cell = (constraints.maxWidth - gap * (n - 1)) / n;
                return Stack(
                  children: [
                    for (var i = 0; i < board.length; i++)
                      Positioned(
                        left: (i % n) * (cell + gap),
                        top: (i ~/ n) * (cell + gap),
                        width: cell,
                        height: cell,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    for (var value = 1; value <= total; value++)
                      _positioned(board, n, cell, gap, value, total, solved),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _positioned(
    List<int> board,
    int n,
    double cell,
    double gap,
    int value,
    int total,
    bool solved,
  ) {
    final index = board.indexOf(value);
    return AnimatedPositioned(
      // Keyed by the number, so a tile keeps its identity and glides.
      key: ValueKey(value),
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      left: (index % n) * (cell + gap),
      top: (index ~/ n) * (cell + gap),
      width: cell,
      height: cell,
      child: GestureDetector(
        onTap: () => _tap(index),
        child: _SlideTile(
          value: value,
          total: total,
          home: index == value - 1,
          solved: solved,
          extent: cell,
        ),
      ),
    );
  }
}

class _SlideTile extends StatelessWidget {
  const _SlideTile({
    required this.value,
    required this.total,
    required this.home,
    required this.solved,
    required this.extent,
  });

  final int value;
  final int total;
  final bool home;
  final bool solved;
  final double extent;

  @override
  Widget build(BuildContext context) {
    // A rainbow across the numbers, so the finished order reads at a glance.
    final hue = (190 + (value - 1) / total * 300) % 360;
    final top = HSVColor.fromAHSV(1, hue, 0.55, 1).toColor();
    final bottom = HSVColor.fromAHSV(1, (hue + 18) % 360, 0.8, 0.85).toColor();

    final tile = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: home ? 0.9 : 0.25),
          width: home ? 2.5 : 1,
        ),
        boxShadow: [
          // Solid side slab: the tile stands up off the board.
          BoxShadow(
            color: extrusionShade(bottom),
            offset: Offset(0, extent * 0.07),
          ),
          BoxShadow(
            color: bottom.withValues(alpha: 0.5),
            blurRadius: solved ? 22 : 12,
            offset: Offset(0, extent * 0.12),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: const Alignment(0, 0.1),
          colors: [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
      child: Stack(
        // Fill the tile, so the check mark sits in the tile's corner rather
        // than the corner of the number.
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              '$value',
              style: AppTypography.display(extent * 0.42, color: Colors.white),
            ),
          ),
          if (home)
            Positioned(
              top: extent * 0.08,
              right: extent * 0.08,
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: extent * 0.16,
              ),
            ),
        ],
      ),
    );

    if (!solved) return tile;
    // Solved: every tile does a little celebratory bounce.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: Duration(milliseconds: 400 + value * 40),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: tile,
    );
  }
}
