import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import 'subject_class_tile.dart';

/// Card rendering one [Subject] and its unified list of [SubjectClass] rooms.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.classes,
    required this.isBusy,
    required this.onEditSubject,
    required this.onDeleteSubject,
    required this.onAddClass,
    required this.onTogglePinClass,
    required this.onEditClass,
    required this.onDeleteClass,
    this.onOpenAttendance,
    this.onOpenGrading,
  });

  final Subject subject;
  final List<SubjectClass> classes;
  final bool isBusy;
  final VoidCallback onEditSubject;
  final VoidCallback onDeleteSubject;
  final VoidCallback onAddClass;
  final ValueChanged<SubjectClass> onTogglePinClass;
  final ValueChanged<SubjectClass> onEditClass;
  final ValueChanged<SubjectClass> onDeleteClass;
  final ValueChanged<SubjectClass>? onOpenAttendance;
  final ValueChanged<SubjectClass>? onOpenGrading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'จัดการรายวิชา',
                enabled: !isBusy,
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: isBusy ? null : onAddClass,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('เพิ่มห้องเรียน'),
            ),
          ),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'ยังไม่มีห้องเรียนในรายวิชานี้ กด "เพิ่มห้องเรียน" เพื่อเริ่มต้น',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
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
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
