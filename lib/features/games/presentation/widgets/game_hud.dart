import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../game_controls.dart';

/// Frosted-glass surface used by the in-game controls.
///
/// Smoked rather than clear: these panels float over whatever the game is
/// painting, and a pale sky or a lit court left white-on-white text with
/// nothing behind it. A dark fill with a light rim reads on a bright
/// backdrop and a dark one alike.
BoxDecoration glassDecoration({double radius = 18, double alpha = 0.16}) {
  return BoxDecoration(
    color: const Color(0xFF0A1420).withValues(alpha: 0.32 + alpha),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Round frosted button, e.g. the game-menu button.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 46,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: size,
            height: size,
            decoration: glassDecoration(radius: size / 2, alpha: 0.2),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Menu button, game name, and the player's best.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    required this.title,
    required this.icon,
    required this.onMenu,
    this.best,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onMenu;
  final int? best;

  @override
  Widget build(BuildContext context) {
    final best = this.best;
    return Row(
      children: [
        GlassIconButton(
          icon: Icons.pause_rounded,
          tooltip: 'Game menu',
          onPressed: onMenu,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(22, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        if (best != null && best > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: glassDecoration(radius: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFE066),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$best',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(width: 46),
      ],
    );
  }
}

class GameStatsRow extends StatelessWidget {
  const GameStatsRow({required this.stats, super.key});

  final List<GameStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: GameStatChip(stat: stats[i])),
        ],
      ],
    );
  }
}

/// One stat. The number counts up to its new value and gives a small bump
/// whenever it changes, so progress feels alive.
class GameStatChip extends StatelessWidget {
  const GameStatChip({required this.stat, super.key});

  final GameStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.eyebrow.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            key: ValueKey(stat.value),
            tween: Tween(begin: 1.14, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              alignment: Alignment.centerLeft,
              child: child,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: stat.value.toDouble()),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              builder: (context, value, _) => Text(
                '${value.round()}',
                maxLines: 1,
                style: AppTypography.display(22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
