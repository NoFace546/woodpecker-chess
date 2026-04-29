import 'package:dartchess/dartchess.dart';

// Stockfish's UCI_Elo only goes down to 1320. For weaker play we fall back to
// Skill Level (0–20) with low depth — much rougher Elo mapping, but it lets
// the engine actually play at sub-1300 strength.
enum BotLevel {
  newcomer(label: 'Newcomer', skillLevel: 0, depth: 1),
  beginner(label: 'Beginner', skillLevel: 3, depth: 3),
  novice(label: 'Novice', skillLevel: 8, depth: 5),
  casual(label: 'Casual', elo: 1320, depth: 8),
  intermediate(label: 'Intermediate', elo: 1700, depth: 12),
  advanced(label: 'Advanced', elo: 2100, depth: 16),
  expert(label: 'Expert', elo: 2400, depth: 20);

  const BotLevel({
    required this.label,
    required this.depth,
    this.elo,
    this.skillLevel,
  });

  final String label;
  final int depth;
  final int? elo;
  final int? skillLevel;

  String get description {
    if (elo != null) return 'Elo $elo • depth $depth';
    return 'Skill ${skillLevel ?? 0} • depth $depth';
  }
}

enum BotColor { white, black, random }

class BotConfig {
  const BotConfig({required this.level, required this.userSide});

  final BotLevel level;
  final Side userSide;
}
