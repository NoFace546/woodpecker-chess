import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'router.dart';
import 'services/app_preferences.dart';
import 'services/board_appearance.dart';
import 'services/pro_status.dart';
import 'services/sound_service.dart';
import 'services/stockfish_service.dart';

void main() {
  runApp(const ProviderScope(child: WoodpeckerApp()));
}

class WoodpeckerApp extends ConsumerStatefulWidget {
  const WoodpeckerApp({super.key});

  @override
  ConsumerState<WoodpeckerApp> createState() => _WoodpeckerAppState();
}

class _WoodpeckerAppState extends ConsumerState<WoodpeckerApp> {
  bool _warmedUp = false;

  void _warmup(BuildContext context) {
    if (_warmedUp) return;
    _warmedUp = true;
    unawaited(ref.read(stockfishServiceProvider).start());
    unawaited(ref.read(soundServiceProvider).warmup());
    // Trigger Pro-status bootstrap (grandfathering check + IAP listener).
    ref.read(proStatusProvider);
    final pieceSet = ref.read(pieceSetProvider);
    for (final asset in pieceSet.assets.values) {
      unawaited(precacheImage(asset, context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final boardTheme = ref.watch(boardThemeProvider);
    final pieceSet = ref.watch(pieceSetProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _warmup(context);
    });
    return MaterialApp.router(
      title: 'Woodpecker',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(_lightScheme),
      darkTheme: _buildTheme(_darkScheme),
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            Positioned(
              left: -2000,
              top: -2000,
              width: 320,
              height: 320,
              child: IgnorePointer(
                child: Chessboard(
                  size: 320,
                  orientation: Side.white,
                  fen:
                      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                  settings: ChessboardSettings(
                    enableCoordinates: false,
                    animationDuration: const Duration(milliseconds: 200),
                    colorScheme: boardTheme.colors,
                    pieceAssets: pieceSet.assets,
                  ),
                  game: GameData(
                    playerSide: PlayerSide.none,
                    validMoves:
                        const IMap<Square, ISet<Square>>.empty(),
                    sideToMove: Side.white,
                    isCheck: false,
                    promotionMove: null,
                    onMove: (_, {viaDragAndDrop}) {},
                    onPromotionSelection: (_) {},
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

ThemeData _buildTheme(ColorScheme scheme) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final fontTextTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  final tightenedTextTheme = fontTextTheme.copyWith(
    displayLarge: fontTextTheme.displayLarge
        ?.copyWith(letterSpacing: -0.8, fontWeight: FontWeight.w600),
    displayMedium: fontTextTheme.displayMedium
        ?.copyWith(letterSpacing: -0.6, fontWeight: FontWeight.w600),
    displaySmall: fontTextTheme.displaySmall
        ?.copyWith(letterSpacing: -0.4, fontWeight: FontWeight.w600),
    headlineLarge: fontTextTheme.headlineLarge
        ?.copyWith(letterSpacing: -0.4, fontWeight: FontWeight.w600),
    headlineMedium: fontTextTheme.headlineMedium
        ?.copyWith(letterSpacing: -0.3, fontWeight: FontWeight.w600),
    headlineSmall: fontTextTheme.headlineSmall
        ?.copyWith(letterSpacing: -0.2, fontWeight: FontWeight.w600),
    titleLarge:
        fontTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium:
        fontTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
    titleSmall:
        fontTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
  );
  return base.copyWith(
    textTheme: tightenedTextTheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        letterSpacing: -0.2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: scheme.outline, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}

// Bolder, more recognizable palette: deep emerald primary, warm rust
// secondary, amber gold tertiary. Distinctive across light and dark.
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1F6948),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFA6E0BE),
  onPrimaryContainer: Color(0xFF002915),
  secondary: Color(0xFFB3592E),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFBC9A4),
  onSecondaryContainer: Color(0xFF3D1700),
  tertiary: Color(0xFFC79324),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFCDF8C),
  onTertiaryContainer: Color(0xFF3F2F00),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFADCD7),
  onErrorContainer: Color(0xFF410005),
  surface: Color(0xFFFAF7F2),
  onSurface: Color(0xFF1F1B16),
  onSurfaceVariant: Color(0xFF5A4F40),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF4EFE6),
  surfaceContainer: Color(0xFFEDE6D8),
  surfaceContainerHigh: Color(0xFFE5DCC9),
  surfaceContainerHighest: Color(0xFFDDD2BC),
  outline: Color(0xFF7B6F5E),
  outlineVariant: Color(0xFFD6CFBF),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5FE0A6),
  onPrimary: Color(0xFF003822),
  primaryContainer: Color(0xFF1E5236),
  onPrimaryContainer: Color(0xFFA6E0BE),
  secondary: Color(0xFFFF8E5A),
  onSecondary: Color(0xFF4D1A04),
  secondaryContainer: Color(0xFF6B3013),
  onSecondaryContainer: Color(0xFFFBC9A4),
  tertiary: Color(0xFFF0CB6A),
  onTertiary: Color(0xFF3F2F00),
  tertiaryContainer: Color(0xFF5A4310),
  onTertiaryContainer: Color(0xFFFCDF8C),
  error: Color(0xFFFF8074),
  onError: Color(0xFF410005),
  errorContainer: Color(0xFF7A1D17),
  onErrorContainer: Color(0xFFFADCD7),
  surface: Color(0xFF131110),
  onSurface: Color(0xFFF2EBDD),
  onSurfaceVariant: Color(0xFFC9BFAB),
  surfaceContainerLowest: Color(0xFF0A0908),
  surfaceContainerLow: Color(0xFF1B1815),
  surfaceContainer: Color(0xFF26221E),
  surfaceContainerHigh: Color(0xFF332C25),
  surfaceContainerHighest: Color(0xFF40382F),
  outline: Color(0xFF9E9180),
  outlineVariant: Color(0xFF3D362C),
);
