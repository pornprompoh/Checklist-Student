import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color_scheme.dart';

/// Material Design 3 theme definitions for Checklist-Student.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(
    colorScheme: lightColorScheme,
    semanticColors: AppSemanticColors.light,
  );

  static ThemeData get dark => _buildTheme(
    colorScheme: darkColorScheme,
    semanticColors: AppSemanticColors.dark,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required AppSemanticColors semanticColors,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    final textTheme = GoogleFonts.notoSansThaiTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.notoSansThaiTextTheme(
        baseTheme.primaryTextTheme,
      ),
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
