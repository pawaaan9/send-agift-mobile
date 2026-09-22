import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/fruit_slice.dart';
import '../game_controls.dart';
import 'tick_clock.dart';

const _fruitLooks = [
  (Color(0xFFEF4444), Color(0xFF991B1B)), // apple
  (Color(0xFFFBBF24), Color(0xFFB45309)), // orange
  (Color(0xFF34D399), Color(0xFF047857)), // lime
  (Color(0xFFF472B6), Color(0xFF9D174D)), // berry
];

/// Fruit Slice: gifts arc up through lanes and a swipe cuts them.
///
/// Each throw's height follows its own tick window, so what is on screen is
/// exactly what the server has in the air at that tick — there is no separate
/// animation clock that could drift out of step with the score.
class FruitBoard extends StatefulWidget {
  const FruitBoard({required this.game, required this.controls, super.key});

  final FruitSlice game;
  final GameControls controls;

  @override
  State<FruitBoard> createState() => _FruitBoardState();
}

class _FruitBoardState extends State<FruitBoard>
    with SingleTickerProviderStateMixin {
  late final TickClock _clock = TickClock(
    vsync: this,
    game: widget.game,
    onTicks: (_) {
      if (widget.game.isOver) widget.controls.onChanged();
    },
  );

  /// Where a swipe was drawn, so the blade trail can be shown briefly.
  final List<({int lane, DateTime at})> _slashes = [];

  /// Lanes already cut during the swipe currently in progress, so a slow
  /// finger dragging back and forth over a lane it already cleared doesn't
  /// keep re-registering as a miss and breaking the streak.
  final Set<int> _slicedThisGesture = {};

  @override
  void initState() {
    super.initState();
    _clock.addListener(_onFrame);
    _sync();
  }

  @override
  void didUpdateWidget(covariant FruitBoard oldWidget) {
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
    _slashes.removeWhere((s) => now.difference(s.at).inMilliseconds > 300);
    if (mounted) setState(() {});
  }

  void _slice(int lane) {
    if (!widget.controls.active || widget.game.isOver) return;
    // Already cut this lane during the current swipe — don't let a lingering
    // finger re-report it as a whiff and reset the streak.
    if (!_slicedThisGesture.add(lane)) return;
    widget.game.slice(lane);
    setState(() => _slashes.add((lane: lane, at: DateTime.now())));
    widget.controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final lanes = game.config.lanes;

    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth / lanes;
        int laneOf(Offset local) =>
            (local.dx / laneWidth).floor().clamp(0, lanes - 1);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A pan (not a horizontal drag) so a swipe registers no matter
          // which way it travels — fruit is sliced with vertical and
          // diagonal swipes just as often as horizontal ones, and a
          // direction-locked recognizer was dropping most of them.
          onPanDown: (d) {
            _slicedThisGesture.clear();
            _slice(laneOf(d.localPosition));
          },
          onPanUpdate: (d) => _slice(laneOf(d.localPosition)),
          onPanEnd: (_) => _slicedThisGesture.clear(),
          onPanCancel: () => _slicedThisGesture.clear(),
          child: Stack(
            children: [
              // Lane guides, so a swipe has something to aim at.
              for (var lane = 0; lane < lanes; lane++)
                Positioned(
                  left: lane * laneWidth,
                  top: 0,
                  bottom: 0,
                  width: laneWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(
                            alpha: lane == lanes - 1 ? 0 : 0.07,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Whatever is in the air right now.
              for (final index in game.airborne)
                _throwWidget(game, index, laneWidth, constraints.maxHeight),

              // Blade trails.
              for (final slash in _slashes)
                Positioned(
                  left: slash.lane * laneWidth,
                  top: 0,
                  bottom: 0,
                  width: laneWidth,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _throwWidget(
    FruitSlice game,
    int index,
    double laneWidth,
    double height,
  ) {
    final t = game.throws[index];
    // How far through its flight this throw is, 0 to 1.
    final span = (t.exit - t.enter).clamp(1, 1 << 30);
    final progress = ((game.tick - t.enter) / span).clamp(0.0, 1.0);
    // A parabola: up, hang, and back down — the arc a thrown thing makes.
    final lift = math.sin(progress * math.pi);
    final size = laneWidth * 0.62;
    final top = height - size - lift * (height - size) * 0.82;

    return Positioned(
      left: t.lane * laneWidth + (laneWidth - size) / 2,
      top: top,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: progress * math.pi * 1.5,
          child: t.bomb
              ? const _Bomb()
              : _Fruit(kind: t.kind % _fruitLooks.length),
        ),
      ),
    );
  }
}

class _Fruit extends StatelessWidget {
  const _Fruit({required this.kind});

  final int kind;

  @override
  Widget build(BuildContext context) {
    final (light, dark) = _fruitLooks[kind];
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [Color.lerp(light, Colors.white, 0.4)!, light, dark],
          stops: const [0, 0.5, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _Bomb extends StatelessWidget {
  const _Bomb();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFF6B7280), Color(0xFF111827)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Icon(Icons.local_fire_department_rounded,
            color: Color(0xFFFBBF24), size: 18),
      ),
    );
  }
}
