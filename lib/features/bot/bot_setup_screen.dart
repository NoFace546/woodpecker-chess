import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/bot_game_repository.dart';
import 'bot_config.dart';

class BotSetupScreen extends ConsumerStatefulWidget {
  const BotSetupScreen({super.key});

  @override
  ConsumerState<BotSetupScreen> createState() => _BotSetupScreenState();
}

class _BotSetupScreenState extends ConsumerState<BotSetupScreen> {
  BotLevel _level = BotLevel.casual;
  BotColor _color = BotColor.white;

  @override
  Widget build(BuildContext context) {
    final activeBotAsync = ref.watch(activeBotGameProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Play vs Computer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          activeBotAsync.maybeWhen(
            data: (snapshot) {
              if (snapshot == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text('Resume game vs ${snapshot.level.label}'),
                    subtitle: const Text('Continue your unfinished game'),
                    onTap: () => context.push(
                      '/play-bot/game',
                      extra: (
                        config: BotConfig(
                          level: snapshot.level,
                          userSide: snapshot.userSide,
                        ),
                        snapshot: snapshot,
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<BotLevel>(
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v ?? _level),
            child: Column(
              children: [
                for (final level in BotLevel.values)
                  RadioListTile<BotLevel>(
                    title: Text(level.label),
                    subtitle: Text(level.description),
                    value: level,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Your color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<BotColor>(
            groupValue: _color,
            onChanged: (v) => setState(() => _color = v ?? _color),
            child: Column(
              children: [
                for (final color in BotColor.values)
                  RadioListTile<BotColor>(
                    title: Text(_colorLabel(color)),
                    value: color,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _start(activeBotAsync.value != null),
            icon: const Icon(Icons.play_arrow),
            label: Text(activeBotAsync.value != null
                ? 'Start new game (discard current)'
                : 'Start game'),
          ),
        ],
      ),
    );
  }

  String _colorLabel(BotColor c) {
    switch (c) {
      case BotColor.white:
        return 'White';
      case BotColor.black:
        return 'Black';
      case BotColor.random:
        return 'Random';
    }
  }

  Future<void> _start(bool hasActive) async {
    if (hasActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard current game?'),
          content: const Text(
              'You have an unfinished game. Starting a new one will discard it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(botGameRepositoryProvider).clear();
    }
    final side = switch (_color) {
      BotColor.white => Side.white,
      BotColor.black => Side.black,
      BotColor.random => Random().nextBool() ? Side.white : Side.black,
    };
    final config = BotConfig(level: _level, userSide: side);
    if (!mounted) return;
    context.push('/play-bot/game', extra: config);
  }
}
