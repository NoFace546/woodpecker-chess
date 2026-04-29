import 'dart:math';

class Round {
  const Round({
    required this.id,
    required this.setId,
    required this.roundNumber,
    required this.startedAt,
    this.completedAt,
    this.currentPosition = 0,
  });

  final String id;
  final String setId;
  final int roundNumber;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentPosition;

  bool get isCompleted => completedAt != null;

  // Deterministic per-round shuffle of the set's puzzle list.
  // Same round.id always produces the same order (so pause/resume is stable),
  // but each new round draws a fresh permutation.
  List<String> orderedPuzzleIds(List<String> setPuzzleIds) {
    final result = List<String>.from(setPuzzleIds);
    result.shuffle(Random(id.hashCode));
    return result;
  }
}
