import 'package:flutter/material.dart';

import 'app_feedback_banner.dart';

/// Global shell banners rendered above every Teacher page: the Offline
/// warning and the Sync Conflict alert (hidden on the Sync Queue page).
class AppShellBanners extends StatelessWidget {
  const AppShellBanners({
    super.key,
    required this.isOffline,
    required this.showConflictBanner,
    required this.conflictCount,
    required this.onReviewConflicts,
  });

  final bool isOffline;
  final bool showConflictBanner;
  final int conflictCount;
  final VoidCallback onReviewConflicts;

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !showConflictBanner) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOffline)
            const AppFeedbackBanner(
              type: AppFeedbackType.warning,
              message:
                  'ขณะนี้อยู่ในโหมดออฟไลน์ การเชื่อมต่ออินเทอร์เน็ตขาดหายชั่วคราว',
            ),
          if (isOffline && showConflictBanner) const SizedBox(height: 10),
          if (showConflictBanner)
            AppFeedbackBanner(
              type: AppFeedbackType.error,
              message:
                  'พบข้อมูลชนกัน $conflictCount รายการจากการทำงานออฟไลน์',
              retryLabel: 'ตรวจสอบ',
              onRetry: onReviewConflicts,
            ),
        ],
      ),
    );
  }
}
