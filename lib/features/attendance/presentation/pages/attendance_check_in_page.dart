import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
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
            label: '$prefixห้อง ${c.roomName}',
          );
        })
        .toList(growable: false);

    final activeClassId =
        (_selectedClassId != null && _selectedClassId!.isNotEmpty)
        ? _selectedClassId
        : (options.isNotEmpty ? options.first.id : null);

    if (activeClassId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ยังไม่ได้เลือกหรือยังไม่มีห้องเรียนในเทอมนี้'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.go(AppRoutes.teacherDashboard),
                    child: const Text('กลับหน้าหลัก'),
                  ),
                ],
              ),
            ),
          ),
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
