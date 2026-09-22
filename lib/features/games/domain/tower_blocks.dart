import 'deterministic_rng.dart';
import 'game_engine.dart';

/// Tower Blocks rules, read from the config the server issues.
class TowerBlocksConfig {
  const TowerBlocksConfig({
    this.columns = 6,
    this.rows = 12,
    this.maxWidth = 3,
    this.pointsPerPiece = 4,
    this.pointsPerRow = 40,
    this.multiRowBonus = 30,
    this.maxPieces = 300,
  });

  final int columns;
  final int rows;
  final int maxWidth;
  final int pointsPerPiece;
  final int pointsPerRow;
  final int multiRowBonus;
  final int maxPieces;

  factory TowerBlocksConfig.fromJson(Map<String, dynamic> json) {
    const d = TowerBlocksConfig();
    int pick(String key, int fallback) {
      final value = readConfigInt(json, key);
      return value > 0 ? value : fallback;
    }

    final columns = pick('columns', d.columns);
    var maxWidth = pick('max_width', d.maxWidth);
    if (maxWidth > columns) maxWidth = columns;
    return TowerBlocksConfig(
      columns: columns,
      rows: pick('rows', d.rows),
      maxWidth: maxWidth,
      pointsPerPiece: pick('points_per_piece', d.pointsPerPiece),
      pointsPerRow: pick('points_per_row', d.pointsPerRow),
      multiRowBonus: pick('multi_row_bonus', d.multiRowBonus),
      maxPieces: pick('max_pieces', d.maxPieces),
    );
  }
}

/// Tower Blocks: slabs of one to three cells drop into a well and the player
/// picks the column. A slab rests on the tallest column it spans, so an uneven
/// stack wastes the space underneath; a full row clears and pulls the rest
/// down. Stacking past the top ends the round.
///
/// Mirrors `internal/games/towerblocks.go` exactly.
class TowerBlocks implements GameEngine {
  TowerBlocks({required String seed, required this.config})
    : _rng = DeterministicRng.fromSeed(seed) {
    _grid = List.generate(
      config.rows,
      (_) => List<bool>.filled(config.columns, false),
    );
    _width = _rng.nextInt(config.maxWidth) + 1;
  }

  final TowerBlocksConfig config;
  final DeterministicRng _rng;
  late final List<List<bool>> _grid;
  final List<String> _moves = [];

  int _width = 1;
  int _pieces = 0;
  int _rows = 0;
  int _bestCombo = 0;
  int _score = 0;
  bool _over = false;

  /// The width of the slab waiting to drop.
  int get width => _width;
  int get rowsCleared => _rows;
  int get pieces => _pieces;
  int get bestCombo => _bestCombo;

  /// Whether a cell holds part of a slab.
  bool filled(int row, int col) {
    if (row < 0 || row >= config.rows || col < 0 || col >= config.columns) {
      return false;
    }
    return _grid[row][col];
  }

  /// The rightmost column the queued slab can start at.
  int get maxColumn => config.columns - _width;

  int _height(int col) {
    for (var r = config.rows - 1; r >= 0; r--) {
      if (_grid[r][col]) return r + 1;
    }
    return 0;
  }

  /// The row the queued slab would land on from a starting column.
  int restRow(int col) {
    var rest = 0;
    for (var c = col; c < col + _width; c++) {
      if (c < 0 || c >= config.columns) continue;
      final h = _height(c);
      if (h > rest) rest = h;
    }
    return rest;
  }

  @override
  int get score => _score;

  @override
  List<String> get moves => List.unmodifiable(_moves);

  @override
  bool get isOver => _over || _pieces >= config.maxPieces;

  @override
  bool get hasProgress => _moves.isNotEmpty;

  /// Drops the queued slab with its left edge at [col]. Returns rows cleared.
  int drop(int col) {
    if (isOver || col < 0 || col > maxColumn) return 0;

    final row = restRow(col);
    _moves.add('$col');
    _pieces++;
    if (row >= config.rows) {
      _over = true;
      return 0;
    }
    for (var c = col; c < col + _width; c++) {
      _grid[row][c] = true;
    }
    _score += config.pointsPerPiece;

    final cleared = _clearRows();
    if (cleared > 0) {
      _rows += cleared;
      if (cleared > _bestCombo) _bestCombo = cleared;
      _score += cleared * config.pointsPerRow +
          config.multiRowBonus * (cleared - 1);
    }

    if (_height(0) >= config.rows) _over = true;
    _width = _rng.nextInt(config.maxWidth) + 1;
    return cleared;
  }

  int _clearRows() {
    var cleared = 0;
    var r = 0;
    while (r < config.rows) {
      var full = true;
      for (var c = 0; c < config.columns; c++) {
        if (!_grid[r][c]) {
          full = false;
          break;
        }
      }
      if (!full) {
        r++;
        continue;
      }
      for (var up = r; up < config.rows - 1; up++) {
        _grid[up] = List<bool>.from(_grid[up + 1]);
      }
      _grid[config.rows - 1] = List<bool>.filled(config.columns, false);
      cleared++;
      // Do not advance r: what fell into this row may also be full.
    }
    return cleared;
  }
}
