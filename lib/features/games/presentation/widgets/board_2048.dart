import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// The 2048 grid.
///
/// Purely a view of [board] — it holds no game state of its own, so what is
/// drawn is always exactly what the engine (and therefore the server) thinks
/// the position is.
class Board2048 extends StatelessWidget {
  const Board2048({required this.board, required this.size, super.key});

  /// Flat, row-major: `board[row * size + col]`.
  final List<int> board;
  final int size;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final cell = (constraints.maxWidth - gap * (size - 1)) / size;

            return Stack(
              children: [
                for (var i = 0; i < board.length; i++)
                  Positioned(
                    left: (i % size) * (cell + gap),
                    top: (i ~/ size) * (cell + gap),
                    width: cell,
                    height: cell,
                    child: _Tile(value: board[i], extent: cell),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.extent});

  final int value;
  final double extent;

  /// Warm ramp from the brand cream up to the teal accent, so bigger tiles
  /// read as more valuable at a glance.
  static const Map<int, Color> _fills = {
    0: AppColors.muted,
    2: AppColors.cream,
    4: Color(0xFFE6DEFB),
    8: Color(0xFFCDBFF6),
    16: Color(0xFFB39DF1),
    32: Color(0xFF9B7BEC),
    64: AppColors.purple,
    128: Color(0xFF4FC7C2),
    256: Color(0xFF2EB9B4),
    512: AppColors.teal,
    1024: Color(0xFF0E9C97),
    2048: Color(0xFF0B6E68),
  };

  Color get _fill => _fills[value] ?? const Color(0xFF07514D);

  Color get _textColor {
    if (value == 0) return Colors.transparent;
    // Light tiles keep dark text; the saturated ones flip to white.
    return value >= 64 ? Colors.white : AppColors.foreground;
  }

  /// Longer numbers need to shrink to keep fitting the tile.
  double get _fontSize {
    final base = extent * 0.38;
    if (value >= 1024) return base * 0.62;
    if (value >= 128) return base * 0.76;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? null
          : FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$value',
                  style: AppTypography.display(_fontSize, color: _textColor),
                ),
              ),
            ),
    );
  }
}
