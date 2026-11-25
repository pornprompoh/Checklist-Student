import 'package:flutter/material.dart';

/// Primary Indigo Slate seed color defined in `docs/ARCHITECTURE.md`.
const Color seedColor = Color(0xFF3B5BDB);

/// Soft neutral canvas behind cards (Light Mode).
const Color lightCanvasColor = Color(0xFFF6F8FB);

/// Soft neutral canvas behind cards (Dark Mode — deep slate, never pure black).
const Color darkCanvasColor = Color(0xFF0F141E);

/// Light Mode: crisp white surfaces on a cool neutral canvas with hairline
/// `#E2E8F0` borders and WCAG-AA slate text for long classroom sessions.
final ColorScheme lightColorScheme =
    ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: seedColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE5EBFF),
      onPrimaryContainer: const Color(0xFF1A2B73),
      secondary: const Color(0xFF475569),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEBF0F7),
      onSecondaryContainer: const Color(0xFF1E293B),
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF475569),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8FAFC),
      surfaceContainer: const Color(0xFFF1F5F9),
      surfaceContainerHigh: const Color(0xFFEAEFF6),
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      outline: const Color(0xFF94A3B8),
      outlineVariant: const Color(0xFFE2E8F0),
      shadow: const Color(0xFF1E293B),
      surfaceTint: Colors.transparent,
    );

/// Dark Mode: deep blue-slate canvas with lifted `#171F2E` surfaces,
/// `#273247` hairlines, and muted slate copy that stays crisp without glare.
final ColorScheme darkColorScheme =
    ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF9DB0FF),
      onPrimary: const Color(0xFF0E1B59),
      primaryContainer: const Color(0xFF233166),
      onPrimaryContainer: const Color(0xFFE0E7FF),
      secondary: const Color(0xFF94A3B8),
      onSecondary: const Color(0xFF0F172A),
      secondaryContainer: const Color(0xFF222D42),
      onSecondaryContainer: const Color(0xFFD8E0EE),
      surface: const Color(0xFF171F2E),
      onSurface: const Color(0xFFE5ECF6),
      onSurfaceVariant: const Color(0xFFA0AEC4),
      surfaceContainerLowest: const Color(0xFF121926),
      surfaceContainerLow: const Color(0xFF1B2436),
      surfaceContainer: const Color(0xFF202B3E),
      surfaceContainerHigh: const Color(0xFF263348),
      surfaceContainerHighest: const Color(0xFF2D3A52),
      outline: const Color(0xFF5A6B86),
      outlineVariant: const Color(0xFF273247),
      shadow: const Color(0xFF05080F),
      surfaceTint: Colors.transparent,
    );

/// Semantic color tokens for classroom attendance statuses and academic risk
/// indicators. Every foreground/container pair meets WCAG AA (>= 4.5:1).
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
    present: Color(0xFF15703B),
    presentContainer: Color(0xFFE3F6EA),
    late: Color(0xFF9A4A07),
    lateContainer: Color(0xFFFDF1D8),
    leave: Color(0xFF1D4ED8),
    leaveContainer: Color(0xFFE2ECFE),
    absent: Color(0xFFB42318),
    absentContainer: Color(0xFFFDE8E6),
    success: Color(0xFF15703B),
    successContainer: Color(0xFFE3F6EA),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFFDF3D3),
    danger: Color(0xFFB42318),
    dangerContainer: Color(0xFFFDE8E6),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    present: Color(0xFF7EE2B0),
    presentContainer: Color(0xFF143628),
    late: Color(0xFFF8CF6B),
    lateContainer: Color(0xFF3A2C10),
    leave: Color(0xFF9CC3FF),
    leaveContainer: Color(0xFF182B4A),
    absent: Color(0xFFFFA8A0),
    absentContainer: Color(0xFF43191C),
    success: Color(0xFF7EE2B0),
    successContainer: Color(0xFF143628),
    warning: Color(0xFFF5D46A),
    warningContainer: Color(0xFF3A3110),
    danger: Color(0xFFFFA8A0),
    dangerContainer: Color(0xFF43191C),
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
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      present: mix(present, other.present),
      presentContainer: mix(presentContainer, other.presentContainer),
      late: mix(late, other.late),
      lateContainer: mix(lateContainer, other.lateContainer),
      leave: mix(leave, other.leave),
      leaveContainer: mix(leaveContainer, other.leaveContainer),
      absent: mix(absent, other.absent),
      absentContainer: mix(absentContainer, other.absentContainer),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
      danger: mix(danger, other.danger),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
    );
  }
}
