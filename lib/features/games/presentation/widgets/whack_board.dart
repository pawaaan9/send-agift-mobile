import 'package:flutter/material.dart';

import '../../domain/whack_a_mole.dart';
import '../game_controls.dart';
import 'tick_clock.dart';
import 'tilt_3d.dart';

/// Whack-a-Mole: a field of holes with moles popping out of them.
///
/// The mole rises and drops on the same ticks the server replays, so what the
/// player swings at is exactly what gets scored.
class WhackBoard extends StatefulWidget {
  const WhackBoard({required this.game, required this.controls, super.key});

  final WhackAMole game;
  final GameControls controls;

  @override
  State<WhackBoard> createState() => _WhackBoardState();
}

class _WhackBoardState extends State<WhackBoard>
    with SingleTickerProviderStateMixin {
  late final TickClock _clock = TickClock(
    vsync: this,
    game: widget.game,
    onTicks: (_) {
      if (widget.game.isOver) widget.controls.onChanged();
    },
  );

  /// Holes flash briefly when struck, so a hit reads even at speed.
  final Map<int, DateTime> _struck = {};

  @override
  void initState() {
    super.initState();
    _clock.addListener(_onFrame);
    _sync();
  }

  @override
  void didUpdateWidget(covariant WhackBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _clock
      ..removeListener(_onFrame)
      ..dispose();
    super.dispose();
  }

  void _sync() => _clock.run(widget.controls.active && !widget.game.isOver);

  void _onFrame() {
    final now = DateTime.now();
    _struck.removeWhere((_, at) => now.difference(at).inMilliseconds > 260);
    if (mounted) setState(() {});
  }

  void _hit(int hole) {
    if (!widget.controls.active || widget.game.isOver) return;
    widget.game.whack(hole);
    setState(() => _struck[hole] = DateTime.now());
    widget.controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final active = game.activeMole;
    final upHole = active >= 0 && !game.wasHit(active)
        ? game.moles[active].hole
        : -1;

    return Center(
      child: Tilt3D(
        angle: 0.22,
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: game.config.holes,
            itemBuilder: (context, hole) => _Hole(
              up: hole == upHole,
              struck: _struck.containsKey(hole),
              onTap: () => _hit(hole),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hole extends StatelessWidget {
  const _Hole({required this.up, required this.struck, required this.onTap});

  final bool up;
  final bool struck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The hole itself: a dark ellipse the mole climbs out of.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1C0F02), Color(0xFF3F2410)],
              ),
              border: Border.all(
                color: struck
                    ? const Color(0xFFFCD34D)
                    : Colors.white.withValues(alpha: 0.18),
                width: struck ? 3 : 1.5,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // The mole, sliding up out of the hole.
          ClipOval(
            child: SizedBox.expand(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                alignment: up ? Alignment.center : const Alignment(0, 2.2),
                child: const _Mole(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mole extends StatelessWidget {
  const _Mole();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.66,
      heightFactor: 0.66,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFC08457), Color(0xFF8B5A2B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Eye(),
                SizedBox(width: 9),
                _Eye(),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 13,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFCA5A5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1F2937),
      ),
    );
  }
}
