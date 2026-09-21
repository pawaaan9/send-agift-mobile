import 'package:flutter/material.dart';

import '../../domain/doodle_jump.dart';
import '../game_controls.dart';

/// How many rungs of the tower are on screen at once.
const _visibleRungs = 7;

/// Doodle Jump: a tower of ledges seen from the side, climbed a rung at a time.
///
/// Lanes out of reach are dimmed rather than hidden, so the rule — your lane
/// and the two beside it — is visible instead of something you learn by
/// falling.
class DoodleBoard extends StatefulWidget {
  const DoodleBoard({required this.game, required this.controls, super.key});

  final DoodleJump game;
  final GameControls controls;

  @override
  State<DoodleBoard> createState() => _DoodleBoardState();
}

class _DoodleBoardState extends State<DoodleBoard> {
  void _hop(int lane) {
    if (!widget.controls.active || widget.game.isOver) return;
    if (!widget.game.canReach(lane)) return;
    widget.game.hop(lane);
    setState(() {});
    widget.controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final lanes = game.config.lanes;

    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth / lanes;
        final rungHeight = constraints.maxHeight / _visibleRungs;

        return Stack(
          children: [
            // Ledges, drawn from the player's rung upward so the climb always
            // shows what is coming next.
            for (var offset = -1; offset < _visibleRungs; offset++)
              ..._rung(game, offset, laneWidth, rungHeight, constraints),

            // The jumper.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              left: game.lane * laneWidth + laneWidth * 0.2,
              bottom: rungHeight * 1.05,
              width: laneWidth * 0.6,
              height: rungHeight * 0.62,
              child: const _Jumper(),
            ),

            // Tap targets, one per lane, dimmed when out of reach.
            Row(
              children: [
                for (var lane = 0; lane < lanes; lane++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _hop(lane),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        color: game.canReach(lane)
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// One rung of the tower, offset rungs above the player.
  List<Widget> _rung(
    DoodleJump game,
    int offset,
    double laneWidth,
    double rungHeight,
    BoxConstraints constraints,
  ) {
    final index = game.height + offset;
    if (index < 0 || index >= game.platforms.length) return const [];
    final platform = game.platformAt(index);
    // offset 0 is the rung underfoot, sitting near the bottom.
    final bottom = rungHeight * (offset + 1);
    if (bottom > constraints.maxHeight) return const [];

    Widget ledge(int lane) => Positioned(
      left: lane * laneWidth + laneWidth * 0.12,
      bottom: bottom,
      width: laneWidth * 0.76,
      height: 12,
      child: _Ledge(spring: platform.spring, current: offset == 0),
    );

    return [
      ledge(platform.lane),
      if (platform.alt >= 0) ledge(platform.alt),
    ];
  }
}

class _Ledge extends StatelessWidget {
  const _Ledge({required this.spring, required this.current});

  final bool spring;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = spring ? const Color(0xFFFCD34D) : const Color(0xFF34D399);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.4)!,
            color,
            Color.lerp(color, Colors.black, 0.3)!,
          ],
          stops: const [0, 0.4, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: current ? 0.6 : 0.3),
            blurRadius: current ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: spring
          ? const Center(
              child: Icon(Icons.keyboard_double_arrow_up_rounded,
                  size: 10, color: Color(0xFF78350F)),
            )
          : null,
    );
  }
}

class _Jumper extends StatelessWidget {
  const _Jumper();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA7F3D0), Color(0xFF059669)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.sentiment_satisfied_rounded,
            size: 18, color: Color(0xFF064E3B)),
      ),
    );
  }
}
