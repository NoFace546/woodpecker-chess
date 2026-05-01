/// Short human-readable definitions of Lichess puzzle themes.
///
/// Used by the theme-explainer bottom sheet on the Strengths screen.
/// Definitions are intentionally short (one or two sentences) and aimed
/// at intermediate players who recognise the chess vocabulary.
///
/// Source: github.com/lichess-org/lila puzzleTheme translations.
const Map<String, String> kThemeDefinitions = {
  // Mating patterns by length
  'mateIn1': 'Force checkmate in one move.',
  'mateIn2': 'Force checkmate in two moves against any defence.',
  'mateIn3': 'Force checkmate in three moves against any defence.',
  'mateIn4': 'Force checkmate in four moves against any defence.',
  'mateIn5': 'Force checkmate in five or more moves against any defence.',

  // Named mating patterns
  'smotheredMate':
      'A knight delivers mate to a king that cannot move because its own '
          'pieces block every escape square.',
  'backRankMate':
      'Mate on the home rank where the king is trapped behind its own pawns.',
  'anastasiaMate':
      'A knight and rook (or queen) trap the king against the edge of the '
          'board, with one of the king\'s own pieces blocking escape.',
  'arabianMate':
      'A rook and knight corner the enemy king with the rook delivering mate '
          'and the knight blocking escape.',
  'bodenMate':
      'Two bishops on crossing diagonals deliver mate to a castled king.',
  'doubleBishopMate':
      'Two bishops on adjacent diagonals deliver mate to a king with no '
          'escape squares.',
  'dovetailMate':
      'A queen mates an adjacent king whose escape squares are blocked by '
          'its own pieces, forming a dovetail shape.',
  'hookMate':
      'Mate by a rook supported by a knight and pawn, with an enemy pawn '
          'restricting the king.',
  'killBoxMate':
      'A rook beside the king supported by a queen forms a "kill box" '
          'cutting off all escape squares.',
  'cornerMate':
      'A rook or queen with knight support traps the enemy king in a corner '
          'and delivers mate.',
  'epauletteMate':
      'The king\'s escape squares are blocked by its own pieces (the '
          '"epaulettes") so the queen mates on a file or rank.',
  'morphysMate':
      'A bishop delivers check while a rook cuts off the king, named after '
          'Paul Morphy\'s famous opera-house game.',
  'operaMate':
      'A rook delivers mate with a bishop guarding it, named after Morphy\'s '
          'game at the Paris Opera.',
  'pillsburysMate':
      'A rook delivers mate while a bishop confines the king, named after '
          'Harry Pillsbury.',

  // Core tactical motifs
  'fork':
      'A single move attacks two or more enemy pieces at once, winning '
          'material.',
  'pin':
      'A piece is attacked but cannot move because moving it would expose a '
          'more valuable piece (or the king) behind it.',
  'skewer':
      'Like a pin in reverse: the front piece is more valuable, and when it '
          'moves the piece behind it can be captured.',
  'discoveredAttack':
      'Moving one piece uncovers an attack from a long-range piece behind '
          'it.',
  'discoveredCheck':
      'Moving one piece uncovers a check from a long-range piece behind it.',
  'doubleCheck':
      'Two pieces give check simultaneously through a discovered attack. '
          'The king must move; nothing can block both.',
  'sacrifice':
      'Give up material in the short term to gain a bigger advantage after '
          'a forced sequence.',
  'attraction':
      'Force an enemy piece (often the king) onto a square where it can be '
          'attacked.',
  'deflection':
      'Force an enemy piece off a square or line where it was defending '
          'something important.',
  'interference':
      'Move a piece between two enemy pieces, breaking the connection or '
          'defence between them.',
  'xRayAttack':
      'A piece attacks (or defends) a square through an enemy piece on the '
          'same line.',
  'capturingDefender':
      'Capture the piece that defends a target so the target itself can be '
          'taken next.',
  'hangingPiece':
      'An enemy piece has no defenders and can be won outright.',
  'trappedPiece':
      'A piece has no safe squares and is bound to be captured.',
  'intermezzo':
      'An "in-between" move (zwischenzug) that creates an immediate threat '
          'before the expected reply.',
  'quietMove':
      'A move that does not capture or check but sets up an unstoppable '
          'follow-up threat.',
  'zugzwang':
      'The opponent is forced to move and any move worsens their position.',
  'advancedPawn':
      'A pawn deep in enemy territory creates the threat of promotion or '
          'breaks the position open.',
  'collinearMove':
      'A piece slides along the same line as another attacker to combine '
          'pressure or set up tactics.',
  'clearance':
      'Move a piece off a square or line so a teammate can use it for the '
          'tactic.',

  // King attacks
  'kingsideAttack':
      'Coordinated attack against the king castled on the kingside.',
  'queensideAttack':
      'Coordinated attack against the king castled on the queenside.',
  'attackingF2F7':
      'Pressure on the f2 or f7 square, the weakest squares at the start '
          'of the game.',
  'exposedKing':
      'A king with few defenders is vulnerable to direct attack.',
  'castling':
      'Castling brings the king to safety and activates the rook, often as '
          'part of a tactic.',
  'enPassant':
      'Capture an enemy pawn that just advanced two squares using en '
          'passant.',

  // Endgames
  'pawnEndgame':
      'Endgame with only pawns and kings; the smallest mistake decides the '
          'game.',
  'rookEndgame':
      'Endgame with only rooks and pawns; activity and king safety dominate.',
  'queenEndgame':
      'Endgame with only queens and pawns; constant tactical alertness '
          'needed.',
  'queenRookEndgame':
      'Endgame with both queens and rooks on the board.',
  'knightEndgame':
      'Endgame with only knights and pawns; piece coordination and outposts '
          'matter.',
  'bishopEndgame':
      'Endgame with only bishops and pawns; bishop colour vs the pawn '
          'structure decides.',

  // Promotion
  'promotion':
      'Push a pawn to the last rank to promote, often decisively.',
  'underPromotion':
      'Promote to a knight, bishop, or rook instead of a queen, usually '
          'because a queen would not work.',

  // Defensive
  'defensiveMove':
      'A precise move that prevents material loss instead of attacking.',

  // Generic mate / phase / length tags also surface in the UI and benefit
  // from a one-liner so the explainer sheet never falls back to "no
  // description".
  'mate':
      'The puzzle ends in checkmate. Calculate the forced mating sequence '
          'rather than just winning material.',
  'opening':
      'A position from the opening phase (typically the first 10-15 moves). '
          'Tactics here often punish concrete development mistakes.',
  'middlegame':
      'A middlegame position, after both sides have developed and the centre '
          'or kingside attacks become possible.',
  'endgame':
      'An endgame position with reduced material. Solutions often involve '
          'piece coordination and king activity rather than raw tactics.',
  'short':
      'A short puzzle (typically two-move solution). Quick pattern '
          'recognition matters more than deep calculation.',
  'long':
      'A longer puzzle with several moves to play. Calculation depth and '
          'visualisation skill are tested.',
  'attackingPin':
      'A pin that not only restricts the pinned piece but also threatens to '
          'win material on the pinning line.',
};

String? definitionFor(String theme) => kThemeDefinitions[theme];
