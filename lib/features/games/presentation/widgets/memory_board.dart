import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/memory_match.dart';
import '../game_controls.dart';
import 'tilt_3d.dart';

/// The eight gift faces a Memory Match grid deals from.
const _faces = [
  (Icons.card_giftcard_rounded, Color(0xFFF472B6)),
  (Icons.cake_rounded, Color(0xFFFBBF24)),
  (Icons.local_florist_rounded, Color(0xFF34D399)),
  (Icons.celebration_rounded, Color(0xFF60A5FA)),
  (Icons.coffee_rounded, Color(0xFFA78BFA)),
  (Icons.diamond_rounded, Color(0xFF22D3EE)),
  (Icons.music_note_rounded, Color(0xFFFB7185)),
  (Icons.sports_esports_rounded, Color(0xFFFCD34D)),
];

/// Memory Match: a grid of cards that flip in 3D.
///
/// The flip is a real Y rotation rather than a cross-fade, so the card turns
/// the way a card does — which is also what makes a pair reading as "the same"
/// obvious at a glance.
class MemoryBoard extends StatefulWidget {
  const MemoryBoard({required this.game, required this.controls, super.key});

  final MemoryMatch game;
  final GameControls controls;

  @override
  State<MemoryBoard> createState() => _MemoryBoardState();
}

class _MemoryBoardState extends State<MemoryBoard> {
  /// The pair being looked at before it turns back. Held briefly so a player
  /// actually sees the second card, rather than it vanishing on contact.
  int? _peekA;
  int? _peekB;

  void _tap(int index) {
    if (!widget.controls.active || widget.game.isOver) return;
    final game = widget.game;
    if (game.isMatched(index) || index == _peekA) return;

    // A tap while two wrong cards are showing clears them first.
    if (_peekA != null && _peekB != null) {
      setState(() {
        _peekA = null;
        _peekB = null;
      });
    }

    final first = game.pending;
    final matched = game.flip(index);
    setState(() {
      if (first < 0) {
        _peekA = index;
        _peekB = null;
      } else if (matched) {
        _peekA = null;
        _peekB = null;
      } else {
        _peekA = first;
        _peekB = index;
      }
    });
    widget.controls.onChanged();

    if (!matched && first >= 0) {
      // Let the mismatch sit long enough to memorise, then turn it back.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _peekA = null;
          _peekB = null;
        });
      });
    }
  }

  bool _isUp(int index) =>
      widget.game.isMatched(index) || index == _peekA || index == _peekB;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Center(
      child: Tilt3D(
        angle: 0.16,
        child: AspectRatio(
          aspectRatio: game.config.columns / game.rows,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: game.config.columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: game.cardCount,
            itemBuilder: (context, index) => _Card(
              face: game.faceOf(index),
              up: _isUp(index),
              matched: game.isMatched(index),
              onTap: () => _tap(index),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.face,
    required this.up,
    required this.matched,
    required this.onTap,
  });

  final int face;
  final bool up;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _faces[face % _faces.length];
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: up ? 1 : 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          // Past the halfway point the card has turned edge-on, so the front
          // takes over — the same trick a real flip plays on the eye.
          final showFront = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(t * math.pi),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _Face(icon: icon, color: color, matched: matched),
                  )
                : const _Back(),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 22,
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.icon, required this.color, required this.matched});

  final IconData icon;
  final Color color;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: matched ? 0.92 : 1),
        border: Border.all(
          color: matched ? color : Colors.white.withValues(alpha: 0.6),
          width: matched ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: matched ? 0.5 : 0.25),
            blurRadius: matched ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: Icon(icon, color: color, size: 26)),
    );
  }
}
