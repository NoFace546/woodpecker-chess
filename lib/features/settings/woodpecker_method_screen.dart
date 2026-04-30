import 'package:flutter/material.dart';

class WoodpeckerMethodScreen extends StatelessWidget {
  const WoodpeckerMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('The Woodpecker Method')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'The Woodpecker Method',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'A chess training system by Axel Smith and Hans Tikkanen',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'The idea',
            body:
                'Pick a fixed set of tactical puzzles. Solve the same set, in '
                'changing order, multiple times until you blast through them '
                'on autopilot. Each round should be faster and more accurate '
                'than the last.',
          ),
          _Section(
            title: 'Why it works',
            body:
                'Tactical patterns (forks, pins, mate threats, deflections) '
                'are recognised, not calculated. A 1500-rated player can spot '
                'a familiar mating net instantly while a 2400 needs seconds in '
                'an unfamiliar one. The Woodpecker Method trains exactly this: '
                'pattern recognition through deliberate, spaced repetition.\n\n'
                'Smith and Tikkanen documented their own results in the 2018 '
                'book of the same name: solving the same 1128 puzzles seven '
                'times over a few months, with each pass roughly half the '
                'duration of the previous one.',
          ),
          _Section(
            title: 'How to do it',
            body:
                '1. Pick a set size. Smith recommends 1000 puzzles for serious '
                'training; 50-250 is realistic for a single training cycle in '
                'this app.\n\n'
                '2. Solve the entire set once, no time pressure. This is '
                'round 1.\n\n'
                '3. After a short break, solve the same set again. Round 2.\n\n'
                '4. Repeat. Each round should take less time and produce fewer '
                'mistakes.\n\n'
                '5. After 5-7 rounds, the patterns are burned in.',
          ),
          _Section(
            title: 'In this app',
            bullets: [
              ('New puzzle set',
                  'Build a set with rating range and optional themes.'),
              ('Round',
                  'Start round 1 from the set detail. Each round shuffles the '
                      'order so you train pattern recognition, not "next '
                      'puzzle" memorisation.'),
              ('Progression',
                  'See your speed-up, accuracy curve, and which puzzles '
                      'consistently trip you up.'),
              ('Drill',
                  'Focus on the puzzles that have failed multiple rounds '
                      'before re-running the full set.'),
              ('Recommended training',
                  'Auto-built sets that target the themes you struggle with, '
                      'sized to your data.'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Source',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Axel Smith and Hans Tikkanen, "The Woodpecker Method" '
            '(Quality Chess, 2018).',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    this.body,
    this.bullets,
  });

  final String title;
  final String? body;
  final List<(String, String)>? bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          if (body != null) Text(body!, style: theme.textTheme.bodyMedium),
          if (bullets != null)
            for (final (head, body) in bullets!)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '• $head: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: body),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
