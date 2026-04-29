import 'set_filter.dart';

class PuzzleSet {
  const PuzzleSet({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.filter,
    required this.puzzleIds,
    this.archivedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final SetFilter filter;
  final List<String> puzzleIds;
  final DateTime? archivedAt;

  int get size => puzzleIds.length;
  bool get isArchived => archivedAt != null;
}
