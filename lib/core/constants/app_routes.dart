/// Central route path constants for Teacher App (`/teacher/...`) and
/// Student Portal (`/student/:teacherCode`).
abstract final class AppRoutes {
  // Teacher App routes
  static const String teacherRoot = '/teacher';
  static const String teacherLogin = '/teacher/login';
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAcademicStructure = '/teacher/academic-structure';
  static const String teacherHomeroomRoster = '/teacher/homeroom-roster';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherAttendanceRules = '/teacher/attendance/rules';
  static const String teacherGrading = '/teacher/grading';
  static const String teacherAuditLog = '/teacher/audit-log';
  static const String teacherExportReports = '/teacher/export-reports';
  static const String teacherSyncQueue = '/teacher/sync-queue';
  static const String teacherSettings = '/teacher/settings';

  // Student Portal route
  static const String studentPortalPattern = '/student/:teacherCode';

  /// Builds the Teacher Attendance route pre-selecting [subjectClassId].
  static String teacherAttendanceForClass(String subjectClassId) {
    final encodedId = Uri.encodeQueryComponent(subjectClassId.trim());
    return '$teacherAttendance?classId=$encodedId';
  }

  /// Builds the Teacher Attendance Rules route for [subjectClassId].
  static String teacherAttendanceRulesForClass(String subjectClassId) {
    final encodedId = Uri.encodeQueryComponent(subjectClassId.trim());
    return '$teacherAttendanceRules?classId=$encodedId';
  }

  /// Builds a concrete Student Portal route path for [teacherCode].
  ///
  /// When [openExternalBrowser] is `true`, appends `?openExternalBrowser=1`
  /// to encourage in-app browsers (e.g. LINE) to open externally.
  static String studentPortalPath(
    String teacherCode, {
    bool openExternalBrowser = false,
  }) {
    final encodedCode = Uri.encodeComponent(teacherCode.trim());
    final basePath = '/student/$encodedCode';
    if (!openExternalBrowser) {
      return basePath;
    }
    return '$basePath?openExternalBrowser=1';
  }
}
