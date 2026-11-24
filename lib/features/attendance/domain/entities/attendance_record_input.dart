import '../../../../core/constants/attendance_status.dart';

/// Command payload for inserting or updating a single student's attendance
/// record inside a session, carrying [expectedVersion] for Optimistic Locking.
///
/// Pure Dart value object.
class AttendanceRecordInput {
  const AttendanceRecordInput({
    this.existingRecordId,
    required this.enrollmentId,
    required this.status,
    this.note = '',
    this.expectedVersion,
  });

  final String? existingRecordId;
  final String enrollmentId;
  final AttendanceStatus status;
  final String note;
  final int? expectedVersion;

  bool get isUpdate => existingRecordId != null && expectedVersion != null;
}
