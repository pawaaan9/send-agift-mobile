import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/hill_rider.dart';
import '../game_controls.dart';
import 'tick_clock.dart';

/// Hill Rider, side on with parallax hills. Hold GAS to drive and BRAKE to
/// slow down before a crest.
class HillRiderBoard extends StatefulWidget {
  const HillRiderBoard({required this.game, required this.controls, super.key});

  final HillRider game;
  final GameControls controls;

  @override
  State<HillRiderBoard> createState() => _HillRiderBoardState();
}

class _HillRiderBoardState extends State<HillRiderBoard>
    with SingleTickerProviderStateMixin {
  late final TickClock _clock = TickClock(
    vsync: this,
    game: widget.game,
    onTicks: (_) {
      final g = widget.game;
      final fuel = g.fuel * 100 ~/ g.config.startFuel;
      if (g.distance != _lastDistance || fuel != _lastFuel || g.isOver) {
        _lastDistance = g.distance;
        _lastFuel = fuel;
        widget.controls.onChanged();
      }
    },
  );

  bool _started = false;
  int _lastDistance = -1;
  int _lastFuel = -1;
  int _gas = 0;
  int _brake = 0;

  /// The camera eases after the car vertically rather than jumping.
  double _camY = 0;
  double? _crashedAt;

  HillRider get _game => widget.game;

  @override
  void initState() {
    super.initState();
    _clock.addListener(_onFrame);
  }

  @override
  void didUpdateWidget(covariant HillRiderBoard oldWidget) {
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

  void _sync() =>
      _clock.run(_started && widget.controls.active && !_game.isOver);

  void _onFrame() {
    _camY += (_game.y - _camY) * 0.12;
    if (_game.crashed && _crashedAt == null) _crashedAt = _clock.wallMs;
  }

  void _pedals() {
    final pedal = _gas > 0
        ? HillPedal.gas
        : (_brake > 0 ? HillPedal.brake : HillPedal.neutral);
    _game.setPedal(pedal);
    if (!_started && pedal != HillPedal.neutral && widget.controls.active) {
      _started = true;
      _sync();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The pedals sit over the road rather than on a strip beneath it. Given
    // their own row they took a fifth of the height off the scene, which on a
    // phone is the difference between driving down a hill and watching one
    // through a letterbox.
    return ClipRRect(
      // Square: the scene runs to the corners of the screen now, and a
      // rounded one would leave the backdrop showing through them.
      borderRadius: BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _HillPainter(
              game: _game,
              clock: _clock,
              camY: () => _camY,
              crashedAt: () => _crashedAt,
            ),
          ),
          AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => _Gauges(game: _game),
          ),
          if (!_started)
            Align(
              alignment: const Alignment(0, -0.2),
              child: IgnorePointer(
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
                    'Hold GAS to start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Row(
              children: [
                _Pedal(
                  key: const ValueKey('hill-brake'),
                  label: 'BRAKE',
                  colors: const [Color(0xFFFF8A80), Color(0xFFC62828)],
                  pressed: _brake > 0,
                  onDown: () {
                    _brake++;
                    _pedals();
                  },
                  onUp: () {
                    _brake = math.max(0, _brake - 1);
                    _pedals();
                  },
                ),
                const Spacer(),
                _Pedal(
                  key: const ValueKey('hill-gas'),
                  label: 'GAS',
                  colors: const [Color(0xFFB9F6CA), Color(0xFF2E7D32)],
                  pressed: _gas > 0,
                  wide: true,
                  onDown: () {
                    _gas++;
                    _pedals();
                  },
                  onUp: () {
                    _gas = math.max(0, _gas - 1);
                    _pedals();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A chunky 3D pedal. Press and hold — it tracks the finger, not taps.
class _Pedal extends StatelessWidget {
  const _Pedal({
    required this.label,
    required this.colors,
    required this.pressed,
    required this.onDown,
    required this.onUp,
    this.wide = false,
    super.key,
  });

  final String label;
  final List<Color> colors;
  final bool pressed;
  final bool wide;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: SizedBox(
        width: wide ? 150 : 120,
        height: 78,
        child: Stack(
          children: [
            // The pedal's side, visible until it is pushed down.
            Positioned(
              left: 0,
              right: 0,
              top: depth,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(colors.last, Colors.black, 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: pressed ? depth : 0,
              bottom: pressed ? 0 : depth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: pressed ? [colors.last, colors.last] : colors,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fuel gauge, distance and air time over the scene.
class _Gauges extends StatelessWidget {
  const _Gauges({required this.game});

  final HillRider game;

  @override
  Widget build(BuildContext context) {
    final fuel = game.fuel / game.config.startFuel;
    final fuelColor = Color.lerp(
      const Color(0xFFFF5252),
      const Color(0xFF69F0AE),
      fuel.clamp(0.0, 1.0),
    )!;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_gas_station_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fuel.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: fuelColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 14,
            child: Text(
              '${game.distance} m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),
          if (game.airborne)
            const Align(
              alignment: Alignment(0, -0.6),
              child: Text(
                'AIR!',
                style: TextStyle(
                  color: Color(0xFFFFE066),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ),
          if (game.crashed)
            const Align(
              alignment: Alignment(0, -0.4),
              child: Text(
                'CRASH!',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
            ),
          if (!game.crashed && game.fuel == 0)
            const Align(
              alignment: Alignment(0, -0.4),
              child: Text(
                'OUT OF FUEL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HillPainter extends CustomPainter {
  _HillPainter({
    required this.game,
    required this.clock,
    required this.camY,
    required this.crashedAt,
  }) : super(repaint: clock);

  final HillRider game;
  final TickClock clock;
  final double Function() camY;
  final double? Function() crashedAt;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 520;
    final camX = game.x - 150;
    final cy = camY();
    final baseY = size.height * 0.6;
    double sx(double xu) => (xu - camX) * s;
    double sy(double yu) => baseY - (yu - cy) * s;

    _sky(canvas, size, camX);

    // Terrain, with a darker band below the grass lip for depth.
    final left = camX - 40;
    final right = camX + size.width / s + 40;
    final top = <Offset>[];
    for (var xu = left; xu <= right; xu += 8) {
      top.add(
        Offset(sx(xu), sy(game.heightAt(math.max(0, xu.round())).toDouble())),
      );
    }
    final ground = Path()
      ..addPolygon([
        ...top,
        Offset(sx(right), size.height),
        Offset(sx(left), size.height),
      ], true);
    canvas.drawPath(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
        ).createShader(Offset.zero & size),
    );
    canvas
      ..drawPath(
        Path()..addPolygon([for (final p in top) p + Offset(0, 10 * s)], false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * s
          ..color = const Color(0xFF33691E),
      )
      ..drawPath(
        Path()..addPolygon(top, false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 * s
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF7CB342),
      );

    _markers(canvas, s, left, right, sx, sy);
    _cans(canvas, s, left, right, sx, sy);
    _car(canvas, s, sx, sy);
  }

  void _sky(Canvas canvas, Size size, double camX) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFE1F5FE)],
        ).createShader(rect),
    );
    final sun = Offset(size.width * 0.8, size.height * 0.14);
    canvas.drawCircle(
      sun,
      size.width * 0.07,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Three mountain ranges scrolling at different speeds.
    for (final (speed, lift, amp, color) in const [
      (0.1, 0.42, 0.1, Color(0xFF90A4AE)),
      (0.2, 0.34, 0.08, Color(0xFF78909C)),
      (0.35, 0.26, 0.06, Color(0xFF81C784)),
    ]) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width + 6; x += 6) {
        final w = (x + camX * speed) / size.width;
        path.lineTo(
          x,
          size.height * (1 - lift) -
              (math.sin(w * math.pi * 2.2) * 0.6 +
                      math.sin(w * math.pi * 5.1 + 1) * 0.4) *
                  size.height *
                  amp,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _markers(
    Canvas canvas,
    double s,
    double left,
    double right,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    for (var m = (left / 1000).ceil(); m * 1000 <= right; m++) {
      if (m <= 0) continue;
      final xu = m * 1000.0;
      final base = Offset(sx(xu), sy(game.heightAt(xu.round()).toDouble()));
      canvas.drawLine(
        base,
        base - Offset(0, 60 * s),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3 * s,
      );
      final sign = Rect.fromCenter(
        center: base - Offset(0, 66 * s),
        width: 64 * s,
        height: 24 * s,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(sign, Radius.circular(4 * s)),
        Paint()..color = const Color(0xFFFF7043),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${m * 100} m',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13 * s,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, sign.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// Fuel cans ahead, as little 3D jerry cans.
  void _cans(
    Canvas canvas,
    double s,
    double left,
    double right,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    for (var k = game.nextCan; k < game.nextCan + 3; k++) {
      final xu = game.canX(k).toDouble();
      if (xu < left || xu > right) continue;
      final base = Offset(sx(xu), sy(game.heightAt(xu.round()).toDouble()));
      final body = Rect.fromLTWH(
        base.dx - 12 * s,
        base.dy - 30 * s,
        24 * s,
        30 * s,
      );
      final d = 6 * s;
      canvas
        ..drawPath(
          Path()..addPolygon([
            body.topRight,
            body.topRight + Offset(d, -d),
            body.bottomRight + Offset(d, -d),
            body.bottomRight,
          ], true),
          Paint()..color = const Color(0xFF8E0000),
        )
        ..drawPath(
          Path()..addPolygon([
            body.topLeft,
            body.topLeft + Offset(d, -d),
            body.topRight + Offset(d, -d),
            body.topRight,
          ], true),
          Paint()..color = const Color(0xFFFF8A80),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(body, Radius.circular(3 * s)),
          Paint()..color = const Color(0xFFE53935),
        )
        ..drawRect(
          Rect.fromLTWH(body.left + 4 * s, body.top - 6 * s, 8 * s, 6 * s),
          Paint()..color = const Color(0xFFFFD54F),
        );
    }
  }

  void _car(
    Canvas canvas,
    double s,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final x = game.x;
    double angle;
    if (game.airborne) {
      angle = math.atan2(
        game.verticalSpeed.toDouble(),
        math.max(game.speed, 1).toDouble(),
      );
    } else {
      final rear = game.heightAt(math.max(0, (x - 22).round())).toDouble();
      final front = game.heightAt((x + 22).round()).toDouble();
      angle = math.atan2(front - rear, 44);
    }
    final crashed = crashedAt();
    if (crashed != null) {
      angle += math.min(math.pi, (clock.wallMs - crashed) / 260);
    }

    final pivot = Offset(sx(x), sy(game.y));
    final bob = game.speed.abs() > 10 && !game.airborne
        ? math.sin(clock.wallMs / 70) * 0.8 * s
        : 0.0;
    final wheelTurn = x / 10;

    // Dust behind the rear wheel while driving on the ground.
    if (game.pedal == HillPedal.gas && !game.airborne && game.fuel > 0) {
      for (var k = 0; k < 5; k++) {
        final phase = ((clock.wallMs / 90 + k / 5) % 1);
        canvas.drawCircle(
          pivot + Offset(-32 * s - phase * 30 * s, -4 * s - phase * 14 * s),
          (3 + phase * 5) * s,
          Paint()
            ..color = const Color(
              0xFFD7CCC8,
            ).withValues(alpha: 0.6 * (1 - phase)),
        );
      }
    }

    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy + bob)
      ..rotate(-angle);

    void wheel(double wx) {
      final c = Offset(wx * s, -10 * s);
      canvas
        ..drawCircle(c, 11 * s, Paint()..color = const Color(0xFF212121))
        ..drawCircle(c, 6 * s, Paint()..color = const Color(0xFFB0BEC5));
      for (var k = 0; k < 4; k++) {
        final a = wheelTurn + k * math.pi / 2;
        canvas.drawLine(
          c,
          c + Offset(math.cos(a), math.sin(a)) * 6 * s,
          Paint()
            ..color = const Color(0xFF546E7A)
            ..strokeWidth = 1.5 * s,
        );
      }
    }

    // Chassis with a lit top and a darker side, like a toy car.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(-32 * s, -34 * s, 64 * s, 18 * s),
      Radius.circular(7 * s),
    );
    canvas
      ..drawRRect(
        body.shift(Offset(0, 3 * s)),
        Paint()..color = const Color(0xFF8E1B00),
      )
      ..drawRRect(
        body,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
          ).createShader(body.outerRect),
      )
      // Roll cage and driver.
      ..drawPath(
        Path()
          ..moveTo(-12 * s, -34 * s)
          ..lineTo(-6 * s, -52 * s)
          ..lineTo(12 * s, -52 * s)
          ..lineTo(16 * s, -34 * s),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * s
          ..color = const Color(0xFF37474F),
      )
      ..drawCircle(
        Offset(3 * s, -42 * s),
        7 * s,
        Paint()..color = const Color(0xFFFFD54F),
      )
      ..drawRect(
        Rect.fromLTWH(3 * s, -44 * s, 7 * s, 3 * s),
        Paint()..color = const Color(0xFF263238),
      );
    wheel(-21);
    wheel(21);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HillPainter oldDelegate) => true;
}
