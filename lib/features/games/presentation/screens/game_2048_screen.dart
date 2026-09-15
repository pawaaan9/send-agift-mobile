import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/games_providers.dart';
import '../../domain/game.dart';
import '../../domain/game_2048.dart';
import '../widgets/board_2048.dart';

/// Plays one round of 2048.
///
/// The app runs the game locally so it stays responsive, but it is not the
/// authority on the result: the board is generated from a seed the server
/// issued, and when the round ends the moves are sent back for the server to
/// replay and score. Whatever score is shown here is provisional until then.
class Game2048Screen extends ConsumerStatefulWidget {
  const Game2048Screen({super.key});

  static const String slug = '2048';

  @override
  ConsumerState<Game2048Screen> createState() => _Game2048ScreenState();
}

/// Below this the drag reads as a stray touch rather than a deliberate swipe.
const double _minSwipeVelocity = 90;

class _Game2048ScreenState extends ConsumerState<Game2048Screen> {
  GameSession? _session;
  Game2048? _game;

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  /// Set once a round has been sent, so a game cannot be submitted twice.
  GameScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Future<void> _startNewGame() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _game = null;
    });

    try {
      final session = await ref
          .read(gamesRepositoryProvider)
          .startSession(Game2048Screen.slug);
      if (!mounted) return;
      setState(() {
        _session = session;
        _game = Game2048(seed: session.seed, config: session.config);
        _loading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _handleSwipe(String direction) {
    final game = _game;
    if (game == null || _submitting || _result != null) return;

    if (!game.move(direction)) return;
    setState(() {});

    // Ending the round is the app's job to notice, but not to judge: the
    // server decides what the run was worth.
    if (game.isGameOver || game.reachedMoveLimit) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final game = _game;
    final session = _session;
    if (game == null || session == null || _submitting || _result != null) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await ref
          .read(gamesRepositoryProvider)
          .submitScore(
            session.sessionId,
            moves: game.moves,
            clientScore: game.score,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _submitting = false;
      });
      // A new personal best changes the board, so refresh it.
      ref.invalidate(leaderboardProvider(Game2048Screen.slug));
      _showResultSheet(result);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _showResultSheet(GameScoreResult result) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _ResultSheet(
        result: result,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _startNewGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;

    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(
            onPressed: _loading || _submitting ? null : _startNewGame,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New game',
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_error != null) {
              return _ErrorView(message: _error!, onRetry: _startNewGame);
            }
            if (game == null) return const SizedBox.shrink();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScoreRow(
                    score: game.score,
                    highestTile: game.highestTile,
                    moves: game.moves.length,
                  ),
                  const SizedBox(height: 16),

                  // Swipes drive the engine directly; there is no animation
                  // queue that could let input and state drift apart.
                  //
                  // Horizontal and vertical drags are handled separately
                  // rather than with a single onPanEnd. A pan recognizer
                  // loses the gesture arena to the scroll view above, so
                  // up and down swipes would scroll the page instead of
                  // moving tiles. Same-axis recognizers let the board — the
                  // deeper widget — win instead.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      final vx = details.velocity.pixelsPerSecond.dx;
                      if (vx.abs() < _minSwipeVelocity) return;
                      _handleSwipe(vx > 0 ? Move2048.right : Move2048.left);
                    },
                    onVerticalDragEnd: (details) {
                      final vy = details.velocity.pixelsPerSecond.dy;
                      if (vy.abs() < _minSwipeVelocity) return;
                      _handleSwipe(vy > 0 ? Move2048.down : Move2048.up);
                    },
                    child: Board2048(board: game.board, size: game.size),
                  ),

                  const SizedBox(height: 16),
                  if (_submitting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Checking your score…'),
                        ],
                      ),
                    )
                  else if (_result != null)
                    FilledButton(
                      onPressed: _startNewGame,
                      child: const Text('Play again'),
                    )
                  else
                    OutlinedButton(
                      // Lets a player bank a good run instead of playing into
                      // a dead board.
                      onPressed: game.moves.isEmpty ? null : _submit,
                      child: const Text('Finish and submit'),
                    ),

                  const SizedBox(height: 20),
                  const _FairPlayNote(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.score,
    required this.highestTile,
    required this.moves,
  });

  final int score;
  final int highestTile;
  final int moves;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Score', value: '$score')),
        const SizedBox(width: 10),
        Expanded(child: _Stat(label: 'Best tile', value: '$highestTile')),
        const SizedBox(width: 10),
        Expanded(child: _Stat(label: 'Moves', value: '$moves')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.eyebrow),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.display(20)),
        ],
      ),
    );
  }
}

/// The app-store and competition rules require it to be clear that nothing
/// here is decided by chance.
class _FairPlayNote extends StatelessWidget {
  const _FairPlayNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 18,
            color: AppColors.accentForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pure skill — chance plays no part. Every player gets the same '
              'tiles from the same server seed, and every score is checked on '
              'our servers.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.accentForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result, required this.onPlayAgain});

  final GameScoreResult result;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final headline = result.won
        ? 'You reached 2048!'
        : result.isPersonalBest
        ? 'New personal best'
        : 'Round complete';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        4,
        AppTheme.gutter,
        AppTheme.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(headline, style: AppTypography.display(24)),
          const SizedBox(height: 14),
          _ResultRow(label: 'Verified score', value: '${result.score}'),
          _ResultRow(label: 'Best tile', value: '${result.highestTile}'),
          _ResultRow(label: 'Moves', value: '${result.movesCount}'),
          _ResultRow(label: 'Personal best', value: '${result.personalBest}'),
          if (!result.accepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                'This round is being reviewed before it joins the leaderboard. '
                'Making sure your app is up to date usually resolves it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(onPressed: onPlayAgain, child: const Text('Play again')),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_esports_outlined,
              size: 40,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
