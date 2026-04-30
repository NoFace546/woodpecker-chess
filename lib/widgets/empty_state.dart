import 'package:flutter/material.dart';

/// A consistent empty-state widget - soft icon + bold title + body line.
/// Use anywhere a screen would otherwise show a single line of plain text.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.padding = const EdgeInsets.all(24),
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 10 : 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: compact ? 24 : 32,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}
