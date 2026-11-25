import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_portal_summary.dart';
import 'student_portal_class_card.dart';

/// Authenticated student dashboard view with student identity header,
/// term switcher, refresh/sign-out controls, and per-class cards.
class StudentPortalSummaryView extends StatelessWidget {
  const StudentPortalSummaryView({
    super.key,
    required this.summary,
    required this.isBusy,
    required this.onSelectTerm,
    required this.onRefresh,
    required this.onSignOut,
  });

  final StudentPortalSummary summary;
  final bool isBusy;
  final ValueChanged<String> onSelectTerm;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final student = summary.student;
    final teacher = summary.teacher;
    final validTermId =
        summary.availableTerms.any((t) => t.termId == summary.selectedTermId)
        ? summary.selectedTermId
        : (summary.availableTerms.isNotEmpty
              ? summary.availableTerms.first.termId
              : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student?.fullName.isNotEmpty == true
                                  ? student!.fullName
                                  : 'นักเรียนรหัส ${student?.studentCode ?? ''}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'รหัสนักเรียน ${student?.studentCode ?? '-'}'
                              '${teacher != null ? ' · ${teacher.effectiveTeacherName}' : ''}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            if (teacher?.schoolName != null &&
                                teacher!.schoolName!.trim().isNotEmpty)
                              Text(
                                teacher.schoolName!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isBusy ? null : onRefresh,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('รีเฟรช'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: isBusy ? null : onSignOut,
                        icon: const Icon(Icons.logout_rounded, size: 17),
                        label: const Text('ออกจากระบบ'),
                      ),
                    ],
                  ),
                ],
              ),
              if (summary.availableTerms.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String?>(validTermId),
                  initialValue: validTermId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ภาคเรียน / ปีการศึกษา (พ.ศ.)',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    isDense: true,
                  ),
                  items: [
                    for (final term in summary.availableTerms)
                      DropdownMenuItem<String>(
                        value: term.termId,
                        child: Text(
                          '${term.displayLabel}${term.isPinnedActive ? ' (ปัจจุบัน)' : ''}',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ),
                  ],
                  onChanged: isBusy
                      ? null
                      : (id) {
                          if (id != null && id != validTermId) {
                            onSelectTerm(id);
                          }
                        },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (summary.classes.isEmpty)
          const AppEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'ยังไม่พบรายวิชาในภาคเรียนที่เลือก',
            description:
                'หากลงทะเบียนเรียนในภาคเรียนอื่น สามารถเลือกเปลี่ยนภาคเรียนจากเมนูด้านบนได้',
          )
        else
          for (var i = 0; i < summary.classes.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            StudentPortalClassCard(detail: summary.classes[i]),
          ],
      ],
    );
  }
}
