import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences(this._prefs);
  final SharedPreferences _prefs;

  static const _kMuted = 'app.muted';
  static const _kTheme = 'app.themeMode';
  static const _kOnboarded = 'app.onboarded';

  bool get muted => _prefs.getBool(_kMuted) ?? false;
  Future<void> setMuted(bool value) => _prefs.setBool(_kMuted, value);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

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
