import '../../../../core/constants/attendance_status.dart';

/// Command payload for inserting or updating a single student's attendance
/// record inside a session, carrying [expectedVersion] for Optimistic Locking.
///
/// Pure Dart value object.
class AttendanceRecordInput {
  const AttendanceRecordInput({
    this.existingRecordId,
    this.clientId,
    required this.enrollmentId,
    required this.status,
    this.note = '',
    this.expectedVersion,
  });

  final String? existingRecordId;

  /// Optional client-generated UUID v4 used for idempotent offline creation.
  final String? clientId;
  final String enrollmentId;
  final AttendanceStatus status;
  final String note;
  final int? expectedVersion;

  bool get isUpdate => existingRecordId != null && expectedVersion != null;
}
