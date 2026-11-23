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
  static const String teacherGrading = '/teacher/grading';
  static const String teacherAuditLog = '/teacher/audit-log';
  static const String teacherExportReports = '/teacher/export-reports';
  static const String teacherSyncQueue = '/teacher/sync-queue';
  static const String teacherSettings = '/teacher/settings';

  // Student Portal route
  static const String studentPortalPattern = '/student/:teacherCode';

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
