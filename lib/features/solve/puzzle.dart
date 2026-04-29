import 'package:dartchess/dartchess.dart';

class Puzzle {
  const Puzzle({
    required this.id,
    required this.fen,
    required this.uciMoves,
    required this.rating,
    required this.themes,
  });

  final String id;
  final String fen;
  final List<String> uciMoves;
  final int rating;
  final List<String> themes;

  Position get initialPosition => Chess.fromSetup(Setup.parseFen(fen));

  Side get userSide => initialPosition.turn.opposite;
}

const samplePuzzle = Puzzle(
  id: '00sHx',
  fen: 'q3k1nr/1pp1nQpp/3p4/1P2p3/4P3/B1PP1b2/B5PP/5K2 b k - 0 17',
  uciMoves: ['e8d7', 'a2e6', 'd7d8', 'f7f8'],
  rating: 1760,
  themes: ['mate', 'mateIn2', 'middlegame', 'short'],
);
