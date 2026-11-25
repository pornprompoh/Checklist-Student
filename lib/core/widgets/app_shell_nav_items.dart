import 'package:flutter/material.dart';

import '../constants/app_routes.dart';

/// One navigable destination in the Teacher App shell.
class AppShellNavItem {
  const AppShellNavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A labelled group of destinations rendered in the Desktop Sidebar.
class AppShellNavGroup {
  const AppShellNavGroup({required this.label, required this.items});

  final String label;
  final List<AppShellNavItem> items;
}

/// Single source of truth for shell navigation destinations, sidebar
/// grouping, mobile bottom bar slots and contextual AppBar titles.
abstract final class AppShellNavigation {
  static const dashboard = AppShellNavItem(
    route: AppRoutes.teacherDashboard,
    label: 'หน้าหลัก',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
  );
  static const academicStructure = AppShellNavItem(
    route: AppRoutes.teacherAcademicStructure,
    label: 'โครงสร้างสอน',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree_rounded,
  );
  static const homeroomRoster = AppShellNavItem(
    route: AppRoutes.teacherHomeroomRoster,
    label: 'คลังรายชื่อ',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
  );
  static const exportReports = AppShellNavItem(
    route: AppRoutes.teacherExportReports,
    label: 'ส่งออกรายงาน',
    icon: Icons.file_download_outlined,
    selectedIcon: Icons.file_download_rounded,
  );
  static const auditLog = AppShellNavItem(
    route: AppRoutes.teacherAuditLog,
    label: 'ประวัติคะแนน',
    icon: Icons.history_rounded,
    selectedIcon: Icons.history_toggle_off_rounded,
  );
  static const syncQueue = AppShellNavItem(
    route: AppRoutes.teacherSyncQueue,
    label: 'สถานะซิงค์',
    icon: Icons.sync_outlined,
    selectedIcon: Icons.sync_rounded,
  );
  static const settings = AppShellNavItem(
    route: AppRoutes.teacherSettings,
    label: 'ตั้งค่า',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  );

  /// Mobile/Tablet bottom bar (max 5 slots).
  static const List<AppShellNavItem> mobilePrimaryItems = <AppShellNavItem>[
    dashboard,
    academicStructure,
    homeroomRoster,
    exportReports,
    settings,
  ];

  /// Desktop sidebar grouped by real teacher workflows.
  static const List<AppShellNavGroup> sidebarGroups = <AppShellNavGroup>[
    AppShellNavGroup(
      label: 'การสอนประจำวัน',
      items: <AppShellNavItem>[dashboard, academicStructure, homeroomRoster],
    ),
    AppShellNavGroup(
      label: 'รายงานและระบบ',
      items: <AppShellNavItem>[exportReports, auditLog, syncQueue, settings],
    ),
  ];

  /// Ordered (most specific first) route prefixes for contextual titles.
  static const List<(String, String)> _contextualTitles = <(String, String)>[
    (AppRoutes.teacherAttendanceRules, 'เกณฑ์เวลาเรียน'),
    (AppRoutes.teacherAttendance, 'เช็คชื่อ'),
    (AppRoutes.teacherGradingPlan, 'แผนเก็บงาน'),
    (AppRoutes.teacherGrading, 'ตารางคะแนน'),
    (AppRoutes.teacherAuditLog, 'ประวัติคะแนน'),
    (AppRoutes.teacherSyncQueue, 'สถานะซิงค์'),
  ];

  /// Human-readable Thai title for the current [path].
  static String titleFor(String path) {
    for (final (prefix, title) in _contextualTitles) {
      if (path.startsWith(prefix)) return title;
    }
    for (final item in mobilePrimaryItems) {
      if (path.startsWith(item.route)) return item.label;
    }
    return dashboard.label;
  }

  /// Selected bottom bar index for [path] (falls back to `หน้าหลัก`).
  static int mobileIndexFor(String path) {
    final idx = mobilePrimaryItems.indexWhere(
      (item) => path.startsWith(item.route),
    );
    return idx >= 0 ? idx : 0;
  }
}
