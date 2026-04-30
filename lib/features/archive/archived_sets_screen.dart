import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/set_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';

class ArchivedSetsScreen extends ConsumerWidget {
  const ArchivedSetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(archivedSetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived sets')),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorView(),
        data: (sets) {
          if (sets.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.archive_outlined,
                title: 'No archived sets',
                body: 'Archive a set from its detail page to tuck it away '
                    'while keeping its data.',
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
                      '${set.filter.ratingMin}-${set.filter.ratingMax}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) =>
                          _handleAction(context, ref, set.id, set.name, action),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'restore',
                          child: ListTile(
                            leading: Icon(Icons.unarchive_outlined),
                            title: Text('Restore'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: Text('Delete forever'),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/sets/${set.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String setId,
    String name,
    String action,
  ) async {
    final repo = ref.read(setRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (action == 'restore') {
      await repo.unarchive(setId);
      ref.invalidate(archivedSetsProvider);
      ref.invalidate(allSetsProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('Restored "$name"'),
        behavior: SnackBarBehavior.floating,
      ));
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete forever?'),
          content: Text(
              'Permanently delete "$name" and all its rounds and attempts.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await repo.delete(setId);
      ref.invalidate(archivedSetsProvider);
      ref.invalidate(allSetsProvider);
      messenger.showSnackBar(const SnackBar(
        content: Text('Set deleted'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
