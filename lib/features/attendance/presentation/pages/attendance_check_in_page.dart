import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../academic_structure/domain/entities/subject.dart';
import '../../../academic_structure/domain/entities/subject_class.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../widgets/attendance_check_in_body.dart';
import '../widgets/attendance_session_header.dart';

/// Daily classroom attendance check-in page (`/teacher/attendance?classId=...`).
///
/// Resolves available subject-classes in the active term and delegates the
/// interactive check-in session view to [AttendanceCheckInBody].
class AttendanceCheckInPage extends ConsumerStatefulWidget {
  const AttendanceCheckInPage({super.key, this.initialClassId});

  final String? initialClassId;

  @override
  ConsumerState<AttendanceCheckInPage> createState() =>
      _AttendanceCheckInPageState();
}

class _AttendanceCheckInPageState extends ConsumerState<AttendanceCheckInPage> {
  String? _selectedClassId;
  bool _lockAfterSave = true;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
  }

  @override
  void didUpdateWidget(covariant AttendanceCheckInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialClassId != oldWidget.initialClassId &&
        widget.initialClassId != null &&
        widget.initialClassId!.isNotEmpty) {
      _selectedClassId = widget.initialClassId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTerm = ref.watch(effectiveSelectedTermProvider);
    final subjectsAsync = selectedTerm == null
        ? const AsyncData<List<Subject>>(<Subject>[])
        : ref.watch(subjectsByTermProvider(selectedTerm.id));
    final classesAsync = selectedTerm == null
        ? const AsyncData<List<SubjectClass>>(<SubjectClass>[])
        : ref.watch(subjectClassesByTermProvider(selectedTerm.id));

    final subjects = subjectsAsync.asData?.value ?? const <Subject>[];
    final classes = classesAsync.asData?.value ?? const <SubjectClass>[];
    final subjectById = {for (final s in subjects) s.id: s};

    final options = classes
        .map((c) {
          final sub = subjectById[c.subjectId];
          final prefix = sub != null
              ? '${sub.subjectCode} ${sub.subjectName} · '
              : '';
          return AttendanceClassOption(
            id: c.id,
            label: '$prefix${c.roomName}',
          );
        })
        .toList(growable: false);

    final activeClassId =
        (_selectedClassId != null && _selectedClassId!.isNotEmpty)
        ? _selectedClassId
        : (options.isNotEmpty ? options.first.id : null);

    if (activeClassId == null &&
        (subjectsAsync.isLoading || classesAsync.isLoading)) {
      return const AppPageContainer.scrollable(
        header: AppPageHeader(title: 'เช็คชื่อรายวัน'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSurfaceCard(child: SkeletonBox(height: 64)),
            SizedBox(height: 12),
            AppSurfaceCard(child: SkeletonBox(height: 180)),
          ],
        ),
      );
    }

    if (activeClassId == null) {
      return AppPageContainer.scrollable(
        header: const AppPageHeader(title: 'เช็คชื่อรายวัน'),
        child: AppEmptyState(
          icon: Icons.fact_check_outlined,
          title: 'ยังไม่ได้เลือกหรือยังไม่มีห้องเรียนในเทอมนี้',
          description:
              'เลือกห้องเรียนจากหน้าหลัก หรือเพิ่มรายวิชาและห้องเรียนก่อนเริ่มเช็คชื่อ',
          actionLabel: 'กลับหน้าหลัก',
          actionIcon: Icons.home_outlined,
          onAction: () => context.go(AppRoutes.teacherDashboard),
        ),
      );
    }

    return AttendanceCheckInBody(
      subjectClassId: activeClassId,
      classOptions: options,
      lockAfterSave: _lockAfterSave,
      onToggleLockAfterSave: (v) => setState(() => _lockAfterSave = v),
      onSwitchClass: (newId) {
        setState(() => _selectedClassId = newId);
        context.go(AppRoutes.teacherAttendanceForClass(newId));
      },
    );
  }
}
