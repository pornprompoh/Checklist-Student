import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton_box.dart';

/// Friendly Thai empty-state card with a primary CTA button for each level
/// of the 4-level academic hierarchy.
class StructureEmptyStateCard extends StatelessWidget {
  const StructureEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading placeholder for the Academic Structure page.
class StructureSkeletonView extends StatelessWidget {
  const StructureSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 48),
                SizedBox(height: 12),
                SkeletonBox.line(width: 220, height: 24),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox.line(width: 180, height: 18),
                SizedBox(height: 12),
                SkeletonBox(height: 56),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
