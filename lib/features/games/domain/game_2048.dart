/// The deterministic 2048 engine.
///
/// This file is a line-for-line mirror of `internal/games/game2048.go` on the
/// backend. When a game ends the app sends only the moves that were played;
/// the server replays them from the same seed and computes the score itself.
/// If these two implementations ever drift apart, honest players get their
/// scores flagged — so any change here must be made on both sides, behind a
/// new game version.
library;

import 'deterministic_rng.dart';
import 'game_engine.dart';

export 'deterministic_rng.dart';
export 'game_engine.dart';

/// The rules the server enforces and this engine runs. Delivered with every
/// session so the two never disagree about how a game is played.
class GameConfig2048 {
  const GameConfig2048({
    this.boardSize = 4,
    this.startTiles = 2,
    this.spawnFourPercent = 10,
    this.winTile = 2048,
    this.maxMoves = 5000,
  });

  factory GameConfig2048.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback) {
      final value = json[key];
      return value is num && value > 0 ? value.toInt() : fallback;
    }

    const defaults = GameConfig2048();
    return GameConfig2048(
      boardSize: read('board_size', defaults.boardSize),
      startTiles: read('start_tiles', defaults.startTiles),
      spawnFourPercent: read('spawn_four_percent', defaults.spawnFourPercent),
      winTile: read('win_tile', defaults.winTile),
      maxMoves: read('max_moves', defaults.maxMoves),
    );
  }

  final int boardSize;
  final int startTiles;
  final int spawnFourPercent;
  final int winTile;
  final int maxMoves;
}

/// A 2048 game driven entirely by a server-issued seed.
class Game2048 implements GameEngine {
  Game2048({required String seed, GameConfig2048? config})
    : config = config ?? const GameConfig2048(),
      _rng = DeterministicRng.fromSeed(seed) {
    _board = List<int>.filled(this.config.boardSize * this.config.boardSize, 0);
    for (var i = 0; i < this.config.startTiles; i++) {
      _spawn();
    }
  }

  final GameConfig2048 config;
  final DeterministicRng _rng;

  late List<int> _board;
  int _score = 0;

  /// Every move that changed the board, in order. This is what gets
  /// submitted — the server derives the score from it.
  final List<String> _moves = <String>[];

  /// The flat, row-major board: `board[row * size + col]`.
  List<int> get board => List<int>.unmodifiable(_board);

  @override
  int get score => _score;

  @override
  List<String> get moves => List<String>.unmodifiable(_moves);

  @override
  bool get isOver => isGameOver || reachedMoveLimit;

  @override
  bool get hasProgress => _moves.isNotEmpty;

  int get size => config.boardSize;

  int get highestTile => _board.fold(0, (best, v) => v > best ? v : best);

  bool get won => highestTile >= config.winTile;

  /// True while a legal move remains: an empty cell, or two equal neighbours.
  bool get hasMoves {
    for (var i = 0; i < _board.length; i++) {
      final v = _board[i];
      if (v == 0) return true;
      final row = i ~/ size;
      final col = i % size;
      if (col + 1 < size && _board[i + 1] == v) return true;
      if (row + 1 < size && _board[i + size] == v) return true;
    }
    return false;
  }

  bool get isGameOver => !hasMoves;

  /// Whether the move budget is spent; submitting more would be rejected.
  bool get reachedMoveLimit => _moves.length >= config.maxMoves;

  /// Places one tile on a random empty cell.
  ///
  /// The position is drawn FIRST and the value second. Swapping those two
  /// lines desyncs this engine from the server's.
  void _spawn() {
    final empties = <int>[];
    for (var i = 0; i < _board.length; i++) {
      if (_board[i] == 0) empties.add(i);
    }
    if (empties.isEmpty) return;

    final cell = empties[_rng.nextInt(empties.length)];
    final value = _rng.nextInt(100) < config.spawnFourPercent ? 4 : 2;
    _board[cell] = value;
  }

  /// Reads one row or column in the direction of travel, so all four
  /// directions reuse the same "slide towards index 0" logic.
  List<int> _line(String dir, int index) {
    final out = List<int>.filled(size, 0);
    for (var i = 0; i < size; i++) {
      switch (dir) {
        case Move.left:
          out[i] = _board[index * size + i];
        case Move.right:
          out[i] = _board[index * size + (size - 1 - i)];
        case Move.up:
          out[i] = _board[i * size + index];
        case Move.down:
          out[i] = _board[(size - 1 - i) * size + index];
      }
    }
    return out;
  }

  void _writeLine(String dir, int index, List<int> values) {
    for (var i = 0; i < size; i++) {
      switch (dir) {
        case Move.left:
          _board[index * size + i] = values[i];
        case Move.right:
          _board[index * size + (size - 1 - i)] = values[i];
        case Move.up:
          _board[i * size + index] = values[i];
        case Move.down:
          _board[(size - 1 - i) * size + index] = values[i];
      }
    }
  }

  /// Slides one line towards index 0 and merges equal neighbours. A tile may
  /// merge at most once per move, resolved from the leading edge inwards.
  List<int> _collapse(List<int> input) {
    final packed = <int>[];
    for (final v in input) {
      if (v != 0) packed.add(v);
    }

    final merged = <int>[];
    for (var i = 0; i < packed.length; i++) {
      if (i + 1 < packed.length && packed[i] == packed[i + 1]) {
        final sum = packed[i] * 2;
        merged.add(sum);
        _score += sum;
        i++; // the consumed neighbour cannot merge again this move
        continue;
      }
      merged.add(packed[i]);
    }

    while (merged.length < input.length) {
      merged.add(0);
    }
    return merged;
  }

  /// Applies one swipe. Returns whether the board changed.
  ///
  /// A new tile appears only when something actually moved, which is what
  /// keeps this engine's random stream aligned with the server's.
  bool move(String dir) {
    if (isOver || !Move.isDirection(dir)) return false;

    var changed = false;
    for (var i = 0; i < size; i++) {
      final before = _line(dir, i);
      final after = _collapse(before);
      for (var j = 0; j < before.length; j++) {
        if (before[j] != after[j]) {
          changed = true;
          break;
        }
      }
      _writeLine(dir, i, after);
    }

    if (changed) {
      _spawn();
      // Only record moves that did something. A no-op move would replay as a
      // no-op on the server too, so sending it just adds noise to the log.
      _moves.add(dir);
    }
    return changed;
  }
}
