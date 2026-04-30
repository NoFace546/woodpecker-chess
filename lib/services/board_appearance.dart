import 'package:chessground/chessground.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences.dart';
import 'pro_status.dart';

/// User-selectable board colour schemes from chessground.
enum BoardTheme {
  brown('Brown', ChessboardColorScheme.brown),
  blue('Blue', ChessboardColorScheme.blue),
  blue2('Blue 2', ChessboardColorScheme.blue2),
  blue3('Blue 3', ChessboardColorScheme.blue3),
  blueMarble('Blue marble', ChessboardColorScheme.blueMarble),
  green('Green', ChessboardColorScheme.green),
  greenPlastic('Green plastic', ChessboardColorScheme.greenPlastic),
  wood('Wood', ChessboardColorScheme.wood),
  wood2('Wood 2', ChessboardColorScheme.wood2),
  wood3('Wood 3', ChessboardColorScheme.wood3),
  wood4('Wood 4', ChessboardColorScheme.wood4),
  maple('Maple', ChessboardColorScheme.maple),
  maple2('Maple 2', ChessboardColorScheme.maple2),
  leather('Leather', ChessboardColorScheme.leather),
  marble('Marble', ChessboardColorScheme.marble),
  ic('IC', ChessboardColorScheme.ic),
  canvas('Canvas', ChessboardColorScheme.canvas),
  newspaper('Newspaper', ChessboardColorScheme.newspaper),
  metal('Metal', ChessboardColorScheme.metal),
  grey('Grey', ChessboardColorScheme.grey),
  olive('Olive', ChessboardColorScheme.olive),
  purple('Purple', ChessboardColorScheme.purple),
  purpleDiag('Purple diag', ChessboardColorScheme.purpleDiag),
  pinkPyramid('Pink', ChessboardColorScheme.pinkPyramid),
  horsey('Horsey', ChessboardColorScheme.horsey);

  const BoardTheme(this.label, this.colors);

  final String label;
  final ChessboardColorScheme colors;

  static BoardTheme fromName(String? name) {
    if (name == null) return BoardTheme.brown;
    return BoardTheme.values
        .firstWhere((t) => t.name == name, orElse: () => BoardTheme.brown);
  }

  bool get isFree => this == BoardTheme.brown;
}

/// Notifier for the user-selected board theme. Persists in shared_prefs.
class _BoardThemeNotifier extends Notifier<BoardTheme> {
  @override
  BoardTheme build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    final isPro = ref.watch(isProProvider);
    return asyncPrefs.maybeWhen(
      data: (p) {
        final selected = BoardTheme.fromName(p.boardThemeName);
        return isPro || selected.isFree ? selected : BoardTheme.brown;
      },
      orElse: () => BoardTheme.brown,
    );
  }

  Future<void> set(BoardTheme value) async {
    final isPro = ref.read(isProProvider);
    final next = isPro || value.isFree ? value : BoardTheme.brown;
    state = next;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setBoardThemeName(next.name);
  }
}

final boardThemeProvider =
    NotifierProvider<_BoardThemeNotifier, BoardTheme>(_BoardThemeNotifier.new);

/// Notifier for the user-selected piece set. Persists in shared_prefs.
class _PieceSetNotifier extends Notifier<PieceSet> {
  @override
  PieceSet build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    final isPro = ref.watch(isProProvider);
    return asyncPrefs.maybeWhen(
      data: (p) {
        final name = p.pieceSetName;
        if (name == null) return PieceSet.cburnett;
        final selected = PieceSet.values.firstWhere(
          (ps) => ps.name == name,
          orElse: () => PieceSet.cburnett,
        );
        return isPro || selected == PieceSet.cburnett
            ? selected
            : PieceSet.cburnett;
      },
      orElse: () => PieceSet.cburnett,
    );
  }

  Future<void> set(PieceSet value) async {
    final isPro = ref.read(isProProvider);
    final next =
        isPro || value == PieceSet.cburnett ? value : PieceSet.cburnett;
    state = next;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setPieceSetName(next.name);
  }
}

final pieceSetProvider =
    NotifierProvider<_PieceSetNotifier, PieceSet>(_PieceSetNotifier.new);
