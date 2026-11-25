import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';

/// Skeleton placeholder matching the compact KPI strip and 1/2/3-column
/// classroom card grid to prevent layout jumps during initial load.
class DashboardSkeletonView extends StatelessWidget {
  const DashboardSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 4 : 2;
            const spacing = 12.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < 4; i++)
                  SizedBox(
                    width: width,
                    child: const AppSurfaceCard(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SkeletonBox(width: 32, height: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox.line(width: 72, height: 12),
                                SizedBox(height: 8),
                                SkeletonBox.line(width: 56, height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1020
                ? 3
                : (constraints.maxWidth >= 660 ? 2 : 1);
            const spacing = 12.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < columns; i++)
                  SizedBox(
                    width: width,
                    child: const AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox.line(width: 96, height: 16),
                          SizedBox(height: 8),
                          SkeletonBox.line(width: 168, height: 20),
                          SizedBox(height: 12),
                          SkeletonBox(height: 44),
                          SizedBox(height: 12),
                          SkeletonBox(height: 40),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
