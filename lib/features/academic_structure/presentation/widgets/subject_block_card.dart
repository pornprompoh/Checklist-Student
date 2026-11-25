import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';

/// Compact Subject Block card rendered in a multi-column equal-height Grid on
/// `AcademicStructurePage`. Tapping the block drills into its rooms.
class SubjectBlockCard extends StatefulWidget {
  const SubjectBlockCard({
    super.key,
    required this.subject,
    required this.classes,
    required this.isBusy,
    required this.onOpenDetail,
    required this.onAddClass,
    required this.onEditSubject,
    required this.onDeleteSubject,
  });

  final Subject subject;
  final List<SubjectClass> classes;
  final bool isBusy;
  final VoidCallback onOpenDetail;
  final VoidCallback onAddClass;
  final VoidCallback onEditSubject;
  final VoidCallback onDeleteSubject;

  @override
  State<SubjectBlockCard> createState() => _SubjectBlockCardState();
}

class _SubjectBlockCardState extends State<SubjectBlockCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final previewClasses = widget.classes.take(4).toList(growable: false);
    final overflowCount = widget.classes.length - previewClasses.length;
    final radius = BorderRadius.circular(16);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: radius,
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
          ),
          boxShadow: _isHovered
              ? <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.subject.subjectCode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: AppTheme.tabularFigures,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: 'จัดการรายวิชา',
                            enabled: !widget.isBusy,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') widget.onEditSubject();
                              if (value == 'delete') widget.onDeleteSubject();
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
                      const SizedBox(height: 8),
                      Text(
                        widget.subject.subjectName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.classes.length} ห้องเรียน',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (previewClasses.isEmpty)
                        Text(
                          'ยังไม่มีห้องเรียน',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final sc in previewClasses)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  sc.roomName,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: AppTheme.tabularFigures,
                                  ),
                                ),
                              ),
                            if (overflowCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$overflowCount ห้อง',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: AppTheme.tabularFigures,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onPressed: widget.isBusy ? null : widget.onAddClass,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('เพิ่มห้อง'),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'จัดการห้องเรียน',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
