import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences(this._prefs);
  final SharedPreferences _prefs;

  static const _kMuted = 'app.muted';
  static const _kTheme = 'app.themeMode';
  static const _kOnboarded = 'app.onboarded';
  static const _kAutoAdvance = 'app.autoAdvance';
  static const _kLastBackupAt = 'app.lastBackupAt';

  bool get muted => _prefs.getBool(_kMuted) ?? false;
  Future<void> setMuted(bool value) => _prefs.setBool(_kMuted, value);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  bool get autoAdvance => _prefs.getBool(_kAutoAdvance) ?? false;
  Future<void> setAutoAdvance(bool value) =>
      _prefs.setBool(_kAutoAdvance, value);

  DateTime? get lastBackupAt {
    final ms = _prefs.getInt(_kLastBackupAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime value) =>
      _prefs.setInt(_kLastBackupAt, value.millisecondsSinceEpoch);

  static const _kBoardTheme = 'app.boardTheme';
  static const _kPieceSet = 'app.pieceSet';

  String? get boardThemeName => _prefs.getString(_kBoardTheme);
  Future<void> setBoardThemeName(String name) =>
      _prefs.setString(_kBoardTheme, name);

  String? get pieceSetName => _prefs.getString(_kPieceSet);
  Future<void> setPieceSetName(String name) =>
      _prefs.setString(_kPieceSet, name);

  static const _kShowCoordinates = 'app.showCoordinates';
  static const _kShowLegalMoves = 'app.showLegalMoves';
  static const _kAnimationSpeed = 'app.animationSpeed';
  static const _kConfetti = 'app.confetti';
  static const _kAutoFlip = 'app.autoFlipBoard';
  static const _kHints = 'app.hintsEnabled';

  bool get showCoordinates => _prefs.getBool(_kShowCoordinates) ?? true;
  Future<void> setShowCoordinates(bool v) =>
      _prefs.setBool(_kShowCoordinates, v);

  bool get showLegalMoves => _prefs.getBool(_kShowLegalMoves) ?? true;
  Future<void> setShowLegalMoves(bool v) => _prefs.setBool(_kShowLegalMoves, v);

  String get animationSpeedName =>
      _prefs.getString(_kAnimationSpeed) ?? 'normal';
  Future<void> setAnimationSpeedName(String v) =>
      _prefs.setString(_kAnimationSpeed, v);

  bool get confettiEnabled => _prefs.getBool(_kConfetti) ?? true;
  Future<void> setConfettiEnabled(bool v) => _prefs.setBool(_kConfetti, v);

  bool get autoFlipBoard => _prefs.getBool(_kAutoFlip) ?? true;
  Future<void> setAutoFlipBoard(bool v) => _prefs.setBool(_kAutoFlip, v);

  bool get hintsEnabled => _prefs.getBool(_kHints) ?? true;
  Future<void> setHintsEnabled(bool v) => _prefs.setBool(_kHints, v);

  ThemeMode get themeMode {
    switch (_prefs.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final encoded = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(_kTheme, encoded);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(prefs);
});

class _MutedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    return asyncPrefs.maybeWhen(
      data: (p) => p.muted,
      orElse: () => false,
    );
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setMuted(value);
  }
}

class _ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    return asyncPrefs.maybeWhen(
      data: (p) => p.themeMode,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setThemeMode(mode);
  }
}

final mutedProvider =
    NotifierProvider<_MutedNotifier, bool>(_MutedNotifier.new);

final themeModeProvider =
    NotifierProvider<_ThemeModeNotifier, ThemeMode>(_ThemeModeNotifier.new);

class _OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    return asyncPrefs.maybeWhen(
      data: (p) => p.onboarded,
      orElse: () => true, // Default to true to avoid flashing onboarding
    );
  }

  Future<void> markComplete() async {
    state = true;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setOnboarded(true);
  }
}

final onboardedProvider =
    NotifierProvider<_OnboardedNotifier, bool>(_OnboardedNotifier.new);

class _AutoAdvanceNotifier extends Notifier<bool> {
  @override
  bool build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    return asyncPrefs.maybeWhen(
      data: (p) => p.autoAdvance,
      orElse: () => false,
    );
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setAutoAdvance(value);
  }
}

