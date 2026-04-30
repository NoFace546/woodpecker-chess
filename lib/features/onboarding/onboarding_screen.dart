import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_state_repository.dart';
import '../../services/app_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  int _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardedProvider.notifier).markComplete();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickLevel(_Level level) async {
    await ref
        .read(userStateRepositoryProvider)
        .resetEloAndAttempts(elo: level.elo);
    // Advance to the final slide.
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    final pages = <Widget>[
      const _IntroSlide(
        icon: Icons.repeat,
        title: 'The Woodpecker Method',
        body:
            'Solve the same set of tactical puzzles in repeated rounds. '
            'Pattern recognition gets faster every time you go through them.',
      ),
      _LevelPickerSlide(onPick: _pickLevel),
      const _IntroSlide(
        icon: Icons.fitness_center,
        title: 'Build a set, drill it 5-7 rounds',
        body:
            'Tap New puzzle set and pick Recommended. Drill the same set '
            'across rounds, speeding up while keeping accuracy. When '
            'mastered, archive it and build the next.',
      ),
    ];
    _pageCount = pages.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _page == i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Level {
  const _Level({
    required this.label,
    required this.subtitle,
    required this.elo,
  });
  final String label;
  final String subtitle;
  final int elo;
}

const _levels = [
  _Level(
    label: 'Beginner',
    subtitle: 'New to chess or just learning tactics',
    elo: 800,
  ),
  _Level(
    label: 'Casual',
    subtitle: 'I play occasionally and know basic patterns',
    elo: 1200,
  ),
  _Level(
    label: 'Intermediate',
    subtitle: 'I play regularly, comfortable with forks and pins',
    elo: 1500,
  ),
  _Level(
    label: 'Advanced',
    subtitle: 'Club player level, calculate several moves ahead',
    elo: 1800,
  ),
  _Level(
    label: 'Expert',
    subtitle: 'Tournament-rated near master level',
    elo: 2100,
  ),
];

class _LevelPickerSlide extends StatelessWidget {
  const _LevelPickerSlide({required this.onPick});
  final Future<void> Function(_Level) onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Icon(
          Icons.auto_graph,
          size: 56,
          color: scheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'What\'s your level?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a starting point so the recommended training fits you '
          'right away. You can change it any time in Settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        for (final level in _levels) ...[
          _LevelCard(level: level, onTap: () => onPick(level)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onTap});
  final _Level level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${level.elo}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
