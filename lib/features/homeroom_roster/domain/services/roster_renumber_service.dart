import '../entities/class_enrollment.dart';
import '../entities/homeroom_student.dart';
import '../entities/student_lifecycle_status.dart';

/// Represents a single student number reassignment produced by
/// [RosterRenumberService].
class RenumberAssignment {
  const RenumberAssignment({
    required this.recordId,
    required this.oldNumber,
    required this.newNumber,
    required this.displayName,
  });

  final String recordId;
  final int oldNumber;
  final int newNumber;
  final String displayName;
}

/// Pure Dart service computing sequential `1..N` renumbering strictly for
/// `active` students while leaving `transferred_out` student numbers intact.
abstract final class RosterRenumberService {
  /// Computes number changes for active [HomeroomStudent] records.
  static List<RenumberAssignment> computeHomeroomRenumber(
    List<HomeroomStudent> students,
  ) {
    final active = students
        .where((s) => s.status == StudentLifecycleStatus.active)
        .toList()
      ..sort(_compareHomeroomStudents);

    return _buildAssignments(
      items: active,
      idOf: (s) => s.id,
      numberOf: (s) => s.studentNumber,
      nameOf: (s) => s.fullName,
    );
  }

  /// Computes number changes for active [ClassEnrollment] records.
  static List<RenumberAssignment> computeClassEnrollmentRenumber(
    List<ClassEnrollment> enrollments,
  ) {
    final active = enrollments
        .where((e) => e.status == StudentLifecycleStatus.active)
        .toList()
      ..sort(_compareEnrollments);

    return _buildAssignments(
      items: active,
      idOf: (e) => e.id,
      numberOf: (e) => e.studentNumber,
      nameOf: (e) => e.fullName,
    );
  }

  /// Returns `(max(existingNumbers) ?? 0) + 1` for newly added or mid-term students.
  static int nextStudentNumber(Iterable<int> existingNumbers) {
    var maxNum = 0;
    for (final number in existingNumbers) {
      if (number > maxNum) {
        maxNum = number;
      }
    }
    return maxNum + 1;
  }

  static int _compareHomeroomStudents(HomeroomStudent a, HomeroomStudent b) {
    final byNum = a.studentNumber.compareTo(b.studentNumber);
    return byNum != 0 ? byNum : a.studentCode.compareTo(b.studentCode);
  }

  static int _compareEnrollments(ClassEnrollment a, ClassEnrollment b) {
    final byNum = a.studentNumber.compareTo(b.studentNumber);
    return byNum != 0 ? byNum : a.studentCode.compareTo(b.studentCode);
  }

  static List<RenumberAssignment> _buildAssignments<T>({
    required List<T> items,
    required String Function(T) idOf,
    required int Function(T) numberOf,
    required String Function(T) nameOf,
  }) {
    final changes = <RenumberAssignment>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final oldNumber = numberOf(item);
      final newNumber = i + 1;
      if (newNumber != oldNumber) {
        changes.add(
          RenumberAssignment(
            recordId: idOf(item),
            oldNumber: oldNumber,
            newNumber: newNumber,
            displayName: nameOf(item),
          ),
        );
      }
    }
    return List<RenumberAssignment>.unmodifiable(changes);
  }
}
