/// Lichess puzzle themes that aren't tactical patterns. These are excluded
/// from strengths/weaknesses-by-tactic analysis because they aren't actionable
/// training targets - being weak on "short" puzzles isn't a tactic to drill.
///
/// Phases (opening/middlegame/endgame) are excluded from the tactical list
/// but surfaced separately as a 3-axis radar chart on the Strengths screen.
const kPhaseThemes = <String>{'opening', 'middlegame', 'endgame'};

const kNonTacticalThemes = <String>{
  // Evaluation buckets
  'crushing', 'advantage', 'equality', 'mate',
  // Puzzle length
  'oneMove', 'short', 'long', 'veryLong',
  // Source
  'master', 'masterVsMaster', 'superGM',
  // Game phases (shown separately as a radar)
  ...kPhaseThemes,
};

bool isTacticalTheme(String theme) => !kNonTacticalThemes.contains(theme);

List<String> filterTactical(Iterable<String> themes) =>
    themes.where(isTacticalTheme).toList();

/// The themes that count as "what you actually train on" for a club-level
/// player. Used to filter recommended-set metadata so the displayed theme
/// count reflects the meaningful training categories, not every obscure
/// Lichess tag (`attackingF2F7`, `zugzwang`, …) that might attach to a
/// puzzle.
const kCuratedTrainingThemes = <String>{
  // Core tactical motifs
  'fork', 'pin', 'skewer', 'discoveredAttack', 'doubleCheck',
  'sacrifice', 'attraction', 'deflection',
  'intermezzo', 'interference', 'clearance',
  'xRayAttack', 'hangingPiece', 'trappedPiece', 'capturingDefender',
  'quietMove', 'defensiveMove', 'exposedKing', 'attackingPin',
  // Common mate patterns
  'mateIn1', 'mateIn2', 'mateIn3', 'mateIn4',
  'backRankMate', 'smotheredMate',
  'anastasiaMate', 'arabianMate', 'bodenMate', 'hookMate',
  // Endgame types
  'pawnEndgame', 'rookEndgame', 'bishopEndgame', 'knightEndgame',
  'queenEndgame', 'queenRookEndgame',
  // Special moves worth practising
  'enPassant', 'promotion', 'underPromotion',
};

bool isCuratedTrainingTheme(String theme) =>
    kCuratedTrainingThemes.contains(theme);
