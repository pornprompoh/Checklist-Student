import 'package:flutter/material.dart';

enum _ClassCardMenuAction {
  gradingPlan,
  attendanceRules,
  exportReports,
  auditLog,
  roster,
  togglePin,
}

/// Compact `⋯` overflow menu for secondary classroom shortcuts on
/// [DashboardClassCard].
class DashboardClassCardMenu extends StatelessWidget {
  const DashboardClassCardMenu({
    super.key,
    required this.isPinned,
    required this.isBusy,
    required this.onTogglePin,
    required this.onOpenGradingPlan,
    required this.onOpenAttendanceRules,
    required this.onOpenExportReports,
    required this.onOpenAuditLog,
    required this.onOpenRoster,
  });

  final bool isPinned;
  final bool isBusy;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenGradingPlan;
  final VoidCallback onOpenAttendanceRules;
  final VoidCallback onOpenExportReports;
  final VoidCallback onOpenAuditLog;
  final VoidCallback onOpenRoster;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ClassCardMenuAction>(
      tooltip: 'ตัวเลือกเพิ่มเติม',
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      onSelected: (action) {
        switch (action) {
          case _ClassCardMenuAction.gradingPlan:
            onOpenGradingPlan();
          case _ClassCardMenuAction.attendanceRules:
            onOpenAttendanceRules();
          case _ClassCardMenuAction.exportReports:
            onOpenExportReports();
          case _ClassCardMenuAction.auditLog:
            onOpenAuditLog();
          case _ClassCardMenuAction.roster:
            onOpenRoster();
          case _ClassCardMenuAction.togglePin:
            if (!isBusy) onTogglePin();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ClassCardMenuAction.gradingPlan,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.assignment_outlined),
            title: Text('ออกแบบแผนเก็บงาน'),
          ),
        ),
        const PopupMenuItem(
          value: _ClassCardMenuAction.attendanceRules,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune_rounded),
            title: Text('ตั้งค่าเกณฑ์ มส'),
          ),
        ),
        const PopupMenuItem(
          value: _ClassCardMenuAction.exportReports,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.file_download_outlined),
            title: Text('ส่งออกรายงาน ปพ.5'),
          ),
        ),
        const PopupMenuItem(
          value: _ClassCardMenuAction.auditLog,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history_rounded),
            title: Text('ประวัติคะแนน'),
          ),
        ),
        const PopupMenuItem(
          value: _ClassCardMenuAction.roster,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.groups_outlined),
            title: Text('คลังรายชื่อ'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _ClassCardMenuAction.togglePin,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            ),
            title: Text(isPinned ? 'เลิกปักหมุด' : 'ปักหมุดห้องนี้'),
          ),
        ),
      ],
    );
  }
}
