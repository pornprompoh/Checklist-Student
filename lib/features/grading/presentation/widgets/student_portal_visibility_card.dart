import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_portal_visibility_config.dart';

/// Teacher-facing toggle card controlling server-side Student Portal masking
/// (`show_score_to_student` & `show_grade_to_student`) for one subject class.
class StudentPortalVisibilityCard extends StatelessWidget {
  const StudentPortalVisibilityCard({
    super.key,
    required this.config,
    required this.isBusy,
    required this.onToggleShowScore,
    required this.onToggleShowGrade,
  });

  final StudentPortalVisibilityConfig config;
  final bool isBusy;
  final ValueChanged<bool> onToggleShowScore;
  final ValueChanged<bool> onToggleShowGrade;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return AppSurfaceCard(
      title: 'การเปิดเผยข้อมูลบน Student Portal',
      subtitle:
          'ควบคุมการมองเห็นเฉพาะวิชานี้และห้องนี้แยกอิสระ (ซ่อนตั้งแต่ระดับเซิร์ฟเวอร์)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('เปิดเผยคะแนนให้นักเรียนเห็น'),
            subtitle: Text(
              'หากปิด นักเรียนยังเห็นสถานะส่งงานและเวลาเรียน แต่คะแนนทุกชิ้นและคะแนนรวมจะถูกซ่อนตั้งแต่ระดับเซิร์ฟเวอร์',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: config.showScoreToStudent,
            onChanged: isBusy ? null : onToggleShowScore,
          ),
          const Divider(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('เปิดเผยเกรดให้นักเรียนเห็น'),
            subtitle: Text(
              'หากปิด เกรดและสถานะเกรดพิเศษจะถูกซ่อนตั้งแต่ระดับเซิร์ฟเวอร์จนกว่าครูจะเปิดเผย',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: config.showGradeToStudent,
            onChanged: isBusy ? null : onToggleShowGrade,
          ),
          if (!config.showScoreToStudent || !config.showGradeToStudent) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: semantic.warningContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                !config.showScoreToStudent && !config.showGradeToStudent
                    ? 'ขณะนี้ซ่อนทั้งคะแนนและเกรดบน Student Portal ของห้องนี้'
                    : (!config.showScoreToStudent
                          ? 'ขณะนี้ซ่อนคะแนน (แสดงเฉพาะเกรด เวลาเรียน และสถานะส่งงาน)'
                          : 'ขณะนี้ซ่อนเกรด (แสดงเฉพาะคะแนน เวลาเรียน และสถานะส่งงาน)'),
                style: textTheme.labelSmall?.copyWith(
                  color: semantic.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
