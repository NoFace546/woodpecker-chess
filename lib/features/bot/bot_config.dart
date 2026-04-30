import 'package:dartchess/dartchess.dart';

// Stockfish's UCI_Elo only goes down to 1320. For weaker play we fall back to
// Skill Level (0–20) with low depth - much rougher Elo mapping, but it lets
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

/// Assistance mode controls how much help the user gets during a bot game.
/// Inspired by chess.com's crown rewards: more help = fewer crowns.
enum BotAssistMode {
  challenge(
    label: 'Challenge',
    crowns: 3,
    description: 'No hints, no takebacks. Pure play.',
    hintLimit: 0,
    takebackLimit: 0,
  ),
  friendly(
    label: 'Friendly',
    crowns: 2,
    description: 'Up to 3 hints and 3 takebacks per game.',
    hintLimit: 3,
    takebackLimit: 3,
  ),
  assisted(
    label: 'Assisted',
    crowns: 1,
    description: 'Unlimited hints and takebacks. Casual learning.',
    hintLimit: -1,
    takebackLimit: -1,
  );

  const BotAssistMode({
    required this.label,
    required this.crowns,
    required this.description,
    required this.hintLimit,
    required this.takebackLimit,
  });

  final String label;
  final int crowns;
  final String description;
  // -1 means unlimited.
  final int hintLimit;
  final int takebackLimit;

  bool get hintsAllowed => hintLimit != 0;
  bool get takebacksAllowed => takebackLimit != 0;
  bool get hintsUnlimited => hintLimit < 0;
  bool get takebacksUnlimited => takebackLimit < 0;
}

class BotConfig {
  const BotConfig({
    required this.level,
    required this.userSide,
    this.assistMode = BotAssistMode.friendly,
  });

  final BotLevel level;
  final Side userSide;
  final BotAssistMode assistMode;
}
