import 'package:flutter/material.dart';

import '../errors/thai_error_mapper.dart';
import '../theme/app_color_scheme.dart';

/// Semantic severity levels for feedback banners and snackbars.
enum AppFeedbackType { info, success, warning, error }

/// Thai-language inline feedback banner with optional retry and dismiss actions.
///
/// Also provides static [showSnackBar] and [showErrorSnackBar] helpers that
/// format errors automatically via [ThaiErrorMapper].
class AppFeedbackBanner extends StatelessWidget {
  const AppFeedbackBanner({
    super.key,
    required this.message,
    this.type = AppFeedbackType.info,
    this.onRetry,
    this.retryLabel = 'ลองใหม่',
    this.onDismiss,
  });

  final String message;
  final AppFeedbackType type;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onDismiss;

  /// Displays a themed floating [SnackBar] with an optional retry action.
  static void showSnackBar(
    BuildContext context, {
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
    VoidCallback? onRetry,
    String retryLabel = 'ลองใหม่',
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final palette = _FeedbackPalette.resolve(context, type);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: palette.container,
          content: Row(
            children: [
              Icon(palette.icon, color: palette.foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.foreground,
                  ),
                ),
              ),
            ],
          ),
          action: onRetry == null
              ? null
              : SnackBarAction(
                  label: retryLabel,
                  textColor: palette.foreground,
                  onPressed: onRetry,
                ),
        ),
      );
  }

  /// Maps [error] into a user-friendly Thai message via [ThaiErrorMapper]
  /// and displays it as an error [SnackBar].
  static void showErrorSnackBar(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    String retryLabel = 'ลองใหม่',
  }) {
    showSnackBar(
      context,
      message: ThaiErrorMapper.map(error),
      type: AppFeedbackType.error,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _FeedbackPalette.resolve(context, type);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: palette.container,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.foreground.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    palette.icon,
                    color: palette.foreground,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.foreground,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ปิดข้อความ',
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: palette.foreground,
                    ),
                  ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.foreground,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(retryLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackPalette {
  const _FeedbackPalette({
    required this.container,
    required this.foreground,
    required this.icon,
  });

  final Color container;
  final Color foreground;
  final IconData icon;

  static _FeedbackPalette resolve(BuildContext context, AppFeedbackType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    return switch (type) {
      AppFeedbackType.info => _FeedbackPalette(
        container: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
        icon: Icons.info_outline_rounded,
      ),
      AppFeedbackType.success => _FeedbackPalette(
        container: semantic.successContainer,
        foreground: semantic.success,
        icon: Icons.check_circle_outline_rounded,
      ),
      AppFeedbackType.warning => _FeedbackPalette(
        container: semantic.warningContainer,
        foreground: semantic.warning,
        icon: Icons.warning_amber_rounded,
      ),
      AppFeedbackType.error => _FeedbackPalette(
        container: semantic.dangerContainer,
        foreground: semantic.danger,
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
