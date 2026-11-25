import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/typed_confirm_dialog.dart';
import '../../domain/entities/audit_log_year_summary.dart';

/// Yearly audit log volume overview with Export CSV/JSON and guarded manual
/// yearly cleanup (`TypedConfirmDialog` requiring exact Buddhist Era year).
class AuditLogYearlyCleanupCard extends StatelessWidget {
  const AuditLogYearlyCleanupCard({
    super.key,
    required this.summaries,
    required this.exportedYearIds,
    required this.isBusy,
    required this.onExportYearCsv,
    required this.onExportYearJson,
    required this.onDeleteYearLogs,
  });

  final List<AuditLogYearSummary> summaries;
  final Set<String> exportedYearIds;
  final bool isBusy;
  final ValueChanged<AuditLogYearSummary> onExportYearCsv;
  final ValueChanged<AuditLogYearSummary> onExportYearJson;
  final ValueChanged<AuditLogYearSummary> onDeleteYearLogs;

  Future<void> _confirmDelete(
    BuildContext context,
    AuditLogYearSummary summary,
  ) async {
    final confirmed = await TypedConfirmDialog.show(
      context,
      title: 'ยืนยันการล้าง Log ประจำปี พ.ศ. ${summary.yearBe}',
      description:
          'คำสั่งนี้จะลบเฉพาะประวัติ Audit Log ของปีการศึกษา พ.ศ. ${summary.yearBe} เท่านั้น '
          'ไม่ลบคะแนนหรือเกรดจริงของนักเรียนในระบบ (แนะนำให้ Export CSV หรือ JSON สำรองก่อนลบ)',
      expectedText: '${summary.yearBe}',
      impactSummary: <DeleteImpactItem>[
        DeleteImpactItem(
          label: 'ประวัติการแก้ไขคะแนนและสถานะเกรด (ลบเฉพาะ Log)',
          count: summary.totalLogsCount,
        ),
      ],
      confirmLabel: 'ยืนยันล้าง Log ปี ${summary.yearBe}',
    );
    if (confirmed) {
      onDeleteYearLogs(summary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurfaceCard(
          backgroundColor: colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ระบบคุมขนาด Audit Log 3 ชั้น (Free-Tier Guardrails)',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1) Debounce 2 นาที: แก้คะแนนช่องเดิมติดกันจะยุบทับเป็นรายการเดียว\n'
                '2) จำกัดสูงสุด 10 ครั้งต่อช่อง: โดยล็อก "รายการแรก" ไว้ตรวจสอบเสมอ\n'
                '3) ล้างอัตโนมัติหลังครบ 1 ปี (pg_cron): ลบเฉพาะประวัติ Log โดยไม่แตะคะแนนจริงของนักเรียน',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (summaries.isEmpty)
          const AppEmptyState(
            icon: Icons.cleaning_services_outlined,
            title: 'ยังไม่มีรายการประวัติการแก้ไขคะแนนในระบบ',
            description: 'เมื่อมีประวัติการแก้ไขคะแนน ระบบจะสรุปจำนวนรายการแยกตามปีการศึกษาที่นี่',
          )
        else
          for (final summary in summaries) ...[
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'ปีการศึกษา พ.ศ. ${summary.yearBe}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      if (exportedYearIds.contains(summary.academicYearId))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.successContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: semantic.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Export สำรองแล้ว',
                                style: textTheme.labelSmall?.copyWith(
                                  color: semantic.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'รวม ${summary.totalLogsCount} รายการ '
                    '(คะแนน ${summary.scoreLogsCount} · สถานะ ร/มส ${summary.gradeStatusLogsCount})',
                    style: textTheme.bodyMedium?.copyWith(
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  if (summary.oldestChangedAt != null &&
                      summary.newestChangedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ช่วงเวลา: ${ThaiDateFormatter.formatShortDate(summary.oldestChangedAt!.toLocal())} '
                      '– ${ThaiDateFormatter.formatShortDate(summary.newestChangedAt!.toLocal())}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => onExportYearCsv(summary),
                        icon: const Icon(Icons.table_view_outlined, size: 17),
                        label: const Text('Export CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => onExportYearJson(summary),
                        icon: const Icon(Icons.data_object_rounded, size: 17),
                        label: const Text('Export JSON'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: semantic.dangerContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: semantic.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'ลบเฉพาะประวัติ Log (คะแนนจริงไม่ถูกลบ)',
                          style: textTheme.bodySmall?.copyWith(
                            color: semantic.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: semantic.dangerContainer,
                            foregroundColor: semantic.danger,
                          ),
                          onPressed: isBusy
                              ? null
                              : () => _confirmDelete(context, summary),
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                          ),
                          label: Text('ล้าง Log ปี พ.ศ. ${summary.yearBe}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
