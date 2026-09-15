import 'package:flutter/material.dart';

/// Each game's look: its colours, icon and short copy.
///
/// Kept on the client because it is presentation only — the rules themselves
/// come from the server with every session.
class GameVisual {
  const GameVisual({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.colors,
    required this.accent,
    required this.hint,
    required this.howToPlay,
  });

  final String name;
  final String tagline;
  final IconData icon;

  /// Three-stop background gradient.
  final List<Color> colors;
  final Color accent;

  /// One-line reminder under the board.
  final String hint;
  final List<String> howToPlay;

  static GameVisual of(String slug) => _visuals[slug] ?? _fallback;

  /// Friendly names for the per-game stats the server returns.
  static String statLabel(String key) => switch (key) {
    'highest_tile' => 'Best tile',
    'length' => 'Length',
    'food' => 'Gifts',
    'ticks' => 'Ticks',
    'moves' => 'Moves',
    'tiles_in_place' => 'Tiles home',
    'makes' => 'Baskets',
    'shots' => 'Shots',
    'swishes' => 'Swishes',
    'best_streak' => 'Best streak',
    'floors' => 'Floors',
    'perfects' => 'Perfects',
    'arrows' => 'Arrows',
    'tens' => 'Tens',
    'xs' => 'Bullseyes',
    'fours' => 'Fours',
    'sixes' => 'Sixes',
    'wickets' => 'Wickets',
    'lines' => 'Lines',
    'best_combo' => 'Best combo',
    'placed' => 'Pieces',
    'levels' => 'Levels',
    'targets' => 'Targets',
    'distance' => 'Metres',
    'air_ticks' => 'Air time',
    'fuel_cans' => 'Fuel cans',
    _ => key.replaceAll('_', ' '),
  };
}

