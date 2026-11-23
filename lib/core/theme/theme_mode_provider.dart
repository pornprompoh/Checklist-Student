import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the application's active [ThemeMode] (system / light / dark).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  /// Toggles between Light Mode and Dark Mode.
  ///
  /// When the current mode is [ThemeMode.system], pass [platformBrightness]
  /// (e.g., `Theme.of(context).brightness`) so the switch always flips to the
  /// opposite visible brightness.
  void toggleTheme({Brightness? platformBrightness}) {
    final isCurrentlyDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    state = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
