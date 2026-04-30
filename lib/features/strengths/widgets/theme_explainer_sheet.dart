import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/theme_definitions.dart';
import '../../../data/repositories/puzzle_repository.dart';
import '../../../services/app_preferences.dart';
import '../../../services/board_appearance.dart';
import '../../solve/puzzle.dart';

class ThemeExplainerSheet extends ConsumerWidget {
  const ThemeExplainerSheet({super.key, required this.theme});

  final String theme;

  static Future<void> show(BuildContext context, String theme) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ThemeExplainerSheet(theme: theme),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = definitionFor(theme) ??
        'No description available for this theme yet.';
    final exampleAsync = ref.watch(puzzleExampleForThemeProvider(theme));
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(theme, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(definition, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              'Example',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            exampleAsync.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Could not load example.',
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ),
              data: (puzzle) {
                if (puzzle == null) {
                  return const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text('No example puzzle for this theme yet.'),
                    ),
                  );
                }
                return _AutoPlayBoard(puzzle: puzzle);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoPlayBoard extends ConsumerStatefulWidget {
  const _AutoPlayBoard({required this.puzzle});
  final Puzzle puzzle;

  @override
  ConsumerState<_AutoPlayBoard> createState() => _AutoPlayBoardState();
}

class _AutoPlayBoardState extends ConsumerState<_AutoPlayBoard> {
  static const _setupDelay = Duration(milliseconds: 700);
  static const _stepDelay = Duration(milliseconds: 800);
  static const _loopPause = Duration(milliseconds: 1800);

  late Position _position;
  Move? _lastMove;
  Timer? _timer;
  int _step = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _resetAndStart();
  }

  @override
  void didUpdateWidget(covariant _AutoPlayBoard old) {
    super.didUpdateWidget(old);
    if (old.puzzle.id != widget.puzzle.id) {
      _resetAndStart();
    }
  }

  void _resetAndStart() {
    _timer?.cancel();
    setState(() {
      _position = widget.puzzle.initialPosition;
      _lastMove = null;
      _step = 0;
    });
    _scheduleNext(_setupDelay);
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _playStep);
  }

  void _playStep() {
    if (_disposed || !mounted) return;
    if (_step >= widget.puzzle.uciMoves.length) {
      // End of line. Pause, then loop back to the start.
      _scheduleNext(_loopPause);
      _step = -1;
      return;
    }
    if (_step == -1) {
      _resetAndStart();
      return;
    }
    final uci = widget.puzzle.uciMoves[_step];
    final move = Move.parse(uci);
    if (move == null || !_position.isLegal(move)) {
      // Bail out - invalid move, just stop.
      return;
    }
    final after = _position.playUnchecked(move);
    setState(() {
      _position = after;
      _lastMove = move;
      _step++;
    });
    _scheduleNext(_stepDelay);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardTheme = ref.watch(boardThemeProvider);
    final pieceSet = ref.watch(pieceSetProvider);
    final animSpeed = ref.watch(animationSpeedProvider);
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = min(constraints.maxWidth, 320.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chessboard(
                size: size,
                orientation: widget.puzzle.userSide,
                fen: _position.fen,
                lastMove: _lastMove,
                settings: ChessboardSettings(
                  enableCoordinates: false,
                  animationDuration: animSpeed.duration,
                  colorScheme: boardTheme.colors,
                  pieceAssets: pieceSet.assets,
                ),
                game: GameData(
                  playerSide: PlayerSide.none,
                  validMoves: const IMap<Square, ISet<Square>>.empty(),
                  sideToMove: _position.turn,
                  isCheck: _position.isCheck,
                  promotionMove: null,
                  onMove: (_, {viaDragAndDrop}) {},
                  onPromotionSelection: (_) {},
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puzzle #${widget.puzzle.id} · rating ${widget.puzzle.rating}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