const Map<String, GameVisual> _visuals = {
  '2048': GameVisual(
    name: '2048',
    tagline: 'Merge the tiles and chase the big number.',
    icon: Icons.grid_view_rounded,
    colors: [Color(0xFFFF5F6D), Color(0xFFFF8E53), Color(0xFFFFC371)],
    accent: Color(0xFFFF5F6D),
    hint: 'Swipe to slide every tile. Equal tiles merge.',
    howToPlay: [
      'Swipe in any direction to slide every tile.',
      'Two equal tiles merge into one — their sum is your points.',
      'The round ends when the board is full and nothing can merge.',
    ],
  ),
  'snake': GameVisual(
    name: 'Snake',
    tagline: 'Grab the gift boxes, grow long, never crash.',
    icon: Icons.timeline_rounded,
    colors: [Color(0xFF052E26), Color(0xFF0B8F72), Color(0xFF38EF7D)],
    accent: Color(0xFF38EF7D),
    hint: 'Swipe or use the arrows. Every gift speeds you up.',
    howToPlay: [
      'Swipe or tap the arrows to steer.',
      'Each gift box is 10 points and makes you longer — and faster.',
      'Hitting a wall or your own tail ends the round.',
    ],
  ),
  'basketball': GameVisual(
    name: 'Basketball',
    tagline: 'Shoot hoops against the clock. Swish for bonus points.',
    icon: Icons.sports_basketball_rounded,
    colors: [Color(0xFF1A0B3B), Color(0xFFE8590C), Color(0xFFFFB347)],
    accent: Color(0xFFE8590C),
    hint: 'Swipe up from the ball. Lead the hoop once it moves.',
    howToPlay: [
      'Swipe up from the ball — sideways aims, the length sets the power.',
      'Farther spots need more power; the green band on the meter is the '
          'sweet spot.',
      'Three baskets in a row and you are on fire: every basket counts '
          'double.',
      'Every few baskets the hoop starts moving — aim where it will be.',
    ],
  ),
  'stack-tower': GameVisual(
    name: 'Stack Tower',
    tagline: 'Drop each floor right on top. Perfect drops grow it back.',
    icon: Icons.layers_rounded,
    colors: [Color(0xFF0F2027), Color(0xFF2C5364), Color(0xFF00C9A7)],
    accent: Color(0xFF00C9A7),
    hint: 'Tap anywhere to drop the sliding floor.',
    howToPlay: [
      'Tap to drop the sliding floor onto the tower.',
      'Anything hanging over the edge is sliced off.',
      'Land it dead centre for a perfect: full width and bonus points.',
      'Miss the tower completely and it is game over.',
    ],
  ),
  'archery': GameVisual(
    name: 'Archery',
    tagline: 'Read the wind, steady your aim, hit the gold.',
    icon: Icons.gps_fixed_rounded,
    colors: [Color(0xFF134E5E), Color(0xFF2E8B57), Color(0xFFA8E063)],
    accent: Color(0xFF2E8B57),
    hint: 'Drag to aim, let go to shoot. Mind the wind.',
    howToPlay: [
      'Drag to move your sight, let go to loose the arrow.',
      'The sight sways — release when it is steady on the gold.',
      'The windsock and the wind chip show how hard it is blowing; aim '
          'into it.',
      'Ten arrows. The gold scores 10, down to 1 on the outer ring.',
    ],
  ),
  'cricket': GameVisual(
    name: 'Cricket',
    tagline: 'Time your swing, find the gaps, clear the rope.',
    icon: Icons.sports_cricket_rounded,
    colors: [Color(0xFF0B3D1F), Color(0xFF1B7A3A), Color(0xFF8BD450)],
    accent: Color(0xFF1B7A3A),
    hint: 'Tap to swing. Tap left or right of the batter to aim.',
    howToPlay: [
      'Tap as the ball reaches the bat — perfect timing clears the rope.',
      'Where you tap aims the shot. Red on the ring means a fielder is '
          'there; green is a gap.',
      'Miss a ball on the stumps and you are bowled. Edge it to a fielder '
          'and you are caught.',
      'Twelve balls, three wickets. Every run counts.',
    ],
  ),
  'block-blast': GameVisual(
    name: 'Block Blast',
    tagline: 'Fill rows and columns to blast them. Chain combos.',
    icon: Icons.grid_on_rounded,
    colors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF22D3EE)],
    accent: Color(0xFF4338CA),
    hint: 'Drag a piece onto the board — or tap it, then tap a square.',
    howToPlay: [
      'Drag a piece from the tray onto the board.',
      'Fill a whole row or column and it blasts away.',
      'Clear lines on back-to-back moves for a combo bonus.',
      'The game ends when none of your pieces fit.',
    ],
  ),
  'sling-shot': GameVisual(
    name: 'Sling Shot',
    tagline: 'Pull, aim, release — topple the towers.',
    icon: Icons.rocket_launch_rounded,
    colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
    accent: Color(0xFFD76D77),
    hint: 'Drag back from anywhere to aim, let go to fire.',
    howToPlay: [
      'Drag back and down to pull the sling; the dots show the flight.',
      'Knock out every grumpy gift box to clear the level.',
      'Wood breaks, stone does not — and anything unsupported falls.',
      'Three shots a level; the ones you save are a bonus.',
    ],
  ),
  'hill-rider': GameVisual(
    name: 'Hill Rider',
    tagline: 'Gas, brake, balance — how far can you drive?',
    icon: Icons.directions_car_filled_rounded,
    colors: [Color(0xFF0F4C75), Color(0xFF3282B8), Color(0xFFF9D56E)],
    accent: Color(0xFF3282B8),
    hint: 'Hold GAS to drive, BRAKE to slow down before a crest.',
    howToPlay: [
      'Hold GAS to drive and BRAKE to slow down.',
      'Hit a crest too fast and you fly — land nose-first and you crash.',
      'Gas burns fuel. Drive through the red cans to fill up.',
      'Your score is how far you get, plus a bonus for air time.',
    ],
  ),
  'slide-puzzle': GameVisual(
    name: 'Slide Puzzle',
    tagline: 'Put the tiles back in order. Fewer moves, more points.',
    icon: Icons.extension_rounded,
    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2), Color(0xFFFF6FD8)],
    accent: Color(0xFF8E2DE2),
    hint: 'Tap a tile in line with the gap, or swipe it in.',
    howToPlay: [
      'Tap any tile in line with the gap to slide it across.',
      'Order the tiles 1, 2, 3… with the gap in the bottom corner.',
      'Solving scores 5,000, minus 20 for every move you make.',
    ],
  ),
};

const GameVisual _fallback = GameVisual(
  name: 'Game',
  tagline: 'Pure skill, free to play.',
  icon: Icons.sports_esports_rounded,
  colors: [Color(0xFF0F1B45), Color(0xFF6D28D9), Color(0xFF14B8B8)],
  accent: Color(0xFF6D28D9),
  hint: '',
  howToPlay: [],
);
