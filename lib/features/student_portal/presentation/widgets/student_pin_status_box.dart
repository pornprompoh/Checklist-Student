import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../domain/services/student_pin_validator_service.dart';

/// Displays remaining PIN attempts warning chip, 15-minute live lockout
/// countdown card (with tabular digits), or inline error feedback.
class StudentPinStatusBox extends StatelessWidget {
  const StudentPinStatusBox({
    super.key,
    required this.isSetupMode,
    required this.isLocked,
    required this.now,
    this.remainingAttempts,
    this.lockedUntil,
    this.errorMessage,
  });

  final bool isSetupMode;
  final bool isLocked;
  final DateTime now;
  final int? remainingAttempts;
  final DateTime? lockedUntil;
  final String? errorMessage;

  static const _validator = StudentPinValidatorService();

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (isLocked && lockedUntil != null) {
      final remainingText = _validator.formatLockoutRemainingThai(
        lockedUntil!,
        now: now,
      );
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: semantic.dangerContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: semantic.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_clock_rounded, size: 22, color: semantic.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ระงับการกรอก PIN ชั่วคราว 15 นาที',
                    style: textTheme.titleSmall?.copyWith(
                      color: semantic.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: semantic.danger,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กรอกรหัสผิดครบ 5 ครั้ง หากจำรหัสไม่ได้สามารถแจ้งครูผู้สอนรีเซต PIN ให้ได้ทันที',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isSetupMode &&
            remainingAttempts != null &&
            remainingAttempts! < 5) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: semantic.warningContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: semantic.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: semantic.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เหลือโอกาสอีก $remainingAttempts ครั้งก่อนถูกล็อกชั่วคราว',
                    style: textTheme.labelMedium?.copyWith(
                      color: semantic.warning,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorMessage != null) const SizedBox(height: 10),
        ],
        if (errorMessage != null)
          AppFeedbackBanner(
            type: AppFeedbackType.error,
            message: errorMessage!,
          ),
      ],
    );
  }
}
