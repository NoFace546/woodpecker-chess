import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/app_preferences.dart';
import '../../services/board_appearance.dart';
import '../../services/stockfish_service.dart';
import '../../widgets/captured_row.dart';
import 'move_validator.dart';
import 'puzzle.dart';

class AnalysisSheet extends ConsumerStatefulWidget {
  const AnalysisSheet({
    super.key,
    required this.puzzle,
    required this.startPosition,
  });

  final Puzzle puzzle;
  final Position startPosition;

  static Future<void> show(
    BuildContext context, {
    required Puzzle puzzle,
    required Position startPosition,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AnalysisSheet(
        puzzle: puzzle,
        startPosition: startPosition,
      ),
    );
  }

  @override
  ConsumerState<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends ConsumerState<AnalysisSheet> {
  AnalysisLine? _analysis;
  _Replay? _replay;
  int _ply = 0;
  late Position _rootPosition;
  late Position _puzzleStartPosition;
  Move? _rootLastMove;
  bool _engineThinking = false;
  bool _analysisFailed = false;
  NormalMove? _promotionMove;
  int _analysisToken = 0;
  final List<_AnalysisHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _puzzleStartPosition = _firstUserPosition(widget.puzzle);
    _rootPosition = widget.startPosition;
    _run();
  }

  Future<void> _run() async {
    final token = ++_analysisToken;
    setState(() {
      _engineThinking = true;
      _analysisFailed = false;
    });
    try {
      final analysis = await ref
          .read(stockfishServiceProvider)
          .analyzeLine(fen: _rootPosition.fen, movetimeMs: 350);
      if (!mounted || token != _analysisToken) return;
      final replay = _Replay.from(_rootPosition, analysis.pv);
      setState(() {
        _analysis = analysis;
        _replay = replay;
        _ply = 0;
        _engineThinking = false;
        _analysisFailed = false;
      });
    } catch (_) {
      if (!mounted || token != _analysisToken) return;
      setState(() {
        _engineThinking = false;
        _analysisFailed = true;
        _replay ??= _Replay.empty(_rootPosition);
        _analysis ??= const AnalysisLine(depth: 0, cp: 0, pv: []);
      });
    }
  }

  Future<void> _playUserMove(Position position, NormalMove move) async {
    if (_engineThinking) return;
    final needsPromotion =
        isPromotionPawnMove(position, move) && move.promotion == null;
    if (needsPromotion) {
      setState(() => _promotionMove = move);
      return;
    }
    if (!position.isLegal(move)) return;
    final afterUser = position.playUnchecked(move);
    setState(() {
      _history.add(_AnalysisHistoryEntry(
        position: _rootPosition,
        lastMove: _rootLastMove,
        analysis: _analysis,
        replay: _replay,
      ));
      _rootPosition = afterUser;
      _rootLastMove = move;
      _ply = 0;
      _replay = _Replay.empty(afterUser);
      _promotionMove = null;
    });
    _run();
  }

  void _undoUserMove() {
    if (_history.isEmpty) return;
    _analysisToken++;
    final previous = _history.removeLast();
    setState(() {
      _rootPosition = previous.position;
      _rootLastMove = previous.lastMove;
      _analysis = previous.analysis;
      _replay = previous.replay ?? _Replay.empty(previous.position);
      _ply = 0;
      _engineThinking = false;
      _promotionMove = null;
      _analysisFailed = false;
    });
  }

  void _startFromPuzzleBeginning() {
    _analysisToken++;
    setState(() {
      _history.clear();
      _rootPosition = _puzzleStartPosition;
      _rootLastMove = null;
      _analysis = null;
      _replay = _Replay.empty(_puzzleStartPosition);
      _ply = 0;
      _engineThinking = false;
      _promotionMove = null;
      _analysisFailed = false;
    });
    _run();
  }

  void _onPromotionSelected(Role? role) {
    final pending = _promotionMove;
    if (pending == null) return;
    if (role == null) {
      setState(() => _promotionMove = null);
      return;
    }
    _playUserMove(_rootPosition, pending.withPromotion(role));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final analysis = _analysis ?? const AnalysisLine(depth: 0, cp: 0, pv: []);
    final replay = _replay ?? _Replay.empty(_rootPosition);
    final lastPly = max(0, replay.positions.length - 1);
    final safePly = _ply < 0 ? 0 : (_ply > lastPly ? lastPly : _ply);
    return SizedBox(
      height: height,
      child: _AnalysisBody(
        puzzle: widget.puzzle,
        analysis: analysis,
        replay: replay,
        ply: safePly,
        rootLastMove: _rootLastMove,
        engineThinking: _engineThinking,
        promotionMove: _promotionMove,
        analysisFailed: _analysisFailed,
        canUndoUserMove: _history.isNotEmpty,
        onPlyChanged: (value) => setState(() => _ply = value),
        onRefresh: _run,
        onUndoUserMove: _undoUserMove,
        onStartFromBeginning: _startFromPuzzleBeginning,
        onMove: _playUserMove,
        onPromotionSelection: _onPromotionSelected,
      ),
    );
  }
}

