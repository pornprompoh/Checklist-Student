import 'package:flutter/material.dart';

import 'app_surface_card.dart';

/// Standard empty state: soft-tinted icon circle, clear heading, short
/// description and at most one primary call-to-action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.framed = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Wraps the content inside an [AppSurfaceCard] when `true`.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasAction = actionLabel != null && onAction != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasAction) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    actionLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!framed) {
      return content;
    }
    return AppSurfaceCard(child: content);
  }
}
