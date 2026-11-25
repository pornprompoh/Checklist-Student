import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';

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

    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เข้าสู่พอร์ทัลตรวจสอบผลการเรียน',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'กรอกรหัสครูผู้สอนที่ได้รับจากลิงก์ในกลุ่มเรียน (เช่น t-8492)',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    );
  }
}
