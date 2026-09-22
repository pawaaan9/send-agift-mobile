/// A 32-bit linear congruential generator shared by every game engine.
///
/// Not `dart:math`'s Random: the backend (`internal/games/prng.go`) has to
/// produce the identical number sequence, and no standard generator is
/// specified the same way across two languages. The constants keep every
/// multiplication under 2^53, so this is exact on native and on the web,
/// where int is a double underneath.
class DeterministicRng {
  DeterministicRng(this._state);

  /// Parses the hex seed handed out by the server.
  factory DeterministicRng.fromSeed(String seed) =>
      DeterministicRng(int.parse(seed, radix: 16));

  int _state;

  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;

  /// Advances the generator and returns the new 32-bit state.
  int next() {
    _state = (_state * _multiplier + _increment) & 0xFFFFFFFF;
    return _state;
  }

  /// A value in [0, n).
  int nextInt(int n) => n <= 0 ? 0 : next() % n;
}
