import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'services/app_preferences.dart';

void main() {
  runApp(const ProviderScope(child: WoodpeckerApp()));
}

class WoodpeckerApp extends ConsumerWidget {
  const WoodpeckerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Woodpecker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5A3C),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5A3C),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
