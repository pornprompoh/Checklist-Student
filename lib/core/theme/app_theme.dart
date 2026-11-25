import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color_scheme.dart';

/// Material Design 3 theme definitions for Checklist-Student.
///
/// Flat hairline surfaces (`outlineVariant` 1px), concentric radii
/// (`8` inner · `10` buttons · `12` inputs/menus · `16` cards · `20` dialogs),
/// explicit hover/focus/pressed states, and Thai-safe line heights.
abstract final class AppTheme {
  /// Tabular digits for KPI counters, attendance totals, scores, and timers.
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static ThemeData get light => _buildTheme(
    colorScheme: lightColorScheme,
    semanticColors: AppSemanticColors.light,
    canvas: lightCanvasColor,
  );

  static ThemeData get dark => _buildTheme(
    colorScheme: darkColorScheme,
    semanticColors: AppSemanticColors.dark,
    canvas: darkCanvasColor,
  );

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme cs) {
    final t = GoogleFonts.notoSansThaiTextTheme(
      base,
    ).apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
    TextStyle? s(TextStyle? style, FontWeight weight, double height) =>
        style?.copyWith(fontWeight: weight, height: height);

    return t.copyWith(
      headlineMedium: s(t.headlineMedium, FontWeight.w700, 1.3),
      headlineSmall: s(t.headlineSmall, FontWeight.w700, 1.35),
      titleLarge: s(t.titleLarge, FontWeight.w700, 1.35),
      titleMedium: s(t.titleMedium, FontWeight.w600, 1.4),
      titleSmall: s(t.titleSmall, FontWeight.w600, 1.4),
      bodyLarge: s(t.bodyLarge, FontWeight.w400, 1.55),
      bodyMedium: s(t.bodyMedium, FontWeight.w400, 1.5),
      bodySmall: s(t.bodySmall, FontWeight.w400, 1.45),
      labelLarge: s(t.labelLarge, FontWeight.w600, 1.35),
      labelMedium: s(t.labelMedium, FontWeight.w500, 1.35),
      labelSmall: s(t.labelSmall, FontWeight.w600, 1.35),
    );
  }

  static WidgetStateProperty<Color?> _stateOverlay(Color base) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return base.withValues(alpha: 0.14);
        }
        if (states.contains(WidgetState.focused)) {
          return base.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return base.withValues(alpha: 0.08);
        }
        return null;
      });

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required AppSemanticColors semanticColors,
    required Color canvas,
  }) {
    final cs = colorScheme;
    final baseTheme = ThemeData(useMaterial3: true, colorScheme: cs);
    final textTheme = _buildTextTheme(baseTheme.textTheme, cs);
    final hairline = BorderSide(color: cs.outlineVariant);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    const buttonMinSize = Size(64, 42);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      hoverColor: cs.primary.withValues(alpha: 0.06),
      focusColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.notoSansThaiTextTheme(
        baseTheme.primaryTextTheme,
      ),
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        shape: Border(bottom: hairline),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: hairline,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.brightness == Brightness.dark
            ? cs.surfaceContainerLowest
            : cs.surfaceContainerLow,
        hoverColor: cs.primary.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        border: inputBorder(cs.outline),
        enabledBorder: inputBorder(cs.outlineVariant),
        disabledBorder: inputBorder(cs.outlineVariant.withValues(alpha: 0.6)),
        focusedBorder: inputBorder(cs.primary, 1.5),
        errorBorder: inputBorder(cs.error),
        focusedErrorBorder: inputBorder(cs.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 0,
          textStyle: textTheme.labelLarge,
        ).copyWith(overlayColor: _stateOverlay(cs.onPrimary)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ).copyWith(
          overlayColor: _stateOverlay(cs.primary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: cs.primary, width: 1.5);
            }
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: cs.primary.withValues(alpha: 0.5));
            }
            return BorderSide(color: cs.outline.withValues(alpha: 0.45));
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ).copyWith(overlayColor: _stateOverlay(cs.primary)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: _stateOverlay(cs.primary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surface,
        selectedColor: cs.primaryContainer,
        side: hairline,
        shape: StadiumBorder(side: hairline),
        labelStyle: textTheme.labelMedium?.copyWith(color: cs.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: cs.onPrimaryContainer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: cs.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow.withValues(alpha: 0.14),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hairline,
        ),
        textStyle: textTheme.bodyMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? cs.onSurface
                : cs.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(dividerColor: cs.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
        actionTextColor: cs.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1),
    );
  }
}
