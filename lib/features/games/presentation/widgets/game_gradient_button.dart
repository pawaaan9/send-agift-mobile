import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The big call-to-action on game screens, painted in the game's colours.
/// Greys out when [onPressed] is null.
class GameGradientButton extends StatelessWidget {
  const GameGradientButton({
    required this.label,
    required this.colors,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    super.key,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled ? Colors.white : AppColors.mutedForeground;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled ? LinearGradient(colors: colors) : null,
            color: enabled ? null : AppColors.muted,
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
