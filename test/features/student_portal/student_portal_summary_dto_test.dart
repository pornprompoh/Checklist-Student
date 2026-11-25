import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/features/student_portal/data/models/resolved_teacher_portal_dto.dart';
import 'package:checklist_student/features/student_portal/data/models/student_pin_access_status_dto.dart';
import 'package:checklist_student/features/student_portal/data/models/student_pin_verification_result_dto.dart';
import 'package:checklist_student/features/student_portal/data/models/student_portal_summary_dto.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_pin_verification_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResolvedTeacherPortalDto', () {
    test('parses redirected archived teacher_code accurately', () {
      final entity = ResolvedTeacherPortalDto.fromJson(const <String, dynamic>{
        'found': true,
        'is_redirected': true,
        'requested_code': 't-old1',
        'current_teacher_code': 't-7777',
        'teacher_display_name': 'ครูสมหญิง ใจดี',
        'school_name': 'โรงเรียนทดสอบวิทยา',
        'department': 'วิทยาศาสตร์',
      }).toEntity();

      expect(entity.found, isTrue);
      expect(entity.isRedirected, isTrue);
      expect(entity.requestedCode, 't-old1');
      expect(entity.currentTeacherCode, 't-7777');
      expect(entity.effectiveTeacherName, 'ครูสมหญิง ใจดี');
      expect(entity.schoolName, 'โรงเรียนทดสอบวิทยา');
    });
  });

  group('StudentPinAccessStatusDto & StudentPinVerificationResultDto', () {
    test('parses access status and locked verification response', () {
      final access = StudentPinAccessStatusDto.fromJson(const <String, dynamic>{
        'teacher_found': true,
        'student_found': true,
        'has_pin': false,
        'is_locked': false,
        'locked_until': null,
        'remaining_attempts': 5,
      }).toEntity();

      expect(access.requiresInitialPinSetup, isTrue);
      expect(access.remainingAttempts, 5);

      final locked = StudentPinVerificationResultDto.fromJson(
        const <String, dynamic>{
          'success': false,
          'error_code': 'PIN_LOCKED',
          'message': 'กรอกรหัส PIN ผิดครบ 5 ครั้ง ระบบล็อกชั่วคราว 15 นาที',
          'remaining_attempts': 0,
          'locked_until': '2026-11-25T10:15:00Z',
        },
      ).toEntity();

      expect(locked.success, isFalse);
      expect(locked.isLocked, isTrue);
      expect(locked.errorCode, StudentPinErrorCode.pinLocked);
      expect(locked.remainingAttempts, 0);
      expect(locked.lockedUntil, DateTime.utc(2026, 11, 25, 10, 15));
    });
  });

  group('StudentPortalSummaryDto', () {
    test('parses exact unrounded 79.99 score + 3.5 grade and server-side score/grade masking', () {
      final json = <String, dynamic>{
        'authorized': true,
        'teacher': const <String, dynamic>{
          'found': true,
          'is_redirected': false,
          'requested_code': 't-7777',
          'current_teacher_code': 't-7777',
          'teacher_display_name': 'ครูสมหญิง ใจดี',
          'school_name': 'โรงเรียนทดสอบวิทยา',
          'department': 'วิทยาศาสตร์',
        },
        'student': const <String, dynamic>{
          'student_code': '67001',
          'prefix': 'ด.ช.',
          'first_name': 'สมชาย',
          'last_name': 'ตั้งใจเรียน',
        },
        'available_terms': const <Map<String, dynamic>>[
          <String, dynamic>{
            'term_id': 'term-1',
            'academic_year_be': 2569,
            'term_label': '1',
            'start_date': '2026-05-16',
            'end_date': '2026-10-10',
            'is_pinned_active': true,
          },
        ],
        'selected_term_id': 'term-1',
        'classes': const <Map<String, dynamic>>[
          // Class 1: Both score and grade visible (exact decimal 79.99 -> grade 3.5)
          <String, dynamic>{
            'subject_class_id': 'sc-1',
            'subject_code': 'ว31101',
            'subject_name': 'วิทยาการคำนวณ A',
            'room_name': 'ม.4/1',
            'student_number': 1,
            'enrollment_status': 'active',
            'enrolled_at': '2026-06-01',
            'show_score_to_student': true,
            'show_grade_to_student': true,
            'total_score': '79.99',
            'total_max_score': '100.00',
            'displayed_grade': '3.5',
            'special_grade_override': null,
            'attendance_summary': <String, dynamic>{
              'total_eligible_sessions': 4,
              'recorded_sessions': 4,
              'present_count': 1,
              'late_count': 2,
              'leave_count': 1,
              'absent_count': 0,
              'converted_late_absent_count': 1,
              'counted_leave_absent_count': 1,
              'effective_absent_count': 2,
              'absent_percentage': 50.0,
              'absent_threshold_pct': 20.0,
            },
            'attendance_records': <Map<String, dynamic>>[
              <String, dynamic>{
                'session_date': '2026-06-04',
                'status': 'present',
                'note': '',
              },
            ],
            'category_scores': <Map<String, dynamic>>[
              <String, dynamic>{
                'category_id': 'cat-1',
                'category_name': 'คะแนนเก็บ',
                'target_max_score': 100,
                'max_score': 100,
                'earned_score': 79.99,
              },
            ],
            'assignments': <Map<String, dynamic>>[
              <String, dynamic>{
                'assignment_id': 'asg-1',
                'category_id': 'cat-1',
                'category_name': 'คะแนนเก็บ',
                'title': 'งาน 1',
                'description': 'แบบฝึกหัด',
                'max_score': 50,
                'is_mandatory': true,
                'due_date': '2026-07-01',
                'submission_status': 'submitted',
                'score': 39.99,
                'note': '',
              },
            ],
          },
          // Class 2: Score masked (show_score_to_student = false), grade visible
          <String, dynamic>{
            'subject_class_id': 'sc-2',
            'subject_code': 'ว31102',
            'subject_name': 'วิทยาการคำนวณ B',
            'room_name': 'ม.4/1',
            'student_number': 1,
            'enrollment_status': 'active',
            'enrolled_at': '2026-06-01',
            'show_score_to_student': false,
            'show_grade_to_student': true,
            'total_score': null,
            'total_max_score': 100,
            'displayed_grade': '3.5',
            'special_grade_override': null,
            'attendance_summary': <String, dynamic>{
              'total_eligible_sessions': 0,
              'recorded_sessions': 0,
              'present_count': 0,
              'late_count': 0,
              'leave_count': 0,
              'absent_count': 0,
              'converted_late_absent_count': 0,
              'counted_leave_absent_count': 0,
              'effective_absent_count': 0,
              'absent_percentage': 0,
              'absent_threshold_pct': 20,
            },
            'attendance_records': <Map<String, dynamic>>[],
            'category_scores': <Map<String, dynamic>>[
              <String, dynamic>{
                'category_id': 'cat-2',
                'category_name': 'คะแนนเก็บ B',
                'target_max_score': 100,
                'max_score': 100,
                'earned_score': null,
              },
            ],
            'assignments': <Map<String, dynamic>>[
              <String, dynamic>{
                'assignment_id': 'asg-2',
                'category_id': 'cat-2',
                'category_name': 'คะแนนเก็บ B',
                'title': 'งาน B1',
                'description': '',
                'max_score': 100,
                'is_mandatory': true,
                'due_date': null,
                'submission_status': 'submitted',
                'score': null,
                'note': 'ส่งตรงเวลา',
              },
            ],
          },
          // Class 3: Score visible, grade masked (show_grade_to_student = false)
          <String, dynamic>{
            'subject_class_id': 'sc-3',
            'subject_code': 'ว31103',
            'subject_name': 'วิทยาการคำนวณ C',
            'room_name': 'ม.4/1',
            'student_number': 1,
            'enrollment_status': 'active',
            'enrolled_at': '2026-06-01',
            'show_score_to_student': true,
            'show_grade_to_student': false,
            'total_score': 79.99,
            'total_max_score': 100,
            'displayed_grade': null,
            'special_grade_override': null,
            'attendance_summary': <String, dynamic>{
              'total_eligible_sessions': 0,
              'recorded_sessions': 0,
              'present_count': 0,
              'late_count': 0,
              'leave_count': 0,
              'absent_count': 0,
              'converted_late_absent_count': 0,
              'counted_leave_absent_count': 0,
              'effective_absent_count': 0,
              'absent_percentage': 0,
              'absent_threshold_pct': 20,
            },
            'attendance_records': <Map<String, dynamic>>[],
            'category_scores': <Map<String, dynamic>>[],
            'assignments': <Map<String, dynamic>>[],
          },
        ],
      };

      final summary = StudentPortalSummaryDto.fromJson(json).toEntity();

      expect(summary.authorized, isTrue);
      expect(summary.student?.fullName, 'ด.ช.สมชาย ตั้งใจเรียน');
      expect(summary.availableTerms, hasLength(1));
      expect(summary.availableTerms.first.startDate, DateTime(2026, 5, 16));
      expect(summary.classes, hasLength(3));

      // Class 1: exact unrounded total_score = 79.99 -> grade 3.5
      final class1 = summary.classes[0];
      expect(class1.showScoreToStudent, isTrue);
      expect(class1.showGradeToStudent, isTrue);
      expect(class1.totalScore, 79.99);
      expect(class1.displayedGrade, '3.5');
      expect(class1.attendanceSummary.isExceededThreshold, isTrue);
      expect(class1.attendanceRecords.single.status, AttendanceStatus.present);
      expect(class1.assignments.single.score, 39.99);
      expect(class1.assignments.single.dueDate, DateTime(2026, 7, 1));

      // Class 2: score masked (null), submission status still visible
      final class2 = summary.classes[1];
      expect(class2.showScoreToStudent, isFalse);
      expect(class2.totalScore, isNull);
      expect(class2.categoryScores.single.earnedScore, isNull);
      expect(class2.assignments.single.score, isNull);
      expect(
        class2.assignments.single.submissionStatus,
        SubmissionStatus.submitted,
      );
      expect(class2.displayedGrade, '3.5');

      // Class 3: grade masked (null), score still visible
      final class3 = summary.classes[2];
      expect(class3.showGradeToStudent, isFalse);
      expect(class3.totalScore, 79.99);
      expect(class3.displayedGrade, isNull);
      expect(class3.specialGradeOverride, isNull);
    });

    test('parses unauthorized summary response cleanly', () {
      final summary = StudentPortalSummaryDto.fromJson(const <String, dynamic>{
        'authorized': false,
        'error_code': 'INVALID_PIN',
        'message': 'รหัส PIN ไม่ถูกต้อง',
      }).toEntity();

      expect(summary.authorized, isFalse);
      expect(summary.errorCode, StudentPinErrorCode.invalidPin);
      expect(summary.errorMessage, 'รหัส PIN ไม่ถูกต้อง');
      expect(summary.classes, isEmpty);
    });
  });
}
