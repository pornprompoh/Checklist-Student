import '../../../../core/constants/attendance_status.dart';
import '../../../../core/constants/submission_status.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/student_pin_verification_result.dart';
import '../../domain/entities/student_portal_class_detail.dart';
import '../../domain/entities/student_portal_summary.dart';
import 'resolved_teacher_portal_dto.dart';

/// JSON DTO for `public.get_student_portal_summary`.
///
/// Safely handles exact PostgreSQL `NUMERIC` values (whether serialized as
/// `num` or `String`), ISO dates via [ThaiDateFormatter.parseIsoDate], and
/// `null` fields masked server-side when score/grade visibility is disabled.
class StudentPortalSummaryDto {
  const StudentPortalSummaryDto({required this.entity});

  final StudentPortalSummary entity;

  factory StudentPortalSummaryDto.fromJson(Map<String, dynamic> json) {
    final authorized = json['authorized'] as bool? ?? false;
    if (!authorized) {
      return StudentPortalSummaryDto(
        entity: StudentPortalSummary(
          authorized: false,
          errorCode: StudentPinErrorCode.fromServerCode(
            json['error_code'] as String?,
          ),
          errorMessage: json['message'] as String?,
          lockedUntil: _parseTimestamp(json['locked_until']),
        ),
      );
    }

    final teacherMap = _asMap(json['teacher']);
    final studentMap = _asMap(json['student']);
    final termsRaw = _asList(json['available_terms']);
    final classesRaw = _asList(json['classes']);

    return StudentPortalSummaryDto(
      entity: StudentPortalSummary(
        authorized: true,
        teacher: teacherMap == null
            ? null
            : ResolvedTeacherPortalDto.fromJson(teacherMap).toEntity(),
        student: studentMap == null
            ? null
            : StudentPortalStudentInfo(
                studentCode: studentMap['student_code'] as String? ?? '',
                prefix: studentMap['prefix'] as String? ?? '',
                firstName: studentMap['first_name'] as String? ?? '',
                lastName: studentMap['last_name'] as String? ?? '',
              ),
        availableTerms: termsRaw
            .map(_parseTerm)
            .whereType<StudentPortalTermOption>()
            .toList(growable: false),
        selectedTermId: json['selected_term_id'] as String?,
        classes: classesRaw
            .map(_parseClassDetail)
            .whereType<StudentPortalClassDetail>()
            .toList(growable: false),
      ),
    );
  }

  StudentPortalSummary toEntity() => entity;

  static StudentPortalTermOption? _parseTerm(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    return StudentPortalTermOption(
      termId: map['term_id'] as String? ?? '',
      academicYearBe: _toInt(map['academic_year_be']),
      termLabel: map['term_label'] as String? ?? '',
      startDate: ThaiDateFormatter.parseIsoDate(map['start_date'] as String?),
      endDate: ThaiDateFormatter.parseIsoDate(map['end_date'] as String?),
      isPinnedActive: map['is_pinned_active'] as bool? ?? false,
    );
  }

  static StudentPortalClassDetail? _parseClassDetail(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    final attMap = _asMap(map['attendance_summary']) ?? const <String, dynamic>{};

    return StudentPortalClassDetail(
      subjectClassId: map['subject_class_id'] as String? ?? '',
      subjectCode: map['subject_code'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? '',
      roomName: map['room_name'] as String? ?? '',
      studentNumber: _toInt(map['student_number']),
      enrollmentStatus: map['enrollment_status'] as String? ?? 'active',
      enrolledAt: ThaiDateFormatter.parseIsoDate(map['enrolled_at'] as String?),
      showScoreToStudent: map['show_score_to_student'] as bool? ?? false,
      showGradeToStudent: map['show_grade_to_student'] as bool? ?? false,
      totalScore: _toNullableDouble(map['total_score']),
      totalMaxScore: _toDouble(map['total_max_score']),
      displayedGrade: map['displayed_grade'] as String?,
      specialGradeOverride: map['special_grade_override'] as String?,
      attendanceSummary: StudentPortalAttendanceSummary(
        totalEligibleSessions: _toInt(attMap['total_eligible_sessions']),
        recordedSessions: _toInt(attMap['recorded_sessions']),
        presentCount: _toInt(attMap['present_count']),
        lateCount: _toInt(attMap['late_count']),
        leaveCount: _toInt(attMap['leave_count']),
        absentCount: _toInt(attMap['absent_count']),
        convertedLateAbsentCount: _toInt(attMap['converted_late_absent_count']),
        countedLeaveAbsentCount: _toInt(attMap['counted_leave_absent_count']),
        effectiveAbsentCount: _toInt(attMap['effective_absent_count']),
        absentPercentage: _toDouble(attMap['absent_percentage']),
        absentThresholdPct: _toDouble(attMap['absent_threshold_pct']),
      ),
      attendanceRecords: _asList(map['attendance_records'])
          .map(_parseAttendanceRecord)
          .whereType<StudentPortalAttendanceRecord>()
          .toList(growable: false),
      categoryScores: _asList(map['category_scores'])
          .map(_parseCategoryScore)
          .whereType<StudentPortalCategoryScore>()
          .toList(growable: false),
      assignments: _asList(map['assignments'])
          .map(_parseAssignmentItem)
          .whereType<StudentPortalAssignmentItem>()
          .toList(growable: false),
    );
  }

  static StudentPortalAttendanceRecord? _parseAttendanceRecord(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    final date = ThaiDateFormatter.parseIsoDate(map['session_date'] as String?);
    final status = AttendanceStatus.tryFromDbValue(map['status'] as String?);
    if (date == null || status == null) return null;
    return StudentPortalAttendanceRecord(
      sessionDate: date,
      status: status,
      note: map['note'] as String? ?? '',
    );
  }

  static StudentPortalCategoryScore? _parseCategoryScore(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    return StudentPortalCategoryScore(
      categoryId: map['category_id'] as String?,
      categoryName: map['category_name'] as String? ?? 'งานทั่วไป',
      targetMaxScore: _toNullableDouble(map['target_max_score']),
      maxScore: _toDouble(map['max_score']),
      earnedScore: _toNullableDouble(map['earned_score']),
    );
  }

  static StudentPortalAssignmentItem? _parseAssignmentItem(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    return StudentPortalAssignmentItem(
      assignmentId: map['assignment_id'] as String? ?? '',
      categoryId: map['category_id'] as String?,
      categoryName: map['category_name'] as String? ?? 'งานทั่วไป',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      maxScore: _toDouble(map['max_score']),
      isMandatory: map['is_mandatory'] as bool? ?? false,
      dueDate: ThaiDateFormatter.parseIsoDate(map['due_date'] as String?),
      submissionStatus:
          SubmissionStatus.tryFromDbValue(
            map['submission_status'] as String?,
          ) ??
          SubmissionStatus.missing,
      score: _toNullableDouble(map['score']),
      note: map['note'] as String? ?? '',
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static List<Object?> _asList(Object? value) =>
      value is List ? List<Object?>.from(value) : const <Object?>[];

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static double _toDouble(Object? value) => _toNullableDouble(value) ?? 0.0;

  static double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
