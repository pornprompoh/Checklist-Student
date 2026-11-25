import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../../domain/entities/attendance_session.dart';
import '../providers/attendance_providers.dart';
import '../providers/attendance_rule_controller.dart';
import '../widgets/attendance_rule_preview_card.dart';

/// Per-subject-class attendance rule settings page (`/teacher/attendance/rules?classId=...`).
///
/// Desktop (`>= 860px`) shows a 2-column layout (settings form on the left,
/// Live Preview on the right); Mobile stacks cleanly. Guarded by [UnsavedChangesGuard].
class AttendanceRuleSettingsPage extends ConsumerStatefulWidget {
  const AttendanceRuleSettingsPage({super.key, required this.subjectClassId});

  final String subjectClassId;

  @override
  ConsumerState<AttendanceRuleSettingsPage> createState() =>
      _AttendanceRuleSettingsPageState();
}

class _AttendanceRuleSettingsPageState
    extends ConsumerState<AttendanceRuleSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _thresholdCtrl = TextEditingController();
  final _lateRatioCtrl = TextEditingController();
  final _formScrollController = ScrollController();
  final _previewScrollController = ScrollController();

  AttendanceRuleConfig? _baseline;
  bool _enableLateConversion = false;
  bool _countLeaveAsAbsent = false;
  bool _initialized = false;

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    _lateRatioCtrl.dispose();
    _formScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _hydrateFromConfig(AttendanceRuleConfig config) {
    _baseline = config;
    _thresholdCtrl.text = _formatNumber(config.absentThresholdPct);
    _enableLateConversion = config.lateToAbsentRatio != null;
    _lateRatioCtrl.text = (config.lateToAbsentRatio ?? 3).toString();
    _countLeaveAsAbsent = config.countLeaveAsAbsent;
    _initialized = true;
  }

  AttendanceRuleConfig _buildDraftConfig() {
    final base = _baseline;
    final parsedThreshold =
        double.tryParse(_thresholdCtrl.text.trim()) ??
        (base?.absentThresholdPct ?? 20.0);
    final parsedRatio = _enableLateConversion
        ? int.tryParse(_lateRatioCtrl.text.trim())
        : null;

    return AttendanceRuleConfig(
      subjectClassId: widget.subjectClassId,
      absentThresholdPct: parsedThreshold,
      lateToAbsentRatio: parsedRatio,
      countLeaveAsAbsent: _countLeaveAsAbsent,
      attendanceScoreWeight: base?.attendanceScoreWeight,
    );
  }

  bool get _isDirty {
    final base = _baseline;
    if (!_initialized || base == null) return false;
    final draft = _buildDraftConfig();
    final thresholdTextChanged =
        double.tryParse(_thresholdCtrl.text.trim()) != base.absentThresholdPct;
    return thresholdTextChanged ||
        draft.lateToAbsentRatio != base.lateToAbsentRatio ||
        draft.countLeaveAsAbsent != base.countLeaveAsAbsent;
  }

  String _formatNumber(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  @override
  Widget build(BuildContext context) {
    final ruleAsync = ref.watch(
      attendanceRuleConfigProvider(widget.subjectClassId),
    );
    final saveState = ref.watch(attendanceRuleControllerProvider);
    final enrollments =
        ref
            .watch(classEnrollmentsProvider(widget.subjectClassId))
            .asData
            ?.value ??
        const <ClassEnrollment>[];
    final sessions =
        ref
            .watch(attendanceSessionsProvider(widget.subjectClassId))
            .asData
            ?.value ??
        const <AttendanceSession>[];
    final records =
        ref
            .watch(attendanceClassRecordsProvider(widget.subjectClassId))
            .asData
            ?.value ??
        const <AttendanceRecord>[];

    ref.listen<AsyncValue<void>>(attendanceRuleControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    final loadedRule = ruleAsync.asData?.value;
    if (loadedRule != null && !_initialized) {
      _hydrateFromConfig(loadedRule);
    }

    final draftConfig = _buildDraftConfig();
    final previewSummaries = draftConfig.isValid
        ? ref
              .watch(attendanceStatisticsServiceProvider)
              .calculateClassSummaries(
                enrollments: enrollments,
                sessions: sessions,
                records: records,
                ruleConfig: draftConfig,
              )
        : const <String, dynamic>{};

    final pageHeader = AppPageHeader(
      title: 'ตั้งค่าเกณฑ์เวลาเรียน (มส) รายวิชา',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _handleBackToCheckIn(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('กลับหน้าเช็คชื่อ'),
        ),
      ],
    );

    return UnsavedChangesGuard(
      hasUnsavedChanges: _isDirty,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSplitPane =
              constraints.maxWidth >= 900 && constraints.maxHeight >= 520;

          if (ruleAsync.isLoading && !_initialized) {
            return AppPageContainer.scrollable(
              header: pageHeader,
              child: const AppSurfaceCard(
                child: Column(
                  children: [
                    SkeletonBox(height: 48),
                    SizedBox(height: 12),
                    SkeletonBox(height: 48),
                  ],
                ),
              ),
            );
          }

          if (ruleAsync.hasError && !_initialized) {
            return AppPageContainer.scrollable(
              header: pageHeader,
              child: AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: ThaiErrorMapper.map(ruleAsync.error!),
                onRetry: () => ref.invalidate(
                  attendanceRuleConfigProvider(widget.subjectClassId),
                ),
              ),
            );
          }

          final formCard = _buildFormCard(saveState.isLoading);
          final previewCard = draftConfig.isValid
              ? AttendanceRulePreviewCard(
                  summaries: Map.from(previewSummaries),
                )
              : const SizedBox.shrink();

          if (isSplitPane) {
            return AppPageContainer.viewport(
              header: pageHeader,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppSubtleScrollbar(
                      controller: _formScrollController,
                      child: SingleChildScrollView(
                        controller: _formScrollController,
                        primary: false,
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: formCard,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AppSubtleScrollbar(
                      controller: _previewScrollController,
                      child: SingleChildScrollView(
                        controller: _previewScrollController,
                        primary: false,
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: previewCard,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return AppPageContainer.scrollable(
            header: pageHeader,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                formCard,
                if (draftConfig.isValid) ...[
                  const SizedBox(height: 16),
                  previewCard,
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard(bool isSaving) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _thresholdCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'เกณฑ์ขาดเรียนเสี่ยง มส (%)',
                helperText:
                    'มาตรฐานสถานศึกษาทั่วไปคือ 20% (เกิน 20% แนะนำติด มส)',
                suffixText: '%',
              ),
              validator: (v) {
                final parsed = double.tryParse(v?.trim() ?? '');
                if (parsed == null || parsed < 1 || parsed > 100) {
                  return 'กรุณากรอกตัวเลขระหว่าง 1 ถึง 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('นับการมาสายสะสมเป็นการขาดเรียน'),
              subtitle: const Text(
                'เช่น มาสายครบ 3 ครั้ง ให้นับเป็นขาดเรียน 1 ครั้ง (หารปัดลง)',
              ),
              value: _enableLateConversion,
              onChanged: (value) => setState(() {
                _enableLateConversion = value;
                if (value && _lateRatioCtrl.text.trim().isEmpty) {
                  _lateRatioCtrl.text = '3';
                }
              }),
            ),
            if (_enableLateConversion) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _lateRatioCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'จำนวนครั้งสายต่อการขาด 1 ครั้ง',
                  hintText: 'เช่น 3',
                  suffixText: 'ครั้ง = ขาด 1 ครั้ง',
                ),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed < 1) {
                    return 'กรุณากรอกจำนวนเต็มตั้งแต่ 1 ขึ้นไป';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'นับการลา (ลาป่วย/ลากิจ) รวมเป็นการขาดเรียน',
              ),
              subtitle: const Text(
                'ค่าเริ่มต้นปิดไว้ หากเปิดจะนำยอดลาไปบวกรวมในการคำนวณ % ขาดเรียน',
              ),
              value: _countLeaveAsAbsent,
              onChanged: (value) =>
                  setState(() => _countLeaveAsAbsent = value),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _resetToDefaults,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('คืนค่าเริ่มต้น'),
                ),
                FilledButton.icon(
                  onPressed: isSaving || !_isDirty ? null : _save,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('บันทึกเกณฑ์เวลาเรียน'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _thresholdCtrl.text = '20';
      _enableLateConversion = false;
      _lateRatioCtrl.text = '3';
      _countLeaveAsAbsent = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = await ref
        .read(attendanceRuleControllerProvider.notifier)
        .saveRuleConfig(_buildDraftConfig());
    if (updated != null && mounted) {
      setState(() => _hydrateFromConfig(updated));
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'บันทึกเกณฑ์เวลาเรียนเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _handleBackToCheckIn(BuildContext context) async {
    if (_isDirty) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !context.mounted) return;
    }
    if (!context.mounted) return;
    context.go(AppRoutes.teacherAttendanceForClass(widget.subjectClassId));
  }
}
