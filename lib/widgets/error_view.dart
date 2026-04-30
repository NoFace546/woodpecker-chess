import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Themed error view for AsyncValue.error branches. Hides raw exception
/// strings from users while letting callers surface a friendly message and
/// optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.body,
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String? body;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.error_outline,
        title: title,
        body: body ?? 'Please try again in a moment.',
        compact: compact,
        action: onRetry == null
            ? null
            : OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
      ),
    );
  }
}
