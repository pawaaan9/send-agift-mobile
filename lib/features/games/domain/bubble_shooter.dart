import 'deterministic_rng.dart';
import 'game_engine.dart';

/// Bubble Shooter rules, read from the config the server issues.
class BubbleConfig {
  const BubbleConfig({
    this.columns = 7,
    this.rows = 11,
    this.startRows = 4,
    this.colors = 4,
    this.minCluster = 3,
    this.pointsPerBubble = 10,
    this.comboBonus = 5,
    this.maxShots = 200,
  });

  final int columns;
  final int rows;
  final int startRows;
  final int colors;
  final int minCluster;
  final int pointsPerBubble;
  final int comboBonus;
  final int maxShots;

  factory BubbleConfig.fromJson(Map<String, dynamic> json) {
    const d = BubbleConfig();
    int pick(String key, int fallback) {
      final value = readConfigInt(json, key);
      return value > 0 ? value : fallback;
    }

    final rows = pick('rows', d.rows);
    var startRows = pick('start_rows', d.startRows);
    if (startRows >= rows) startRows = rows - 1;
    return BubbleConfig(
      columns: pick('columns', d.columns),
      rows: rows,
      startRows: startRows,
      colors: pick('colors', d.colors),
      minCluster: pick('min_cluster', d.minCluster),
      pointsPerBubble: pick('points_per_bubble', d.pointsPerBubble),
      comboBonus: pick('combo_bonus', d.comboBonus),
      maxShots: pick('max_shots', d.maxShots),
    );
  }
}

/// Bubble Shooter: fire the queued colour up a column, where it sticks under
/// the wall. Landing it against enough of its own colour pops the cluster, and
/// anything left unsupported falls with it — which is where the chains come
/// from. The skill is reading where the colour already sits.
///
/// Mirrors `internal/games/bubble.go` exactly.
class BubbleShooter implements GameEngine {
  BubbleShooter({required String seed, required this.config})
    : _rng = DeterministicRng.fromSeed(seed) {
    _grid = List.generate(
      config.rows,
      (_) => List<int>.filled(config.columns, -1),
    );
    for (var r = 0; r < config.startRows; r++) {
      for (var c = 0; c < config.columns; c++) {
        _grid[r][c] = _rng.nextInt(config.colors);
      }
    }
    _next = _rng.nextInt(config.colors);
  }

  final BubbleConfig config;
  final DeterministicRng _rng;
  late final List<List<int>> _grid;
  final List<String> _moves = [];

  int _next = 0;
  int _shots = 0;
  int _pops = 0;
  int _bestCombo = 0;
  int _score = 0;
  bool _over = false;

  /// The colour waiting to be fired.
  int get next => _next;
  int get pops => _pops;
  int get shots => _shots;
  int get bestCombo => _bestCombo;

  /// The colour in a cell, or -1 when empty.
  int at(int row, int col) {
    if (row < 0 || row >= config.rows || col < 0 || col >= config.columns) {
      return -1;
    }
    return _grid[row][col];
  }

  /// Where a shot up a column would come to rest.
  int landingRow(int col) {
    for (var r = config.rows - 1; r >= 0; r--) {
      if (_grid[r][col] >= 0) return r + 1;
    }
    return 0;
  }

  @override
  int get score => _score;

  @override
  List<String> get moves => List.unmodifiable(_moves);

  @override
  bool get isOver => _over || _shots >= config.maxShots;

  @override
  bool get hasProgress => _moves.isNotEmpty;

  /// Fires the queued colour up a column. Returns how many bubbles popped.
  int shoot(int col) {
    if (isOver || col < 0 || col >= config.columns) return 0;

    final row = landingRow(col);
    _moves.add('$col');
    _shots++;
    if (row >= config.rows) {
      _over = true;
      return 0;
    }

    _grid[row][col] = _next;

    var popped = 0;
    final group = _cluster(row, col);
    if (group.length >= config.minCluster) {
      for (final cell in group) {
        _grid[cell[0]][cell[1]] = -1;
      }
      popped = group.length + _dropFloaters();
      _pops += popped;
      final combo = popped ~/ config.minCluster;
      if (combo > _bestCombo) _bestCombo = combo;
      _score += popped * config.pointsPerBubble + config.comboBonus * combo;
    }

    if (landingRow(col) >= config.rows) _over = true;
    _next = _rng.nextInt(config.colors);
    return popped;
  }

  /// Every cell of one colour reachable from a starting cell.
  List<List<int>> _cluster(int row, int col) {
    final color = at(row, col);
    if (color < 0) return const [];
    final seen = <String>{'$row,$col'};
    final queue = <List<int>>[
      [row, col],
    ];
    final out = <List<int>>[
      [row, col],
    ];
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final step in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final nr = cell[0] + step[0];
        final nc = cell[1] + step[1];
        final key = '$nr,$nc';
        if (seen.contains(key) || at(nr, nc) != color) continue;
        seen.add(key);
        queue.add([nr, nc]);
        out.add([nr, nc]);
      }
    }
    return out;
  }

  /// Clears anything no longer hanging from the ceiling, which is what turns
  /// a pop into a cascade instead of leaving islands.
  int _dropFloaters() {
    final attached = List.generate(
      config.rows,
      (_) => List<bool>.filled(config.columns, false),
    );
    final queue = <List<int>>[];
    for (var c = 0; c < config.columns; c++) {
      if (_grid[0][c] >= 0) {
        attached[0][c] = true;
        queue.add([0, c]);
      }
    }
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final step in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final nr = cell[0] + step[0];
        final nc = cell[1] + step[1];
        if (nr < 0 || nr >= config.rows || nc < 0 || nc >= config.columns) {
          continue;
        }
        if (attached[nr][nc] || _grid[nr][nc] < 0) continue;
        attached[nr][nc] = true;
        queue.add([nr, nc]);
      }
    }

    var dropped = 0;
    for (var r = 0; r < config.rows; r++) {
      for (var c = 0; c < config.columns; c++) {
        if (_grid[r][c] >= 0 && !attached[r][c]) {
          _grid[r][c] = -1;
          dropped++;
        }
      }
    }
    return dropped;
  }
}
