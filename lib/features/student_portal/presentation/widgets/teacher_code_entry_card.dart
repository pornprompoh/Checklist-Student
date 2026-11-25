import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback_banner.dart';

/// Fallback card for `/student` when no teacher code is provided in the URL
/// or when the supplied code was not found.
class TeacherCodeEntryCard extends StatelessWidget {
  const TeacherCodeEntryCard({
    super.key,
    required this.controller,
    required this.isBusy,
    required this.onSubmit,
    this.errorMessage,
  });

  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'เข้าสู่พอร์ทัลตรวจสอบผลการเรียน',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'กรอกรหัสครูผู้สอนที่ได้รับจากลิงก์ในกลุ่มเรียน (เช่น t-8492)',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              enabled: !isBusy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                labelText: 'รหัสครูผู้สอน',
                hintText: 'เช่น t-8492',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: errorMessage!,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isBusy ? null : onSubmit,
              child: const Text('เปิดหน้าตรวจสอบคะแนน'),
            ),
          ],
        ),
      ),
    );
  }
}
