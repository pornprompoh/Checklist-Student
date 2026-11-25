import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
    return AppEmptyState(
      icon: icon,
      title: title,
      description: subtitle,
      actionLabel: actionLabel,
      actionIcon: Icons.add_rounded,
      onAction: onAction,
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
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 48),
              SizedBox(height: 12),
              SkeletonBox.line(width: 220, height: 24),
            ],
          ),
        ),
        SizedBox(height: 16),
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox.line(width: 180, height: 18),
              SizedBox(height: 12),
              SkeletonBox(height: 56),
            ],
          ),
        ),
      ],
    );
  }
}
