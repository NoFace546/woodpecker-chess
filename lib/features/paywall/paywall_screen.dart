import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/pro_status.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.headline, this.subhead});

  final String? headline;
  final String? subhead;

  static Future<void> show(
    BuildContext context, {
    String? headline,
    String? subhead,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaywallScreen(headline: headline, subhead: subhead),
      ),
    );
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok =
          await ref.read(proStatusProvider.notifier).buyPro();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Purchase is currently unavailable. Check Play Store setup and try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Purchase failed. Please try again in a moment.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(proStatusProvider.notifier).restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Restoring previous purchases…'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Restore failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss when Pro flips on (e.g. purchase confirmed).
    ref.listen<ProStatus>(proStatusProvider, (prev, next) {
      if (next.isPro && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Welcome to Pro!'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final scheme = Theme.of(context).colorScheme;
    final productAsync = ref.watch(proProductProvider);
    final priceLabel = productAsync.maybeWhen(
      data: (p) => p?.price ?? '149 kr',
      orElse: () => '149 kr',
    );
    final hasStorePrice = productAsync.maybeWhen(
      data: (p) => p != null,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Woodpecker Pro'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _restore,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.headline != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.headline!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          if (widget.subhead != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.subhead!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 8),
          _Feature(
            icon: Icons.psychology_outlined,
            title: 'Recommended training',
            body: 'Get a data-driven 150-puzzle plan built from your '
                'weaknesses, with an adaptive drill / explore mix as your '
                'history grows.',
          ),
          _Feature(
            icon: Icons.collections_bookmark_outlined,
            title: 'Unlimited custom sets',
            body: 'Build, archive and run as many sets as you want, with '
                'access to all tactical themes.',
          ),
          _Feature(
            icon: Icons.insights_outlined,
            title: 'Strengths analysis',
            body: 'See per-theme accuracy, phase radar and speed metrics, '
                'then train your weakest patterns with drill mode.',
          ),
          _Feature(
            icon: Icons.timeline,
            title: 'Full Elo history',
            body: 'Go beyond 30 days and track your rating progress over time.',
          ),
          _Feature(
            icon: Icons.backup_outlined,
            title: 'Backup & restore',
            body: 'Export your full database to share or move to another '
                'device.',
          ),
          _Feature(
            icon: Icons.palette_outlined,
            title: 'All board themes & piece sets',
            body: 'Unlock 23 board themes and all piece sets to personalize '
                'your board style.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer,
                  scheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'One-time purchase',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay once. Yours forever.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _buy,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock Pro'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              hasStorePrice
                  ? 'No subscription. No ads. No tracking.'
                  : 'No subscription. No ads. No tracking. Store price will appear when available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
