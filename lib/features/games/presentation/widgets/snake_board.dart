import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/game_engine.dart';
import '../../domain/snake_game.dart';
import '../game_controls.dart';
import 'tilt_3d.dart';

/// The Snake board and its controls.
///
/// This widget owns the clock. Each tick it asks the engine to step, and the
/// engine logs which tick every turn landed on — the clock only decides when
/// ticks happen, never what they do, so the server's replay is unaffected by
/// how smooth the phone is.
class SnakeBoard extends StatefulWidget {
  const SnakeBoard({required this.game, required this.controls, super.key});

  final SnakeGame game;
  final GameControls controls;

  @override
  State<SnakeBoard> createState() => _SnakeBoardState();
}

class _SnakeBoardState extends State<SnakeBoard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _started = false;
  Offset _drag = Offset.zero;
  bool _dragFired = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  SnakeGame get _game => widget.game;

  bool get _running => _started && widget.controls.active && !_game.isOver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SnakeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// Starts or stops the clock to match pause / game-over state. The interval
  /// is re-read every tick because the snake speeds up as it eats.
  void _sync() {
    if (_running) {
      _timer ??= Timer(Duration(milliseconds: _game.tickIntervalMs), _tick);
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    _timer = null;
    if (!mounted || !_running) return;
    _game.step();
    widget.controls.onChanged();
    _sync();
  }

  void _steer(String dir) {
    if (!widget.controls.active || _game.isOver) return;
    _game.turn(dir);
    if (!_started) setState(() => _started = true);
    _sync();
  }

  void _startIfIdle() {
    if (!widget.controls.active || _game.isOver || _started) return;
    setState(() => _started = true);
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _startIfIdle,
            onPanStart: (_) {
              _drag = Offset.zero;
              _dragFired = false;
            },
            // Fire as soon as the finger has clearly moved, not on release —
            // Snake has to feel instant.
            onPanUpdate: (details) {
              if (_dragFired) return;
              _drag += details.delta;
              if (_drag.distance < 18) return;
              _dragFired = true;
              _steer(
                _drag.dx.abs() > _drag.dy.abs()
                    ? (_drag.dx > 0 ? Move.right : Move.left)
                    : (_drag.dy > 0 ? Move.down : Move.up),
              );
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: Tilt3D(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _SnakePainter(
                        body: _game.body,
                        food: _game.food,
                        gridSize: _game.gridSize,
                        heading: _game.heading,
                        dead: _game.dead,
                        pulse: _pulse,
                      ),
                    ),
                    if (!_started && !_game.isOver)
                      // Below centre, so the snake and the way it is facing
                      // stay visible before the first move.
                      Align(
                        alignment: const Alignment(0, 0.62),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Swipe or tap to start',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _DirectionPad(
          heading: _game.heading,
          onSteer: _steer,
          pulse: _pulse,
        ),
      ],
    );
  }
}

class _SnakePainter extends CustomPainter {
  _SnakePainter({
    required this.body,
    required this.food,
    required this.gridSize,
    required this.heading,
    required this.dead,
    required this.pulse,
  }) : super(repaint: pulse);

  final List<int> body;
  final int food;
  final int gridSize;
  final String heading;
  final bool dead;
  final Animation<double> pulse;

  static const _headColor = Color(0xFFB2FF59);
  static const _tailColor = Color(0xFF00E5FF);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final board = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas
      ..save()
      ..clipRRect(board)
      ..drawRRect(
        board,
        Paint()..color = const Color(0xFF031B15).withValues(alpha: 0.78),
      );

