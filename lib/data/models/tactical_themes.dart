/// Lichess puzzle themes that aren't tactical patterns. These are excluded
/// from strengths/weaknesses-by-tactic analysis because they aren't actionable
/// training targets — being weak on "short" puzzles isn't a tactic to drill.
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
