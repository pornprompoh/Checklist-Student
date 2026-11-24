import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton_box.dart';

/// Skeleton placeholder shown while Teacher Dashboard metrics and class cards
/// are loading (prevents blank white flashes).
class DashboardSkeletonView extends StatelessWidget {
  const DashboardSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            const spacing = 10.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < 4; i++)
                  SizedBox(
                    width: width,
                    child: const Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 34, height: 34),
                            SizedBox(height: 10),
                            SkeletonBox.line(width: 84, height: 18),
                            SizedBox(height: 6),
                            SkeletonBox.line(width: 110, height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 2; i++) ...[
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox.line(width: 120, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox.line(width: 180, height: 18),
                  SizedBox(height: 14),
                  SkeletonBox(height: 40),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
