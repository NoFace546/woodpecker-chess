import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/set_repository.dart';

class ArchivedSetsScreen extends ConsumerWidget {
  const ArchivedSetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(archivedSetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived sets')),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sets) {
          if (sets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No archived sets. Archive a set from its detail page to '
                  'tuck it away while keeping its data.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final set in sets)
                Card(
                  child: ListTile(
                    title: Text(set.name),
                    subtitle: Text(
                      '${set.size} puzzles · '
                      '${set.filter.ratingMin}–${set.filter.ratingMax}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/sets/${set.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
