import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/set_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/app_preferences.dart';
import '../../services/backup_service.dart';
import '../../services/reset_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(mutedProvider);
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Sound'),
          SwitchListTile(
            title: const Text('Mute sounds'),
            subtitle: const Text(
                'Stop puzzle move and feedback sounds'),
            value: muted,
            onChanged: (v) => ref.read(mutedProvider.notifier).set(v),
          ),
          const Divider(),
          _SectionHeader(title: 'Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).set(v);
              }
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('System default'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.auto_graph),
            title: const Text('Reset Elo to 1500'),
            subtitle: const Text(
                'Solve random puzzles to find your level again'),
            onTap: () => _confirmResetElo(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset all progress'),
            subtitle: const Text(
                'Delete sets, rounds, attempts, and Elo history'),
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: 'Backup'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export data'),
            subtitle:
                const Text('Save a backup file you can share or restore'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import data'),
            subtitle:
                const Text('Replace all data with a previous backup'),
            onTap: () => _importData(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: 'Feedback'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a bug'),
            subtitle:
                const Text('Opens email with version + device info'),
            onTap: () => _reportBug(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('About the Woodpecker Method'),
            subtitle: const Text('How this training system works'),
            onTap: () => context.push('/method'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Woodpecker'),
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportBug(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pkg = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      String deviceLine = 'Device: unknown';
      String osLine = 'OS: unknown';
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceLine = 'Device: ${info.manufacturer} ${info.model}';
        osLine = 'OS: Android ${info.version.release} (API ${info.version.sdkInt})';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceLine = 'Device: ${info.model}';
        osLine = 'OS: iOS ${info.systemVersion}';
      }
      final body = '''
[Auto-generated]
App version: ${pkg.version}+${pkg.buildNumber}
$deviceLine
$osLine

[Please describe the bug]
What happened:

What you expected:

Steps to reproduce:
''';
      final uri = Uri(
        scheme: 'mailto',
        path: 'sebiosjed@gmail.com',
        query: _encodeQuery({
          'subject': 'Woodpecker bug report',
          'body': body,
        }),
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  Future<void> _confirmResetElo(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Elo to 1500?'),
        content: const Text(
          'Your current Elo will be reset to 1500. Solve random puzzles '
          'to find your level again — your Elo adjusts per puzzle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await ref
        .read(userStateRepositoryProvider)
        .resetEloAndAttempts(elo: 1500);
    ref.invalidate(eloHistoryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Elo reset to 1500.')),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This will permanently delete:\n'
          '• All puzzle sets and rounds\n'
          '• All attempt history\n'
          '• Your Elo and calibration\n\n'
          'The puzzle library is unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(resetServiceProvider).resetUserData();
      ref.invalidate(allSetsProvider);
      ref.invalidate(archivedSetsProvider);
      ref.invalidate(eloHistoryProvider);
      ref.invalidate(weaknessAnalysisProvider);
      ref.invalidate(globalThemeStatsProvider);
      ref.invalidate(enrichedThemeStatsProvider);
      ref.invalidate(phaseStatsProvider);
      ref.invalidate(globalStatsProvider);
      ref.invalidate(setActivitiesProvider);
      ref.invalidate(dailyActivityProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('All progress reset.')),
      );
      context.go('/');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref.read(backupServiceProvider).stageExport();
      await SharePlus.instance.share(
        ShareParams(files: [file], subject: 'Woodpecker backup'),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) return;
    final pickedPath = picked.files.first.path;
    if (pickedPath == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
          'This will replace your current sets, rounds, attempts, and Elo '
          'with the contents of the backup. The current data cannot be '
          'recovered after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupServiceProvider).importFrom(File(pickedPath));
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup restored.')),
      );
      context.go('/');
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
