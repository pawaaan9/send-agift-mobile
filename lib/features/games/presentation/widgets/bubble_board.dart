import 'package:flutter/material.dart';

import '../../domain/bubble_shooter.dart';
import '../game_controls.dart';
import 'tilt_3d.dart';

const _bubbleColors = [
  Color(0xFFF87171),
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFF34D399),
  Color(0xFFA78BFA),
  Color(0xFFF472B6),
];

/// Bubble Shooter: tap a column to fire the queued colour up it.
///
/// The queued colour sits under the board with the columns highlighted as you
/// aim, because the whole skill is spotting where that colour already is.
class BubbleBoard extends StatelessWidget {
  const BubbleBoard({required this.game, required this.controls, super.key});

  final BubbleShooter game;
  final GameControls controls;

  void _shoot(int col) {
    if (!controls.active || game.isOver) return;
    game.shoot(col);
    controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final config = game.config;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Tilt3D(
              angle: 0.14,
              child: AspectRatio(
                aspectRatio: config.columns / config.rows,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cell = constraints.maxWidth / config.columns;
                    return Stack(
                      children: [
                        // The wall, drawn from the top down.
                        for (var row = 0; row < config.rows; row++)
                          for (var col = 0; col < config.columns; col++)
                            if (game.at(row, col) >= 0)
                              Positioned(
                                left: col * cell,
                                // Row 0 is the ceiling, so it draws at the top.
                                top: row * cell,
                                width: cell,
                                height: cell,
                                child: _Bubble(
                                  color: _bubbleColors[
                                      game.at(row, col) % _bubbleColors.length],
                                ),
                              ),
                        // Tap targets, one per column.
                        Row(
                          children: [
                            for (var col = 0; col < config.columns; col++)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => _shoot(col),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Queue(game: game),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // A light source up and left, so each bubble reads as a sphere
          // rather than a flat dot.
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: [
              Color.lerp(color, Colors.white, 0.55)!,
              color,
              extrusionShade(color, 0.16),
            ],
            stops: const [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Queue extends StatelessWidget {
  const _Queue({required this.game});

  final BubbleShooter game;

  @override
  Widget build(BuildContext context) {
    final color = _bubbleColors[game.next % _bubbleColors.length];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Next',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          height: 34,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _Bubble(key: ValueKey(game.next), color: color),
          ),
        ),
      ],
    );
  }
}
