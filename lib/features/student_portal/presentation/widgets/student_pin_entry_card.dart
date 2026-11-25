import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/services/student_pin_validator_service.dart';
import 'student_pin_status_box.dart';

/// Step 2 card supporting both first-time 6-digit PIN setup (2 fields) and
/// existing PIN verification (1 field) with a live 1-second lockout countdown.
///
/// PIN values live strictly in widget memory and are never persisted.
class StudentPinEntryCard extends StatefulWidget {
  const StudentPinEntryCard({
    super.key,
    required this.studentCode,
    required this.isSetupMode,
    required this.isBusy,
    this.remainingAttempts,
    this.lockedUntil,
    this.errorMessage,
    required this.onSubmitSetup,
    required this.onSubmitVerify,
    required this.onLockoutExpired,
    required this.onChangeStudent,
  });

  final String studentCode;
  final bool isSetupMode;
  final bool isBusy;
  final int? remainingAttempts;
  final DateTime? lockedUntil;
  final String? errorMessage;
  final void Function(String pin, String confirmPin) onSubmitSetup;
  final ValueChanged<String> onSubmitVerify;
  final VoidCallback onLockoutExpired;
  final VoidCallback onChangeStudent;

  @override
  State<StudentPinEntryCard> createState() => _StudentPinEntryCardState();
}

class _StudentPinEntryCardState extends State<StudentPinEntryCard> {
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _obscurePin = true;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  bool get _isLocked {
    final until = widget.lockedUntil;
    return until != null && until.toUtc().isAfter(_now.toUtc());
  }

  @override
  void initState() {
    super.initState();
    _syncCountdownTimer();
  }

  @override
  void didUpdateWidget(covariant StudentPinEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockedUntil != widget.lockedUntil) {
      _now = DateTime.now();
      _syncCountdownTimer();
    }
    if (oldWidget.isSetupMode != widget.isSetupMode ||
        oldWidget.studentCode != widget.studentCode) {
      _pinCtrl.clear();
      _confirmPinCtrl.clear();
    }
  }

  void _syncCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (!_isLocked) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final current = DateTime.now();
      setState(() => _now = current);
      final until = widget.lockedUntil;
      if (until == null || !until.toUtc().isAfter(current.toUtc())) {
        timer.cancel();
        _countdownTimer = null;
        widget.onLockoutExpired();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isBusy || _isLocked) return;
    if (widget.isSetupMode) {
      widget.onSubmitSetup(_pinCtrl.text, _confirmPinCtrl.text);
    } else {
      widget.onSubmitVerify(_pinCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locked = _isLocked;
    final digitsOnly = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(StudentPinValidatorService.pinLength),
    ];
    final hasStatus =
        locked ||
        widget.errorMessage != null ||
        (!widget.isSetupMode &&
            widget.remainingAttempts != null &&
            widget.remainingAttempts! < 5);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
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
                widget.isSetupMode
                    ? 'ตั้งรหัส PIN 6 หลักครั้งแรก'
                    : 'ยืนยันรหัส PIN 6 หลัก',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'รหัส ${widget.studentCode}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isSetupMode
                ? 'กำหนดรหัสตัวเลข 6 หลักเพื่อใช้ดูคะแนนและเวลาเรียนส่วนตัว (จดจำไว้ให้ดี)'
                : 'กรอกรหัส PIN 6 หลักที่ตั้งไว้เพื่อดูข้อมูลการเรียนส่วนตัว',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            enabled: !widget.isBusy && !locked,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
            inputFormatters: digitsOnly,
            textInputAction: widget.isSetupMode
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: widget.isSetupMode ? null : (_) => _submit(),
            style: textTheme.titleMedium?.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
            decoration: InputDecoration(
              labelText: widget.isSetupMode
                  ? 'ตั้งรหัส PIN 6 หลัก'
                  : 'รหัส PIN 6 หลัก',
              hintText: 'ตัวเลข 6 หลัก',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePin ? 'แสดงรหัส PIN' : 'ซ่อนรหัส PIN',
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                icon: Icon(
                  _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (widget.isSetupMode) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinCtrl,
              enabled: !widget.isBusy && !locked,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: digitsOnly,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: textTheme.titleMedium?.copyWith(
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
              ),
              decoration: const InputDecoration(
                labelText: 'ยืนยันรหัส PIN 6 หลักอีกครั้ง',
                hintText: 'กรอกตัวเลข 6 หลักให้ตรงกัน',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
            ),
          ],
          if (hasStatus) ...[
            const SizedBox(height: 12),
            StudentPinStatusBox(
              isSetupMode: widget.isSetupMode,
              isLocked: locked,
              now: _now,
              remainingAttempts: widget.remainingAttempts,
              lockedUntil: widget.lockedUntil,
              errorMessage: widget.errorMessage,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (widget.isBusy || locked) ? null : _submit,
            child: widget.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.isSetupMode
                        ? 'ตั้งรหัส PIN และเข้าดูข้อมูล'
                        : 'ยืนยันรหัส PIN',
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'ลืมรหัส PIN? กรุณาแจ้งครูผู้สอนให้รีเซต PIN ให้',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: widget.isBusy ? null : widget.onChangeStudent,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('เปลี่ยนรหัสนักเรียน'),
          ),
        ],
      ),
    );
  }
}
