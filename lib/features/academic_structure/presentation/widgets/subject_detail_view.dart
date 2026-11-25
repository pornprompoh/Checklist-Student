import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import 'subject_class_tile.dart';

/// In-page drill-down detail view for one selected [Subject], showing a back
/// breadcrumb, subject actions, and all [SubjectClass] rooms with quick links.
class SubjectDetailView extends StatelessWidget {
  const SubjectDetailView({
    super.key,
    required this.subject,
    required this.classes,
    required this.isBusy,
    required this.onBack,
    required this.onEditSubject,
    required this.onDeleteSubject,
    required this.onAddClass,
    required this.onTogglePinClass,
    required this.onEditClass,
    required this.onDeleteClass,
    this.onOpenAttendance,
    this.onOpenGrading,
    this.onOpenGradingPlan,
  });

  final Subject subject;
  final List<SubjectClass> classes;
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback onEditSubject;
  final VoidCallback onDeleteSubject;
  final VoidCallback onAddClass;
  final ValueChanged<SubjectClass> onTogglePinClass;
  final ValueChanged<SubjectClass> onEditClass;
  final ValueChanged<SubjectClass> onDeleteClass;
  final ValueChanged<SubjectClass>? onOpenAttendance;
  final ValueChanged<SubjectClass>? onOpenGrading;
  final ValueChanged<SubjectClass>? onOpenGradingPlan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('กลับไปรายวิชาทั้งหมด'),
          ),
        ),
        const SizedBox(height: 8),
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subject.subjectCode,
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ),
                          Text(
                            '${classes.length} ห้องเรียน',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subject.subjectName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: isBusy ? null : onAddClass,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('เพิ่มห้องเรียน'),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'จัดการรายวิชา',
                        enabled: !isBusy,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') onEditSubject();
                          if (value == 'delete') onDeleteSubject();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined, size: 18),
                              title: Text('แก้ไขรายวิชา'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: semantic.danger,
                              ),
                              title: Text(
                                'ลบรายวิชา',
                                style: TextStyle(color: semantic.danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (classes.isEmpty)
                AppEmptyState(
                  framed: false,
                  icon: Icons.class_outlined,
                  title: 'ยังไม่มีห้องเรียนในรายวิชานี้',
                  description:
                      'เพิ่มห้องเรียนพร้อมกำหนดวันสอน เพื่อเริ่มเช็คชื่อและเก็บคะแนนได้ทันที',
                  actionLabel: 'เพิ่มห้องเรียนแรก',
                  actionIcon: Icons.add_rounded,
                  onAction: onAddClass,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < classes.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outlineVariant,
                          ),
                        SubjectClassTile(
                          subjectClass: classes[i],
                          isBusy: isBusy,
                          onTogglePin: () => onTogglePinClass(classes[i]),
                          onEdit: () => onEditClass(classes[i]),
                          onDelete: () => onDeleteClass(classes[i]),
                          onOpenAttendance: onOpenAttendance == null
                              ? null
                              : () => onOpenAttendance!(classes[i]),
                          onOpenGrading: onOpenGrading == null
                              ? null
                              : () => onOpenGrading!(classes[i]),
                          onOpenGradingPlan: onOpenGradingPlan == null
                              ? null
                              : () => onOpenGradingPlan!(classes[i]),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
