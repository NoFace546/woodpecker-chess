import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show PieceKind;
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
import '../../services/board_appearance.dart';
import '../../services/pro_status.dart';
import '../../services/reset_service.dart';
import '../../widgets/pro_lock.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    final muted = ref.watch(mutedProvider);
    final themeMode = ref.watch(themeModeProvider);
    final autoAdvance = ref.watch(autoAdvanceProvider);
    final boardTheme = ref.watch(boardThemeProvider);
    final pieceSet = ref.watch(pieceSetProvider);
    final showCoordinates = ref.watch(showCoordinatesProvider);
    final showLegalMoves = ref.watch(showLegalMovesProvider);
    final animationSpeed = ref.watch(animationSpeedProvider);
    final confetti = ref.watch(confettiEnabledProvider);
    final autoFlip = ref.watch(autoFlipBoardProvider);
    final hintsEnabled = ref.watch(hintsEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Account'),
          _ProStatusTile(),
          const Divider(),
          _SectionHeader(title: 'Puzzles'),
          SwitchListTile(
            title: const Text('Auto-advance after correct'),
            subtitle: const Text(
                'Automatically load the next puzzle after a clean solve'),
            value: autoAdvance,
            onChanged: (v) => ref.read(autoAdvanceProvider.notifier).set(v),
          ),
          SwitchListTile(
            title: const Text('Show hint button'),
            subtitle:
                const Text('Disable to train without hints'),
            value: hintsEnabled,
            onChanged: (v) =>
                ref.read(hintsEnabledProvider.notifier).set(v),
          ),
          SwitchListTile(
            title: const Text('Confetti on big wins'),
            subtitle: const Text(
                'Celebrate rounds with 85%+ accuracy'),
            value: confetti,
            onChanged: (v) =>
                ref.read(confettiEnabledProvider.notifier).set(v),
          ),
          const Divider(),
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
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: Row(
              children: [
                const Text('Board theme'),
                if (!isPro) ...[
                  const SizedBox(width: 8),
                  const ProBadge(compact: true),
                ],
              ],
            ),
            subtitle: Text(boardTheme.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickBoardTheme(context, ref, boardTheme, isPro),
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: Row(
              children: [
                const Text('Piece set'),
                if (!isPro) ...[
                  const SizedBox(width: 8),
                  const ProBadge(compact: true),
                ],
              ],
            ),
            subtitle: Text(pieceSet.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickPieceSet(context, ref, pieceSet, isPro),
          ),
          SwitchListTile(
            title: const Text('Show coordinates'),
            subtitle: const Text('a-h and 1-8 along the edge'),
            value: showCoordinates,
            onChanged: (v) =>
                ref.read(showCoordinatesProvider.notifier).set(v),
          ),
          SwitchListTile(
            title: const Text('Show legal moves'),
            subtitle: const Text(
                'Dots on squares where the picked-up piece can go'),
            value: showLegalMoves,
            onChanged: (v) =>
                ref.read(showLegalMovesProvider.notifier).set(v),
          ),
          SwitchListTile(
            title: const Text('Auto-flip board'),
            subtitle: const Text(
                'Show black at the bottom when you play black'),
            value: autoFlip,
            onChanged: (v) =>
                ref.read(autoFlipBoardProvider.notifier).set(v),
          ),
          ListTile(
            leading: const Icon(Icons.animation),
            title: const Text('Animation speed'),
            subtitle: Text(animationSpeed.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickAnimationSpeed(context, ref, animationSpeed),
          ),
          const Divider(),
          _SectionHeader(title: 'Profile'),
          ListTile(
            leading: const Icon(Icons.auto_graph),
            title: const Text('Recalibrate level'),
            subtitle: const Text(
                'Reset your Elo and attempt history. Pick a starting level.'),
            onTap: () => _recalibrateLevel(context, ref),
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
            title: Row(
              children: [
                const Text('Export data'),
                if (!isPro) ...[
                  const SizedBox(width: 8),
                  const ProBadge(compact: true),
                ],
              ],
            ),
            subtitle:
                const Text('Save a backup file you can share or restore'),
            onTap: () => isPro
                ? _exportData(context, ref)
                : PaywallScreen.show(
                    context,
                    headline: 'Backup is a Pro feature',
                    subhead:
                        'Export and import your full database to share '
                        'or move to another device.',
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Row(
              children: [
                const Text('Import data'),
                if (!isPro) ...[
                  const SizedBox(width: 8),
                  const ProBadge(compact: true),
                ],
              ],
            ),
            subtitle:
                const Text('Replace all data with a previous backup'),
            onTap: () => isPro
                ? _importData(context, ref)
                : PaywallScreen.show(
                    context,
                    headline: 'Backup is a Pro feature',
                    subhead:
                        'Export and import your full database to share '
                        'or move to another device.',
                  ),
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open your email app. Please try again.'),
        ),
      );
    }
  }

  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  Future<void> _recalibrateLevel(
      BuildContext context, WidgetRef ref) async {
    const levels = [
      _LevelChoice('Beginner',
          'New to chess or just learning tactics', 800),
      _LevelChoice('Casual',
          'I play occasionally and know basic patterns', 1200),
      _LevelChoice('Intermediate',
          'I play regularly, comfortable with forks and pins', 1500),
      _LevelChoice('Advanced',
          'Club player level, calculate several moves ahead', 1800),
      _LevelChoice('Expert',
          'Tournament-rated near master level', 2100),
    ];
    final picked = await showModalBottomSheet<_LevelChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Pick your level',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Your Elo and attempt history will be reset.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            for (final l in levels)
              Card(
                child: ListTile(
                  title: Text('${l.label} · Elo ${l.elo}'),
                  subtitle: Text(l.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, l),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    await ref
        .read(userStateRepositoryProvider)
        .resetEloAndAttempts(elo: picked.elo);
    ref.invalidate(eloHistoryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Elo set to ${picked.elo} (${picked.label}).')),
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not reset progress. Please try again.'),
        ),
      );
    }
  }

  Future<void> _pickAnimationSpeed(
      BuildContext context, WidgetRef ref, AnimationSpeed current) async {
    final picked = await showModalBottomSheet<AnimationSpeed>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in AnimationSpeed.values)
              ListTile(
                title: Text(s.label),
                trailing: s == current
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(animationSpeedProvider.notifier).set(picked);
    }
  }

  Future<void> _pickBoardTheme(
      BuildContext context, WidgetRef ref, BoardTheme current, bool isPro) async {
    final pieceSet = ref.read(pieceSetProvider);
    final picked = await showModalBottomSheet<BoardTheme>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in BoardTheme.values)
              ListTile(
                leading: _BoardSwatch(theme: t, pieceSet: pieceSet),
                title: Text(t.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPro && !t.isFree)
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    if (t == current) ...[
                      if (!isPro && !t.isFree) const SizedBox(width: 8),
                      const Icon(Icons.check, color: Colors.green),
                    ],
                  ],
                ),
                onTap: () {
                  if (isPro || t.isFree) {
                    Navigator.pop(ctx, t);
                    return;
                  }
                  Navigator.pop(ctx);
                  PaywallScreen.show(
                    context,
                    headline: 'Board themes are a Pro feature',
                    subhead:
                        'Unlock all board themes and piece sets to customize your board.',
                  );
                },
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(boardThemeProvider.notifier).set(picked);
    }
  }

  Future<void> _pickPieceSet(
      BuildContext context, WidgetRef ref, PieceSet current, bool isPro) async {
    final boardTheme = ref.read(boardThemeProvider);
    final picked = await showModalBottomSheet<PieceSet>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final ps in PieceSet.values)
              ListTile(
                leading: _PieceSetSwatch(pieceSet: ps, theme: boardTheme),
                title: Text(ps.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPro && ps != PieceSet.cburnett)
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    if (ps == current) ...[
                      if (!isPro && ps != PieceSet.cburnett)
                        const SizedBox(width: 8),
                      const Icon(Icons.check, color: Colors.green),
                    ],
                  ],
                ),
                onTap: () {
                  if (isPro || ps == PieceSet.cburnett) {
                    Navigator.pop(ctx, ps);
                    return;
                  }
                  Navigator.pop(ctx);
                  PaywallScreen.show(
                    context,
                    headline: 'Board themes are a Pro feature',
                    subhead:
                        'Unlock all board themes and piece sets to customize your board.',
                  );
                },
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(pieceSetProvider.notifier).set(picked);
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Share backup'),
              subtitle: const Text(
                  'Open the system share sheet (email, cloud drive, etc.)'),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save to device'),
              subtitle:
                  const Text('Pick a folder on this phone to copy the file to'),
              onTap: () => Navigator.pop(ctx, 'save'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref.read(backupServiceProvider).stageExport();
      if (choice == 'share') {
        await SharePlus.instance.share(
          ShareParams(files: [file], subject: 'Woodpecker backup'),
        );
      } else {
        final bytes = await File(file.path).readAsBytes();
        final destPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Woodpecker backup',
          fileName: file.name,
          bytes: bytes,
        );
        if (!context.mounted) return;
        if (destPath != null) {
          messenger.showSnackBar(SnackBar(
            content: Text('Saved to $destPath'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Export failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Import failed. Please verify the file and try again.'),
        ),
      );
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

/// Mini 2x2 board with a king on it, showing what the theme + piece set
/// look like together.
class _BoardSwatch extends StatelessWidget {
  const _BoardSwatch({required this.theme, required this.pieceSet});
  final BoardTheme theme;
  final PieceSet pieceSet;

  @override
  Widget build(BuildContext context) {
    final c = theme.colors;
    final whiteKing = pieceSet.assets[PieceKind.whiteKing];
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    _Square(color: c.lightSquare),
                    _Square(color: c.darkSquare),
                  ],
                ),
                Row(
                  children: [
                    _Square(color: c.darkSquare),
                    _Square(color: c.lightSquare),
                  ],
                ),
              ],
            ),
            if (whiteKing != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image(image: whiteKing, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 24, height: 24, child: ColoredBox(color: color));
  }
}

