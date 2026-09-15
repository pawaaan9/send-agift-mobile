import 'package:flutter/foundation.dart';

/// What a board widget gets from the shared game screen.
class GameControls {
  const GameControls({required this.active, required this.onChanged});

  /// False while paused, submitting, or finished. Boards ignore input and
  /// stop any clock of their own when this is false.
  final bool active;

  /// Call after changing the engine so the screen redraws its stats and
  /// notices when the round is over.
  final VoidCallback onChanged;
}

/// One number in the stats strip above the board.
class GameStat {
  const GameStat(this.label, this.value);

  final String label;
  final int value;
}