final autoAdvanceProvider =
    NotifierProvider<_AutoAdvanceNotifier, bool>(_AutoAdvanceNotifier.new);

class _LastBackupNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    return asyncPrefs.maybeWhen(
      data: (p) => p.lastBackupAt,
      orElse: () => null,
    );
  }

  Future<void> markNow() async {
    final now = DateTime.now();
    state = now;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setLastBackupAt(now);
  }
}

final lastBackupProvider =
    NotifierProvider<_LastBackupNotifier, DateTime?>(
  _LastBackupNotifier.new,
);

enum AnimationSpeed {
  off(Duration.zero, 'Off'),
  fast(Duration(milliseconds: 350), 'Fast'),
  normal(Duration(milliseconds: 550), 'Normal'),
  slow(Duration(milliseconds: 800), 'Slow');

  const AnimationSpeed(this.duration, this.label);
  final Duration duration;
  final String label;

  static AnimationSpeed fromName(String? name) {
    if (name == null) return AnimationSpeed.normal;
    return AnimationSpeed.values.firstWhere(
      (s) => s.name == name,
      orElse: () => AnimationSpeed.normal,
    );
  }
}

class _ShowCoordinatesNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesProvider).maybeWhen(
        data: (p) => p.showCoordinates,
        orElse: () => true,
      );
  Future<void> set(bool value) async {
    state = value;
    final p = await ref.read(appPreferencesProvider.future);
    await p.setShowCoordinates(value);
  }
}

class _ShowLegalMovesNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesProvider).maybeWhen(
        data: (p) => p.showLegalMoves,
        orElse: () => true,
      );
  Future<void> set(bool value) async {
    state = value;
    final p = await ref.read(appPreferencesProvider.future);
    await p.setShowLegalMoves(value);
  }
}

class _ConfettiNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesProvider).maybeWhen(
        data: (p) => p.confettiEnabled,
        orElse: () => true,
      );
  Future<void> set(bool value) async {
    state = value;
    final p = await ref.read(appPreferencesProvider.future);
    await p.setConfettiEnabled(value);
  }
}

class _AutoFlipNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesProvider).maybeWhen(
        data: (p) => p.autoFlipBoard,
        orElse: () => true,
      );
  Future<void> set(bool value) async {
    state = value;
    final p = await ref.read(appPreferencesProvider.future);
    await p.setAutoFlipBoard(value);
  }
}

class _HintsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesProvider).maybeWhen(
        data: (p) => p.hintsEnabled,
        orElse: () => true,
      );
  Future<void> set(bool value) async {
    state = value;
    final p = await ref.read(appPreferencesProvider.future);
    await p.setHintsEnabled(value);
  }
}

final showCoordinatesProvider =
    NotifierProvider<_ShowCoordinatesNotifier, bool>(
        _ShowCoordinatesNotifier.new);
final showLegalMovesProvider =
    NotifierProvider<_ShowLegalMovesNotifier, bool>(
        _ShowLegalMovesNotifier.new);
final confettiEnabledProvider =
    NotifierProvider<_ConfettiNotifier, bool>(_ConfettiNotifier.new);
final autoFlipBoardProvider =
    NotifierProvider<_AutoFlipNotifier, bool>(_AutoFlipNotifier.new);
final hintsEnabledProvider =
    NotifierProvider<_HintsNotifier, bool>(_HintsNotifier.new);

class _AnimationSpeedNotifier extends Notifier<AnimationSpeed> {
  @override
  AnimationSpeed build() {
    final asyncPrefs = ref.watch(appPreferencesProvider);
    return asyncPrefs.maybeWhen(
      data: (p) => AnimationSpeed.fromName(p.animationSpeedName),
      orElse: () => AnimationSpeed.normal,
    );
  }

  Future<void> set(AnimationSpeed value) async {
    state = value;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setAnimationSpeedName(value.name);
  }
}

final animationSpeedProvider =
    NotifierProvider<_AnimationSpeedNotifier, AnimationSpeed>(
  _AnimationSpeedNotifier.new,
);