/// Two pieces side by side (white king + black knight) on neutral squares,
/// showing what the piece set looks like.
class _PieceSetSwatch extends StatelessWidget {
  const _PieceSetSwatch({required this.pieceSet, required this.theme});
  final PieceSet pieceSet;
  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    final whiteKing = pieceSet.assets[PieceKind.whiteKing];
    final blackKnight = pieceSet.assets[PieceKind.blackKnight];
    return SizedBox(
      width: 64,
      height: 32,
      child: Row(
        children: [
          _PieceTile(
            background: theme.colors.lightSquare,
            asset: whiteKing,
          ),
          _PieceTile(
            background: theme.colors.darkSquare,
            asset: blackKnight,
          ),
        ],
      ),
    );
  }
}

class _PieceTile extends StatelessWidget {
  const _PieceTile({required this.background, required this.asset});
  final Color background;
  final AssetImage? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      color: background,
      padding: const EdgeInsets.all(2),
      child: asset == null ? null : Image(image: asset!, fit: BoxFit.contain),
    );
  }
}

class _LevelChoice {
  const _LevelChoice(this.label, this.subtitle, this.elo);
  final String label;
  final String subtitle;
  final int elo;
}

class _ProStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(proStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    if (status.isPro) {
      String label;
      switch (status.source) {
        case ProSource.paid:
          label = 'Active · purchased';
        case ProSource.grandfathered:
          label = 'Active · early supporter';
        case ProSource.debugBuild:
          label = 'Active · debug build';
        case ProSource.locked:
          label = 'Active';
      }
      return ListTile(
        leading: Icon(Icons.workspace_premium, color: scheme.primary),
        title: const Row(
          children: [
            Text('Woodpecker Pro'),
            SizedBox(width: 8),
            ProBadge(compact: true),
          ],
        ),
        subtitle: Text(label),
      );
    }
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.star_outline, color: scheme.primary),
          title: const Text('Unlock Woodpecker Pro'),
          subtitle: const Text(
              'One-time purchase. All features, forever.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => PaywallScreen.show(context),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Restore purchase'),
          subtitle: const Text(
              'If you bought Pro on another device or reinstalled'),
          onTap: () async {
            try {
              await ref.read(proStatusProvider.notifier).restore();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Restoring previous purchases…'),
                behavior: SnackBarBehavior.floating,
              ));
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Restore failed. Please try again.'),
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
      ],
    );
  }
}