class _AnalysisHistoryEntry {
  const _AnalysisHistoryEntry({
    required this.position,
    required this.lastMove,
    required this.analysis,
    required this.replay,
  });

  final Position position;
  final Move? lastMove;
  final AnalysisLine? analysis;
  final _Replay? replay;
}

class _AnalysisBody extends ConsumerWidget {
  const _AnalysisBody({
    required this.puzzle,
    required this.analysis,
    required this.replay,
    required this.ply,
    required this.rootLastMove,
    required this.engineThinking,
    required this.promotionMove,
    required this.analysisFailed,
    required this.canUndoUserMove,
    required this.onPlyChanged,
    required this.onRefresh,
    required this.onUndoUserMove,
    required this.onStartFromBeginning,
    required this.onMove,
    required this.onPromotionSelection,
  });

  final Puzzle puzzle;
  final AnalysisLine analysis;
  final _Replay replay;
  final int ply;
  final Move? rootLastMove;
  final bool engineThinking;
  final NormalMove? promotionMove;
  final bool analysisFailed;
  final bool canUndoUserMove;
  final ValueChanged<int> onPlyChanged;
  final VoidCallback onRefresh;
  final VoidCallback onUndoUserMove;
  final VoidCallback onStartFromBeginning;
  final Future<void> Function(Position position, NormalMove move) onMove;
  final ValueChanged<Role?> onPromotionSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardTheme = ref.watch(boardThemeProvider);
    final pieceSet = ref.watch(pieceSetProvider);
    final showCoords = ref.watch(showCoordinatesProvider);
    final animSpeed = ref.watch(animationSpeedProvider);
    final position = replay.positions[ply];
    final nextMove = ply < replay.moves.length ? replay.moves[ply] : null;
    final lastMove = ply > 0 ? replay.moves[ply - 1] : rootLastMove;
    final orientation = puzzle.userSide;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _headline(
                    sideToMoveAtRoot: replay.positions.first.turn,
                    analysis: analysis,
                    failed: analysisFailed,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: engineThinking ? null : onRefresh,
                icon: engineThinking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: engineThinking ? 'Engine thinking' : 'Refresh analysis',
              ),
              IconButton(
                onPressed: canUndoUserMove ? onUndoUserMove : null,
                icon: const Icon(Icons.undo),
                tooltip: 'Undo your move',
              ),
              IconButton(
                onPressed: onStartFromBeginning,
                icon: const Icon(Icons.first_page),
                tooltip: 'Start from first puzzle move',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              analysisFailed
                  ? 'Engine did not return a line. You can still try moves on the board.'
                  : engineThinking && replay.sanLine.isEmpty
                      ? 'Analyzing...'
                      : replay.sanLine.isEmpty
                          ? 'No engine line found.'
                          : replay.sanLine.join(' '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CapturedRow(
          captorSide: orientation.opposite,
          initialPosition: puzzle.initialPosition,
          currentPosition: position,
          pieceAssets: pieceSet.assets,
        ),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = min(constraints.maxWidth, constraints.maxHeight);
                return Chessboard(
                  size: size,
                  orientation: orientation,
                  fen: position.fen,
                  lastMove: lastMove,
                  shapes: nextMove is NormalMove
                      ? ISet({
                          Arrow(
                            color: const Color(0xCC2E7D32),
                            orig: nextMove.from,
                            dest: nextMove.to,
                          ),
                        })
                      : null,
                  settings: ChessboardSettings(
                    enableCoordinates: showCoords,
                    showValidMoves: true,
                    animationDuration: animSpeed.duration,
                    colorScheme: boardTheme.colors,
                    pieceAssets: pieceSet.assets,
                  ),
                  game: GameData(
                    playerSide: engineThinking
                        ? PlayerSide.none
                        : _playerSide(position.turn),
                    validMoves: engineThinking
                        ? const IMap<Square, ISet<Square>>.empty()
                        : makeLegalMoves(position),
                    sideToMove: position.turn,
                    isCheck: position.isCheck,
                    promotionMove: promotionMove,
                    onMove: (move, {viaDragAndDrop}) {
                      if (move is NormalMove) onMove(position, move);
                    },
                    onPromotionSelection: onPromotionSelection,
                  ),
                );
              },
            ),
          ),
        ),
        CapturedRow(
          captorSide: orientation,
          initialPosition: puzzle.initialPosition,
          currentPosition: position,
          pieceAssets: pieceSet.assets,
        ),
        Container(
          color: scheme.surfaceContainer,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: ply > 0 ? () => onPlyChanged(ply - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous move',
                ),
                Expanded(
                  child: Text(
                    engineThinking
                        ? 'Analyzing'
                        : replay.moves.isEmpty
                            ? 'Try a move'
                            : 'Move $ply / ${replay.moves.length}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  onPressed: ply < replay.moves.length
                      ? () => onPlyChanged(ply + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next move',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _headline({
    required Side sideToMoveAtRoot,
    required AnalysisLine analysis,
    required bool failed,
  }) {
    if (failed) return 'Analysis unavailable';
    final whiteCp =
        sideToMoveAtRoot == Side.white ? analysis.cp : -analysis.cp;
    final label = _advantageLabel(whiteCp);
    final score = _scoreLabel(whiteCp);
    final depthLabel = analysis.depth > 0 ? 'Depth: ${analysis.depth}' : 'quick';
    return '$label - Stockfish $depthLabel ($score):';
  }
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            const Text('Could not analyze this position.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

PlayerSide _playerSide(Side side) {
  return side == Side.white ? PlayerSide.white : PlayerSide.black;
}

Position _firstUserPosition(Puzzle puzzle) {
  var position = puzzle.initialPosition;
  if (puzzle.uciMoves.isEmpty) return position;
  final setupMove = Move.parse(puzzle.uciMoves.first);
  if (setupMove == null || !position.isLegal(setupMove)) return position;
  return position.playUnchecked(setupMove);
}

class _Replay {
  const _Replay({
    required this.positions,
    required this.moves,
    required this.sanLine,
  });

  final List<Position> positions;
  final List<Move> moves;
  final List<String> sanLine;

  factory _Replay.empty(Position start) =>
      _Replay(positions: [start], moves: const [], sanLine: const []);

  factory _Replay.from(Position start, List<String> uciMoves) {
    final positions = <Position>[start];
    final moves = <Move>[];
    final san = <String>[];
    var pos = start;
    for (final uci in uciMoves) {
      final move = Move.parse(uci);
      if (move == null || !pos.isLegal(move)) break;
      san.add(_san(pos, move));
      moves.add(move);
      pos = pos.playUnchecked(move);
      positions.add(pos);
    }
    return _Replay(positions: positions, moves: moves, sanLine: san);
  }
}

String _advantageLabel(int whiteCp) {
  if (whiteCp >= 90000) return 'White has mate';
  if (whiteCp <= -90000) return 'Black has mate';
  final abs = whiteCp.abs();
  if (abs < 35) return 'Equal';
  if (abs < 120) return whiteCp > 0 ? 'White is slightly better' : 'Black is slightly better';
  if (abs < 300) return whiteCp > 0 ? 'White is better' : 'Black is better';
  return whiteCp > 0 ? 'White is winning' : 'Black is winning';
}

String _scoreLabel(int whiteCp) {
  if (whiteCp >= 90000) return 'M${100000 - whiteCp}';
  if (whiteCp <= -90000) return '-M${100000 + whiteCp}';
  final pawns = whiteCp / 100.0;
  return pawns >= 0 ? '+${pawns.toStringAsFixed(2)}' : pawns.toStringAsFixed(2);
}

String _san(Position position, Move move) {
  if (move is! NormalMove) return move.uci;
  final piece = position.board.pieceAt(move.from);
  if (piece == null) return move.uci;
  final after = position.playUnchecked(move);
  final checkSuffix = after.isCheckmate ? '#' : after.isCheck ? '+' : '';
  if (piece.role == Role.king && (move.from.value - move.to.value).abs() == 2) {
    return move.to.value > move.from.value ? 'O-O$checkSuffix' : 'O-O-O$checkSuffix';
  }

  final capture = position.board.pieceAt(move.to) != null ||
      (piece.role == Role.pawn && (move.from.value & 7) != (move.to.value & 7));
  final promotion = move.promotion == null ? '' : '=${_roleLetter(move.promotion!)}';
  if (piece.role == Role.pawn) {
    final file = capture ? _fileName(move.from) : '';
    return '$file${capture ? 'x' : ''}${_squareName(move.to)}$promotion$checkSuffix';
  }

  final disambiguation = _disambiguation(position, move, piece.role);
  return '${_roleLetter(piece.role)}$disambiguation${capture ? 'x' : ''}'
      '${_squareName(move.to)}$checkSuffix';
}

String _disambiguation(Position position, NormalMove move, Role role) {
  final sameRoleFrom = <Square>[];
  makeLegalMoves(position).forEach((from, dests) {
    if (from == move.from) return;
    if (!dests.contains(move.to)) return;
    final piece = position.board.pieceAt(from);
    if (piece != null && piece.role == role) {
      sameRoleFrom.add(from);
    }
  });
  if (sameRoleFrom.isEmpty) return '';
  final sameFile = sameRoleFrom.any((s) => (s.value & 7) == (move.from.value & 7));
  final sameRank = sameRoleFrom.any((s) => (s.value >> 3) == (move.from.value >> 3));
  if (!sameFile) return _fileName(move.from);
  if (!sameRank) return _rankName(move.from);
  return _squareName(move.from);
}

String _roleLetter(Role role) {
  return switch (role) {
    Role.king => 'K',
    Role.queen => 'Q',
    Role.rook => 'R',
    Role.bishop => 'B',
    Role.knight => 'N',
    Role.pawn => '',
  };
}

String _squareName(Square square) => '${_fileName(square)}${_rankName(square)}';
String _fileName(Square square) => 'abcdefgh'[square.value & 7];
String _rankName(Square square) => '${(square.value >> 3) + 1}';
