import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

/// Shows pieces of [captorSide].opposite that are missing compared to the
/// initial position - i.e. the pieces [captorSide] has captured. Includes a
/// material differential when captures are uneven.
class CapturedRow extends StatelessWidget {
  const CapturedRow({
    super.key,
    required this.captorSide,
    required this.initialPosition,
    required this.currentPosition,
    required this.pieceAssets,
  });

  final Side captorSide;
  final Position initialPosition;
  final Position currentPosition;
  final PieceAssets pieceAssets;

  static const _values = {
    Role.pawn: 1,
    Role.knight: 3,
    Role.bishop: 3,
    Role.rook: 5,
    Role.queen: 9,
    Role.king: 0,
  };

  static const _orderedRoles = [
    Role.pawn,
    Role.knight,
    Role.bishop,
    Role.rook,
    Role.queen,
  ];

  static final Map<Side, Map<Role, PieceKind>> _kindByColorAndRole = {
    Side.white: {
      Role.pawn: PieceKind.whitePawn,
      Role.knight: PieceKind.whiteKnight,
      Role.bishop: PieceKind.whiteBishop,
      Role.rook: PieceKind.whiteRook,
      Role.queen: PieceKind.whiteQueen,
      Role.king: PieceKind.whiteKing,
    },
    Side.black: {
      Role.pawn: PieceKind.blackPawn,
      Role.knight: PieceKind.blackKnight,
      Role.bishop: PieceKind.blackBishop,
      Role.rook: PieceKind.blackRook,
      Role.queen: PieceKind.blackQueen,
      Role.king: PieceKind.blackKing,
    },
  };

  @override
  Widget build(BuildContext context) {
    final captorMissing = _missing(captorSide);
    final victimMissing = _missing(captorSide.opposite);
    final captorMaterial = _materialOf(victimMissing);
    final victimMaterial = _materialOf(captorMissing);
    final diff = captorMaterial - victimMaterial;

    final pieces = <Widget>[];
    final victimKinds = _kindByColorAndRole[captorSide.opposite]!;
    for (final role in _orderedRoles) {
      final count = victimMissing[role] ?? 0;
      final kind = victimKinds[role];
      if (kind == null) continue;
      final asset = pieceAssets[kind];
      if (asset == null) continue;
      for (var i = 0; i < count; i++) {
        pieces.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Image(image: asset, width: 18, height: 18),
        ));
      }
    }
    if (pieces.isEmpty && diff <= 0) {
      return const SizedBox(height: 24);
    }
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ...pieces,
          if (diff > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '+$diff',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Map<Role, int> _missing(Side side) {
    final initialCounts = _countByRole(initialPosition, side);
    final currentCounts = _countByRole(currentPosition, side);
    final out = <Role, int>{};
    for (final entry in initialCounts.entries) {
      final missing = entry.value - (currentCounts[entry.key] ?? 0);
      if (missing > 0) out[entry.key] = missing;
    }
    return out;
  }

  Map<Role, int> _countByRole(Position pos, Side side) {
    final counts = <Role, int>{};
    for (var i = 0; i < 64; i++) {
      final piece = pos.board.pieceAt(Square(i));
      if (piece == null || piece.color != side) continue;
      counts[piece.role] = (counts[piece.role] ?? 0) + 1;
    }
    return counts;
  }

  int _materialOf(Map<Role, int> missing) {
    var sum = 0;
    for (final entry in missing.entries) {
      sum += entry.value * (_values[entry.key] ?? 0);
    }
    return sum;
  }
}
