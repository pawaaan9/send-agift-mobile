import 'deterministic_rng.dart';
import 'game_engine.dart';

/// Fruit Slice rules, read from the config the server issues.
class FruitConfig {
  const FruitConfig({
    this.tickMs = 20,
    this.lanes = 5,
    this.throws = 48,
    this.startFlightTicks = 60,
    this.minFlightTicks = 24,
    this.flightStepTicks = 1,
    this.gapTicks = 14,
    this.bombEveryThrows = 7,
    this.pointsPerFruit = 12,
    this.comboBonus = 6,
  });

  final int tickMs;
  final int lanes;
  final int throws;
  final int startFlightTicks;
  final int minFlightTicks;
  final int flightStepTicks;
  final int gapTicks;
  final int bombEveryThrows;
  final int pointsPerFruit;
  final int comboBonus;

  factory FruitConfig.fromJson(Map<String, dynamic> json) {
    const d = FruitConfig();
    int pick(String key, int fallback) {
      final value = readConfigInt(json, key);
      return value > 0 ? value : fallback;
    }

    return FruitConfig(
      tickMs: pick('tick_ms', d.tickMs),
      lanes: pick('lanes', d.lanes),
      throws: pick('throws', d.throws),
      startFlightTicks: pick('start_flight_ticks', d.startFlightTicks),
      minFlightTicks: pick('min_flight_ticks', d.minFlightTicks),
      flightStepTicks: pick('flight_step_ticks', d.flightStepTicks),
      gapTicks: pick('gap_ticks', d.gapTicks),
      bombEveryThrows: pick('bomb_every_throws', d.bombEveryThrows),
      pointsPerFruit: pick('points_per_fruit', d.pointsPerFruit),
      comboBonus: pick('combo_bonus', d.comboBonus),
    );
  }
}

/// One item in the air: its lane, the window it can be cut in, and whether
/// cutting it ends the round.
class FruitThrow {
  const FruitThrow({
    required this.lane,
    required this.enter,
    required this.exit,
    required this.bomb,
    required this.kind,
  });

  final int lane;
  final int enter;
  final int exit;
  final bool bomb;
  final int kind;
}

/// Fruit Slice: gifts arc up through numbered lanes and the player swipes to
/// cut them, with flights shortening as the round goes on. A run pays a
/// growing bonus; catching a bomb ends it — so it is about what you leave
/// alone as much as what you cut.
///
/// Mirrors `internal/games/fruitslice.go` exactly.
class FruitSlice implements TickGame {
  FruitSlice({required String seed, required this.config})
    : throws = _schedule(seed, config) {
    _cut = List<bool>.filled(throws.length, false);
  }

  final FruitConfig config;
  final List<FruitThrow> throws;
  late final List<bool> _cut;
  final List<String> _moves = [];

  int _tick = 0;
  int _sliced = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _score = 0;
  bool _over = false;

  static List<FruitThrow> _schedule(String seed, FruitConfig config) {
    final rng = DeterministicRng.fromSeed(seed);
    final out = <FruitThrow>[];
    var tick = config.gapTicks;
    for (var i = 0; i < config.throws; i++) {
      var flight = config.startFlightTicks - config.flightStepTicks * i;
      if (flight < config.minFlightTicks) flight = config.minFlightTicks;
      final lane = rng.nextInt(config.lanes);
      final kind = rng.nextInt(4);
      final bomb = i > 0 && i % config.bombEveryThrows == 0;
      out.add(
        FruitThrow(
          lane: lane,
          enter: tick,
          exit: tick + flight,
          bomb: bomb,
          kind: kind,
        ),
      );
      tick = tick + flight + config.gapTicks + rng.nextInt(config.gapTicks);
    }
    return out;
  }

  int get sliced => _sliced;
  int get bestStreak => _bestStreak;

  /// When the final throw lands — the length of the whole round.
  int get lastTick => throws.isEmpty ? 0 : throws.last.exit;

  /// Whether a throw has already been cut.
  bool wasCut(int index) => index >= 0 && index < _cut.length && _cut[index];

  /// The throws currently in the air, for the board to draw.
  List<int> get airborne {
    final out = <int>[];
    for (var i = 0; i < throws.length; i++) {
      final t = throws[i];
      if (t.enter > _tick) break;
      if (_tick >= t.enter && _tick < t.exit && !_cut[i]) out.add(i);
    }
    return out;
  }

  /// The index of the throw in a lane at a tick, or -1 when the lane is empty.
  int throwAt(int tick, int lane) {
    for (var i = 0; i < throws.length; i++) {
      final t = throws[i];
      if (t.enter > tick) break;
      if (t.lane == lane && tick >= t.enter && tick < t.exit) return i;
    }
    return -1;
  }

  @override
  int get tickMs => config.tickMs;

  @override
  int get tick => _tick;

  @override
  int get score => _score;

  @override
  List<String> get moves => List.unmodifiable(_moves);

  @override
  bool get isOver => _over || _tick >= lastTick;

  @override
  bool get hasProgress => _moves.isNotEmpty;

  @override
  void advance() {
    if (!isOver) _tick++;
  }

  /// Swipes a lane at the current tick. Returns true when it cut a fruit.
  bool slice(int lane) {
    if (isOver || lane < 0 || lane >= config.lanes) return false;
    _moves.add('$_tick:$lane');

    final index = throwAt(_tick, lane);
    if (index < 0 || _cut[index]) {
      _streak = 0;
      return false;
    }

    _cut[index] = true;
    if (throws[index].bomb) {
      _over = true;
      _streak = 0;
      return false;
    }

    _sliced++;
    _streak++;
    if (_streak > _bestStreak) _bestStreak = _streak;
    _score += config.pointsPerFruit + config.comboBonus * (_streak - 1);
    return true;
  }
}
