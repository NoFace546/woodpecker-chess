import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData
              ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
              : '…';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Woodpecker',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Version $version',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A Woodpecker Method chess trainer for solving puzzles in '
                'repeating sets to build pattern recognition.',
              ),
              const SizedBox(height: 24),
              Text(
                'Credits',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const _CreditRow(
                title: 'Puzzle database',
                source: 'Lichess (CC0)',
                url: 'database.lichess.org',
              ),
              const _CreditRow(
                title: 'Engine',
                source: 'Stockfish (GPL-3.0)',
                url: 'stockfishchess.org',
              ),
              const _CreditRow(
                title: 'Engine bindings',
                source: 'multistockfish (Lichess, GPL-3.0)',
                url: 'pub.dev/packages/multistockfish',
              ),
              const _CreditRow(
                title: 'Chessboard UI',
                source: 'chessground (Lichess, GPL-3.0)',
                url: 'pub.dev/packages/chessground',
              ),
              const _CreditRow(
                title: 'Move logic',
                source: 'dartchess (Lichess, GPL-3.0)',
                url: 'pub.dev/packages/dartchess',
              ),
              const SizedBox(height: 24),
              Text(
                'License',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Because Woodpecker bundles GPL-3.0 components, the app as '
                'distributed is GPL-3.0. Source available on request.',
              ),
              const SizedBox(height: 24),
              Text(
                'Privacy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'All data is stored locally on your device. No analytics, '
                'no telemetry, no servers. Backups you create are saved to '
                'wherever you choose to share them.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.title,
    required this.source,
    required this.url,
  });
  final String title;
  final String source;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(source),
          Text(
            url,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
