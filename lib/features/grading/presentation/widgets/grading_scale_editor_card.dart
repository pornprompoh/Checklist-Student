import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/services/grade_evaluator_service.dart';
import '../../domain/services/score_calculator_service.dart';
import 'grading_scale_tier_row.dart';

class _EditableTierRow {
  _EditableTierRow({required String grade, required String minScore})
    : gradeCtrl = TextEditingController(text: grade),
      minScoreCtrl = TextEditingController(text: minScore);

  final TextEditingController gradeCtrl;
  final TextEditingController minScoreCtrl;

  void dispose() {
    gradeCtrl.dispose();
    minScoreCtrl.dispose();
  }
}

/// Interactive grading scale (`0-4` / `A-F` / `custom`) and `missing_work_threshold`
/// editor card with real-time validation via [GradeEvaluatorService] and dirty
/// tracking for [UnsavedChangesGuard].
class GradingScaleEditorCard extends StatefulWidget {
  const GradingScaleEditorCard({
    super.key,
    required this.initialConfig,
    required this.isSaving,
    required this.onDirtyChanged,
    required this.onSave,
  });

  final GradingScaleConfig initialConfig;
  final bool isSaving;
  final ValueChanged<bool> onDirtyChanged;
  final Future<bool> Function(GradingScaleConfig config) onSave;

  @override
  State<GradingScaleEditorCard> createState() => _GradingScaleEditorCardState();
}

class _GradingScaleEditorCardState extends State<GradingScaleEditorCard> {
  static const _evaluator = GradeEvaluatorService();
  static const _calculator = ScoreCalculatorService();

  late GradingScaleType _scaleType;
  late TextEditingController _thresholdCtrl;
  final List<_EditableTierRow> _rows = <_EditableTierRow>[];
  bool _lastReportedDirty = false;

  @override
  void initState() {
    super.initState();
    _thresholdCtrl = TextEditingController();
    _hydrateFrom(widget.initialConfig, notifyParent: false);
  }

  @override
  void didUpdateWidget(covariant GradingScaleEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialConfig.subjectClassId !=
            widget.initialConfig.subjectClassId ||
        !_configsEqual(oldWidget.initialConfig, widget.initialConfig)) {
      _hydrateFrom(widget.initialConfig, notifyParent: true);
    }
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _hydrateFrom(
    GradingScaleConfig config, {
    required bool notifyParent,
  }) {
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();
    _scaleType = config.scaleType;
    _thresholdCtrl.text = '${config.missingWorkThreshold}';
    for (final tier in config.rules) {
      _rows.add(
        _EditableTierRow(
          grade: tier.grade,
          minScore: _calculator.formatExactScore(tier.minScore),
        ),
      );
    }
    if (notifyParent) {
      _syncDirty(false);
    }
  }

  void _applyScaleType(GradingScaleType nextType) {
    setState(() {
      _scaleType = nextType;
      if (nextType == GradingScaleType.scale0To4 ||
          nextType == GradingScaleType.scaleAToF) {
        for (final row in _rows) {
          row.dispose();
        }
        _rows.clear();
        for (final tier in GradingScaleConfig.presetRulesFor(nextType)) {
          _rows.add(
            _EditableTierRow(
              grade: tier.grade,
              minScore: _calculator.formatExactScore(tier.minScore),
            ),
          );
        }
      }
    });
    _notifyDirtyIfChanged();
  }

  List<GradingRuleTier>? _tryParseDraftRules() {
    final parsed = <GradingRuleTier>[];
    for (final row in _rows) {
      final minVal = double.tryParse(row.minScoreCtrl.text.trim());
      if (minVal == null) {
        return null;
      }
      parsed.add(
        GradingRuleTier(grade: row.gradeCtrl.text.trim(), minScore: minVal),
      );
    }
    return parsed;
  }

  String? _computeValidationError() {
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    if (threshold == null || threshold < 1) {
      return 'เกณฑ์งานค้างสำหรับแนะนำเกรด ร ต้องเป็นจำนวนเต็มตั้งแต่ 1 ขึ้นไป';
    }
    final parsedRules = _tryParseDraftRules();
    if (parsedRules == null) {
      return 'กรุณากรอกคะแนนขั้นต่ำเป็นตัวเลขให้ครบทุกช่วงเกรด';
    }
    return _evaluator.validateGradingRules(parsedRules);
  }

