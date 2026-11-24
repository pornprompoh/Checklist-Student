import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
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
/// Protected by [UnsavedChangesGuard] and includes a Pure Dart Live Preview.
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

  AttendanceRuleConfig? _baseline;
  bool _enableLateConversion = false;
  bool _countLeaveAsAbsent = false;
  bool _initialized = false;

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    _lateRatioCtrl.dispose();
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
      // Preserve future-use attendance_score_weight without mutating it.
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

    return UnsavedChangesGuard(
      hasUnsavedChanges: _isDirty,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'ตั้งค่าเกณฑ์เวลาเรียน (มส) รายวิชา',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _handleBackToCheckIn(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('กลับหน้าเช็คชื่อ'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (ruleAsync.isLoading && !_initialized)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SkeletonBox(height: 48),
                          SizedBox(height: 12),
                          SkeletonBox(height: 48),
                        ],
                      ),
                    ),
                  )
                else if (ruleAsync.hasError && !_initialized)
                  AppFeedbackBanner(
                    type: AppFeedbackType.error,
                    message: ThaiErrorMapper.map(ruleAsync.error!),
                    onRetry: () => ref.invalidate(
                      attendanceRuleConfigProvider(widget.subjectClassId),
                    ),
                  )
                else ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _thresholdCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                                if (parsed == null ||
                                    parsed < 1 ||
                                    parsed > 100) {
                                  return 'กรุณากรอกตัวเลขระหว่าง 1 ถึง 100';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'นับการมาสายสะสมเป็นการขาดเรียน',
                              ),
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
                            const Divider(height: 28),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: saveState.isLoading
                                      ? null
                                      : _resetToDefaults,
                                  icon: const Icon(
                                    Icons.restart_alt_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('คืนค่าเริ่มต้น'),
                                ),
                                FilledButton.icon(
                                  onPressed: saveState.isLoading || !_isDirty
                                      ? null
                                      : _save,
                                  icon: saveState.isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_outlined,
                                          size: 18,
                                        ),
                                  label: const Text('บันทึกเกณฑ์เวลาเรียน'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (draftConfig.isValid)
                    AttendanceRulePreviewCard(
                      summaries: Map.from(previewSummaries),
                    ),
                ],
              ],
            ),
          ),
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
