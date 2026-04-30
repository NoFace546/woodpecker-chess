import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/paywall/paywall_screen.dart';
import '../services/pro_status.dart';

/// Small "Pro" badge - gold pill with star.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0A82E), Color(0xFFC79324)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: compact ? 10 : 12, color: Colors.white),
          SizedBox(width: compact ? 2 : 3),
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a screen body - shows the child if Pro, otherwise replaces it with
/// a centered "Pro feature" pitch + Unlock button.
class ProGate extends ConsumerWidget {
  const ProGate({
    super.key,
    required this.child,
    required this.featureTitle,
    required this.featureBlurb,
    this.icon = Icons.lock_outline,
  });

  final Widget child;
  final String featureTitle;
  final String featureBlurb;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    if (isPro) return child;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            const ProBadge(),
            const SizedBox(height: 12),
            Text(
              featureTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              featureBlurb,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => PaywallScreen.show(
                context,
                headline: featureTitle,
                subhead: featureBlurb,
              ),
              icon: const Icon(Icons.star),
              label: const Text('Unlock Pro'),
            ),
          ],
        ),
      ),
    );
  }
}