    final checker = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            checker,
          );
        }
      }
    }

    if (food >= 0) _paintGift(canvas, cell);

    Rect segment(int i) {
      final inset = cell * (i == 0 ? 0.03 : 0.1);
      return Rect.fromLTWH(
        (body[i] % gridSize) * cell + inset,
        (body[i] ~/ gridSize) * cell + inset,
        cell - inset * 2,
        cell - inset * 2,
      );
    }

    // Shadows first, all of them, so no segment's shadow falls on another.
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.28);
    for (var i = 0; i < body.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          segment(i).shift(Offset(cell * 0.06, cell * 0.12)),
          Radius.circular(cell * 0.34),
        ),
        shadow,
      );
    }

    // Tail first so the head is drawn on top. Each segment is lit from the
    // top left, so the snake reads as a row of beads rather than squares.
    for (var i = body.length - 1; i >= 0; i--) {
      final t = body.length == 1 ? 0.0 : i / (body.length - 1);
      final color = dead && i == 0
          ? const Color(0xFFFF5252)
          : Color.lerp(_headColor, _tailColor, t)!;
      final rect = segment(i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.34)),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 0.9,
            colors: [
              Color.lerp(color, Colors.white, 0.5)!,
              color,
              Color.lerp(color, Colors.black, 0.35)!,
            ],
            stops: const [0, 0.5, 1],
          ).createShader(rect),
      );
    }

    if (body.isNotEmpty) _paintEyes(canvas, cell);
    canvas.restore();
  }

  void _paintGift(Canvas canvas, double cell) {
    final center = Offset(
      (food % gridSize + 0.5) * cell,
      (food ~/ gridSize + 0.5) * cell,
    );
    final glowRadius = cell * (0.75 + 0.35 * pulse.value);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF4FA3).withValues(alpha: 0.55),
            const Color(0xFFFF4FA3).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );

    final box = Rect.fromCenter(
      center: center,
      width: cell * 0.7,
      height: cell * 0.7,
    );
    // The box's front face, so the gift stands up as a cube.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        box.shift(Offset(0, cell * 0.12)),
        Radius.circular(cell * 0.14),
      ),
      Paint()..color = const Color(0xFFB0246A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(cell * 0.14)),
      Paint()..color = const Color(0xFFFF4FA3),
    );
    final ribbon = Paint()..color = const Color(0xFFFFE066);
    canvas
      ..drawRect(
        Rect.fromCenter(center: center, width: cell * 0.14, height: cell * 0.7),
        ribbon,
      )
      ..drawRect(
        Rect.fromCenter(center: center, width: cell * 0.7, height: cell * 0.14),
        ribbon,
      )
      ..drawCircle(box.topCenter.translate(-cell * 0.1, 0), cell * 0.09, ribbon)
      ..drawCircle(box.topCenter.translate(cell * 0.1, 0), cell * 0.09, ribbon);
  }

  void _paintEyes(Canvas canvas, double cell) {
    final head = body.first;
    final center = Offset(
      (head % gridSize + 0.5) * cell,
      (head ~/ gridSize + 0.5) * cell,
    );
    final (dx, dy) = Move.delta(heading);
    final forward = Offset(dx.toDouble(), dy.toDouble());
    final side = Offset(-forward.dy, forward.dx);
    for (final s in [-1.0, 1.0]) {
      final eye = center + forward * cell * 0.16 + side * cell * 0.19 * s;
      canvas
        ..drawCircle(eye, cell * 0.12, Paint()..color = Colors.white)
        ..drawCircle(
          eye + forward * cell * 0.04,
          cell * 0.06,
          Paint()..color = const Color(0xFF0B1320),
        );
    }
  }

  @override
  bool shouldRepaint(_SnakePainter oldDelegate) => true;
}

/// A joystick-style D-pad: four keys around a glowing hub that shows which
/// way the snake is currently heading, in place of four identical circles.
class _DirectionPad extends StatelessWidget {
  const _DirectionPad({
    required this.heading,
    required this.onSteer,
    required this.pulse,
  });

  final String heading;
  final ValueChanged<String> onSteer;
  final Animation<double> pulse;

  static const _hubColor = Color(0xFFB2FF59);

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    const key = 56.0;
    const hub = 52.0;
    return SizedBox(
      width: key * 3 + gap * 2,
      height: key * 3 + gap * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _DPadKey(
              icon: Icons.keyboard_arrow_up_rounded,
              tooltip: 'Up',
              active: heading == Move.up,
              onTap: () => onSteer(Move.up),
            ),
          ),
          Positioned(
            bottom: 0,
            child: _DPadKey(
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: 'Down',
              active: heading == Move.down,
              onTap: () => onSteer(Move.down),
            ),
          ),
          Positioned(
            left: 0,
            child: _DPadKey(
              icon: Icons.keyboard_arrow_left_rounded,
              tooltip: 'Left',
              active: heading == Move.left,
              onTap: () => onSteer(Move.left),
            ),
          ),
          Positioned(
            right: 0,
            child: _DPadKey(
              icon: Icons.keyboard_arrow_right_rounded,
              tooltip: 'Right',
              active: heading == Move.right,
              onTap: () => onSteer(Move.right),
            ),
          ),

          // The hub: a small compass needle pointing the way the snake is
          // actually travelling right now, breathing gently with the same
          // pulse as the food glow.
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final glow = 0.35 + 0.25 * pulse.value;
              return Container(
                width: hub,
                height: hub,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _hubColor.withValues(alpha: 0.9),
                      _hubColor.withValues(alpha: 0.25),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hubColor.withValues(alpha: glow),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: child,
              );
            },
            child: AnimatedRotation(
              turns: switch (heading) {
                Move.up => 0,
                Move.right => 0.25,
                Move.down => 0.5,
                _ => 0.75,
              },
              duration: const Duration(milliseconds: 150),
              child: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF04331F),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One D-pad key: a rounded glass tile that bounces on press and lights up
/// when it's the direction the snake is already travelling.
class _DPadKey extends StatefulWidget {
  const _DPadKey({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_DPadKey> createState() => _DPadKeyState();
}

class _DPadKeyState extends State<_DPadKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.active ? 0.85 : (_pressed ? 0.4 : 0.18);
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: widget.active ? 0.32 : 0.16),
                  Colors.white.withValues(alpha: widget.active ? 0.14 : 0.05),
                ],
              ),
              border: Border.all(
                color: widget.active
                    ? const Color(0xFFB2FF59).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.28),
                width: widget.active ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB2FF59).withValues(alpha: glow * 0.5),
                  blurRadius: widget.active ? 14 : 6,
                  spreadRadius: widget.active ? 1 : 0,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
