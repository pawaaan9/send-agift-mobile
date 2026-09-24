import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/game_engine.dart';
import '../../domain/slide_puzzle.dart';
import '../game_controls.dart';
import 'game_hud.dart';
import 'puzzle_pictures.dart';
import 'tilt_3d.dart';

const double _minSwipeVelocity = 90;

/// The sliding puzzle: a picture cut into tiles, one square short.
///
/// The picture is the player's to choose and is drawn locally — it decides
/// nothing about the puzzle. The scramble comes from the server's seed and
/// the moves are what gets scored, so two players on the same seed solve the
/// identical board whichever picture they picked.
class SlideBoard extends StatefulWidget {
  const SlideBoard({required this.game, required this.controls, super.key});

  final SlidePuzzle game;
  final GameControls controls;

  @override
  State<SlideBoard> createState() => _SlideBoardState();
}

class _SlideBoardState extends State<SlideBoard> {
  /// Null until a picture is chosen, which is what starts the round.
  PuzzlePicture? _picture;

  /// Held down to see the finished picture, the way the lid of a jigsaw box
  /// is. It is only ever a reminder of what you are building.
  bool _peeking = false;

  SlidePuzzle get _game => widget.game;

  void _tap(int index) {
    if (!widget.controls.active) return;
    if (_game.moveTileAt(index)) widget.controls.onChanged();
  }

  /// A swipe names the direction the tile travels, same as the move log.
  void _swipe(String dir) {
    if (!widget.controls.active) return;
    if (_game.move(dir)) widget.controls.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final picture = _picture;
    if (picture == null) {
      return _PicturePicker(
        onPick: (chosen) => setState(() => _picture = chosen),
      );
    }

    final board = _game.board;
    final n = _game.size;
    final total = n * n - 1;
    final solved = _game.solved;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Tilt3D(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: glassDecoration(radius: 26, alpha: 0.2),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 9.0;
                    final cell = (constraints.maxWidth - gap * (n - 1)) / n;
                    // Peeking shows the picture whole, over the tiles.
                    if (_peeking || solved) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CustomPaint(
                          painter: _PicturePainter(picture: picture),
                          size: Size.square(constraints.maxWidth),
                        ),
                      );
                    }
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
                          _positioned(
                            board,
                            n,
                            cell,
                            gap,
                            value,
                            picture,
                            solved,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PeekButton(
            onChanged: (down) => setState(() => _peeking = down),
            peeking: _peeking,
          ),
        ],
      ),
    );
  }

  Widget _positioned(
    List<int> board,
    int n,
    double cell,
    double gap,
    int value,
    PuzzlePicture picture,
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
          size: n,
          picture: picture,
          home: index == value - 1,
          solved: solved,
          extent: cell,
        ),
      ),
    );
  }
}

/// Choose a picture before the first move. The scramble is already dealt —
/// this only decides what is printed on the tiles.
class _PicturePicker extends StatelessWidget {
  const _PicturePicker({required this.onPick});

  final ValueChanged<PuzzlePicture> onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pick your picture',
              style: AppTypography.display(24, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Slide the tiles back into it in as few moves as you can.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                // Two across, so each thumbnail is big enough to tell what it
                // is before committing to solving it.
                final tile =
                    (constraints.maxWidth.clamp(240.0, 460.0) - 14) / 2;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final picture in puzzlePictures)
                      _PictureChoice(
                        picture: picture,
                        extent: tile,
                        onTap: () => onPick(picture),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PictureChoice extends StatelessWidget {
  const _PictureChoice({
    required this.picture,
    required this.extent,
    required this.onTap,
  });

  final PuzzlePicture picture;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: picture.name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: extent,
              height: extent,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: picture.colors.last.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _PicturePainter(picture: picture),
                  size: Size.square(extent),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              picture.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hold to see the finished picture, like the lid of a jigsaw box.
class _PeekButton extends StatelessWidget {
  const _PeekButton({required this.onChanged, required this.peeking});

  final ValueChanged<bool> onChanged;
  final bool peeking;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onChanged(true),
      onPointerUp: (_) => onChanged(false),
      onPointerCancel: (_) => onChanged(false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: glassDecoration(radius: 22, alpha: peeking ? 0.3 : 0.16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              peeking ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Hold to see the picture',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a whole picture into the space it is given.
class _PicturePainter extends CustomPainter {
  _PicturePainter({required this.picture});

  final PuzzlePicture picture;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    picture.paint(canvas, side);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PicturePainter old) => old.picture != picture;
}

/// Paints one tile's share of the picture: the whole thing, shifted so the
/// slice belonging to this tile lands inside it.
class _TilePainter extends CustomPainter {
  _TilePainter({
    required this.picture,
    required this.size,
    required this.value,
  });

  final PuzzlePicture picture;

  /// The board's width in tiles.
  final int size;

  /// 1-based tile number, which is also its home square.
  final int value;

  @override
  void paint(Canvas canvas, Size box) {
    final whole = box.width * size;
    final home = value - 1;
    canvas.save();
    canvas.clipRect(Offset.zero & box);
    canvas.translate(-(home % size) * box.width, -(home ~/ size) * box.height);
    picture.paint(canvas, whole);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TilePainter old) =>
      old.picture != picture || old.value != value || old.size != size;
}

class _SlideTile extends StatelessWidget {
  const _SlideTile({
    required this.value,
    required this.size,
    required this.picture,
    required this.home,
    required this.solved,
    required this.extent,
  });

  final int value;
  final int size;
  final PuzzlePicture picture;
  final bool home;
  final bool solved;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          // A tile already home is outlined, which is the only cue a picture
          // puzzle gives that a piece is in the right place.
          color: home
              ? const Color(0xFF34D399)
              : Colors.white.withValues(alpha: 0.35),
          width: home ? 2.5 : 1,
        ),
        boxShadow: [
          // Solid side slab: the tile stands up off the board.
          BoxShadow(
            color: const Color(0xFF0B1020).withValues(alpha: 0.55),
            offset: Offset(0, extent * 0.07),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: solved ? 22 : 12,
            offset: Offset(0, extent * 0.12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _TilePainter(picture: picture, size: size, value: value),
            ),
            // A glossy highlight, so a tile reads as a raised piece rather
            // than a hole cut in the picture.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.2),
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            // The number, small and in the corner: enough to work out where a
            // piece belongs without covering the picture it carries.
            Positioned(
              left: extent * 0.07,
              top: extent * 0.05,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: extent * 0.07,
                  vertical: extent * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(extent * 0.1),
                ),
                child: Text(
                  '$value',
                  style: AppTypography.display(
                    extent * 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
