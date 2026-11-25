import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback_banner.dart';
import '../../domain/entities/resolved_teacher_portal.dart';

/// Step 1 card displaying teacher/school header, optional archived-code
/// redirect notice, and the student-code lookup form.
class StudentCodeLookupCard extends StatefulWidget {
  const StudentCodeLookupCard({
    super.key,
    required this.teacher,
    required this.isBusy,
    this.infoMessage,
    this.errorMessage,
    required this.onSubmitStudentCode,
  });

  final ResolvedTeacherPortal teacher;
  final bool isBusy;
  final String? infoMessage;
  final String? errorMessage;
  final ValueChanged<String> onSubmitStudentCode;

  @override
  State<StudentCodeLookupCard> createState() => _StudentCodeLookupCardState();
}

class _StudentCodeLookupCardState extends State<StudentCodeLookupCard> {
  final _studentCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _studentCodeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isBusy) return;
    widget.onSubmitStudentCode(_studentCodeCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final schoolName = widget.teacher.schoolName?.trim() ?? '';
    final department = widget.teacher.department?.trim() ?? '';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teacher.effectiveTeacherName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (schoolName.isNotEmpty)
                        Text(
                          schoolName,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (department.isNotEmpty)
                        Text(
                          department,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.infoMessage != null) ...[
              const SizedBox(height: 14),
              AppFeedbackBanner(
                type: AppFeedbackType.info,
                message: widget.infoMessage!,
              ),
            ],
            const Divider(height: 28),
            Text(
              'ตรวจสอบเวลาเรียน งานค้าง และผลการเรียน',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'กรอกเลขประจำตัวนักเรียนเพื่อเข้าสู่ระบบด้วยรหัส PIN 6 หลัก (ไม่ต้องสมัครสมาชิก)',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _studentCodeCtrl,
              enabled: !widget.isBusy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'เลขประจำตัวนักเรียน',
                hintText: 'เช่น 67001',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 12),
              AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: widget.errorMessage!,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.isBusy ? null : _submit,
              child: widget.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ถัดไป'),
            ),
          ],
        ),
      ),
    );
  }
}
