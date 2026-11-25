import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/in_app_browser_detector.dart';
import '../../../../core/widgets/app_feedback_banner.dart';

/// Prompts students opening the portal inside LINE / Facebook / Instagram
/// in-app browsers to switch to Chrome or Safari using `?openExternalBrowser=1`.
class LineBrowserRedirectBanner extends StatelessWidget {
  const LineBrowserRedirectBanner({
    super.key,
    this.browserInfoOverride,
    this.forceVisibleForTest = false,
    this.onOpenExternal,
  });

  final InAppBrowserInfo? browserInfoOverride;
  final bool forceVisibleForTest;
  final ValueChanged<String>? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final detected = browserInfoOverride ?? detectInAppBrowser();
    final shouldShow = forceVisibleForTest || detected.isInAppBrowser;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final appName = detected.appLabel ?? 'แอปแชท';
    final externalUrl = detected.externalBrowserUrl.isNotEmpty
        ? detected.externalBrowserUrl
        : buildExternalBrowserUrl(
            detected.currentUrl.isNotEmpty
                ? detected.currentUrl
                : 'https://checklist-student.app/student',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantic.warningContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: semantic.warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.open_in_browser_rounded,
                size: 20,
                color: semantic.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'กำลังเปิดผ่านเบราว์เซอร์ภายใน $appName',
                      style: textTheme.titleSmall?.copyWith(
                        color: semantic.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'แนะนำให้เปิดใน Chrome หรือ Safari เพื่อให้แสดงผลและใช้งานได้เสถียรที่สุด',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () {
                  if (onOpenExternal != null) {
                    onOpenExternal!(externalUrl);
                  } else {
                    openExternalBrowserUrl(externalUrl);
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.launch_rounded, size: 17),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'เปิดในเบราว์เซอร์หลัก',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: externalUrl));
                  if (!context.mounted) return;
                  AppFeedbackBanner.showSnackBar(
                    context,
                    type: AppFeedbackType.success,
                    message: 'คัดลอกลิงก์สำหรับเปิดในเบราว์เซอร์เรียบร้อยแล้ว',
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'คัดลอกลิงก์',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
