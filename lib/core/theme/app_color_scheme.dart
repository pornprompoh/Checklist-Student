import 'package:flutter/material.dart';

/// Primary Indigo Slate seed color defined in `docs/ARCHITECTURE.md`.
const Color seedColor = Color(0xFF3B5BDB);

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
);

/// Semantic color tokens for classroom attendance statuses and academic risk
/// indicators, supporting both Light Mode and Dark Mode cleanly.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.present,
    required this.presentContainer,
    required this.late,
    required this.lateContainer,
    required this.leave,
    required this.leaveContainer,
    required this.absent,
    required this.absentContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
  });

  final Color present;
  final Color presentContainer;
  final Color late;
  final Color lateContainer;
  final Color leave;
  final Color leaveContainer;
  final Color absent;
  final Color absentContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;

  static const AppSemanticColors light = AppSemanticColors(
    present: Color(0xFF1B7A43),
    presentContainer: Color(0xFFE7F7EE),
    late: Color(0xFFB45309),
    lateContainer: Color(0xFFFEF3C7),
    leave: Color(0xFF1D4ED8),
    leaveContainer: Color(0xFFDBEAFE),
    absent: Color(0xFFB91C1C),
    absentContainer: Color(0xFFFEE2E2),
    success: Color(0xFF15803D),
    successContainer: Color(0xFFDCFCE7),
    warning: Color(0xFFA16207),
    warningContainer: Color(0xFFFEF9C3),
    danger: Color(0xFFDC2626),
    dangerContainer: Color(0xFFFEE2E2),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    present: Color(0xFF6EE7B7),
    presentContainer: Color(0xFF0F3526),
    late: Color(0xFFFCD34D),
    lateContainer: Color(0xFF3F2B0D),
    leave: Color(0xFF93C5FD),
    leaveContainer: Color(0xFF172B4D),
    absent: Color(0xFFFCA5A5),
    absentContainer: Color(0xFF45161B),
    success: Color(0xFF86EFAC),
    successContainer: Color(0xFF0F3526),
    warning: Color(0xFFFDE047),
    warningContainer: Color(0xFF3E300E),
    danger: Color(0xFFFCA5A5),
    dangerContainer: Color(0xFF45161B),
  );

  /// Retrieves [AppSemanticColors] from the active [ThemeData], falling back
  /// safely based on the current theme brightness.
  static AppSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppSemanticColors copyWith({
    Color? present,
    Color? presentContainer,
    Color? late,
    Color? lateContainer,
    Color? leave,
    Color? leaveContainer,
    Color? absent,
    Color? absentContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
  }) {
    return AppSemanticColors(
      present: present ?? this.present,
      presentContainer: presentContainer ?? this.presentContainer,
      late: late ?? this.late,
      lateContainer: lateContainer ?? this.lateContainer,
      leave: leave ?? this.leave,
      leaveContainer: leaveContainer ?? this.leaveContainer,
      absent: absent ?? this.absent,
      absentContainer: absentContainer ?? this.absentContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      present: Color.lerp(present, other.present, t)!,
      presentContainer: Color.lerp(presentContainer, other.presentContainer, t)!,
      late: Color.lerp(late, other.late, t)!,
      lateContainer: Color.lerp(lateContainer, other.lateContainer, t)!,
      leave: Color.lerp(leave, other.leave, t)!,
      leaveContainer: Color.lerp(leaveContainer, other.leaveContainer, t)!,
      absent: Color.lerp(absent, other.absent, t)!,
      absentContainer: Color.lerp(absentContainer, other.absentContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
    );
  }
}