  bool get _isDirty {
    final base = widget.initialConfig;
    if (_scaleType != base.scaleType) return true;
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    if (threshold != base.missingWorkThreshold) return true;
    final draftRules = _tryParseDraftRules();
    if (draftRules == null || draftRules.length != base.rules.length) {
      return true;
    }
    for (var i = 0; i < draftRules.length; i++) {
      if (draftRules[i].grade != base.rules[i].grade.trim()) return true;
      if ((draftRules[i].minScore * 100).round() !=
          (base.rules[i].minScore * 100).round()) {
        return true;
      }
    }
    return false;
  }

  void _notifyDirtyIfChanged() => _syncDirty(_isDirty);

  void _syncDirty(bool dirty) {
    if (dirty == _lastReportedDirty) return;
    _lastReportedDirty = dirty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDirtyChanged(dirty);
      }
    });
  }

  bool _configsEqual(GradingScaleConfig a, GradingScaleConfig b) {
    if (a.scaleType != b.scaleType ||
        a.missingWorkThreshold != b.missingWorkThreshold ||
        a.rules.length != b.rules.length) {
      return false;
    }
    for (var i = 0; i < a.rules.length; i++) {
      if (a.rules[i].grade != b.rules[i].grade ||
          a.rules[i].minScore != b.rules[i].minScore) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleSave() async {
    final error = _computeValidationError();
    if (error != null) return;
    final draft = GradingScaleConfig(
      subjectClassId: widget.initialConfig.subjectClassId,
      scaleType: _scaleType,
      rules: _tryParseDraftRules()!,
      missingWorkThreshold: int.parse(_thresholdCtrl.text.trim()),
    );
    final saved = await widget.onSave(draft);
    if (saved && mounted) {
      _syncDirty(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final validationError = _computeValidationError();
    final dirty = _isDirty;

    return AppSurfaceCard(
      title: 'เกณฑ์ตัดเกรดและเกณฑ์งานค้าง (ร)',
      subtitle: 'ปรับระบบเกรดและจำนวนงานค้างสำหรับแนะนำสถานะ ร',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<GradingScaleType>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<GradingScaleType>>[
              ButtonSegment(
                value: GradingScaleType.scale0To4,
                label: Text(
                  '0-4',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              ButtonSegment(
                value: GradingScaleType.scaleAToF,
                label: Text(
                  'A-F',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              ButtonSegment(
                value: GradingScaleType.custom,
                label: Text(
                  'กำหนดเอง',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
            selected: <GradingScaleType>{_scaleType},
            onSelectionChanged: (selection) => _applyScaleType(selection.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _thresholdCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              setState(() {});
              _notifyDirtyIfChanged();
            },
            decoration: const InputDecoration(
              labelText: 'เกณฑ์งานค้างสำหรับแนะนำเกรด ร (ชิ้น)',
              helperText: 'เช่น ค้างส่งตั้งแต่ 3 ชิ้นขึ้นไป ให้แนะนำสถานะ ร',
              suffixText: 'ชิ้น',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'ช่วงคะแนนตัดเกรด',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _rows.add(_EditableTierRow(grade: '', minScore: '0'));
                  });
                  _notifyDirtyIfChanged();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่มช่วงเกรด'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            GradingScaleTierRow(
              gradeController: _rows[i].gradeCtrl,
              minScoreController: _rows[i].minScoreCtrl,
              canRemove: _rows.length > 1,
              onChanged: () {
                setState(() {});
                _notifyDirtyIfChanged();
              },
              onRemove: () {
                setState(() {
                  _rows.removeAt(i).dispose();
                });
                _notifyDirtyIfChanged();
              },
            ),
          if (validationError != null) ...[
            const SizedBox(height: 8),
            AppFeedbackBanner(
              type: AppFeedbackType.error,
              message: validationError,
            ),
          ],
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: widget.isSaving || !dirty
                    ? null
                    : () => setState(
                        () => _hydrateFrom(
                          widget.initialConfig,
                          notifyParent: true,
                        ),
                      ),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('คืนค่าเดิม'),
              ),
              FilledButton.icon(
                onPressed:
                    widget.isSaving || !dirty || validationError != null
                    ? null
                    : _handleSave,
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('บันทึกเกณฑ์ตัดเกรด'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
