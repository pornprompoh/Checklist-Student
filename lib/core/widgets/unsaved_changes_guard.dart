import 'package:flutter/material.dart';

/// Guards forms (such as settings or grading plan editors) against accidental
/// navigation away when unsaved edits exist.
///
/// Uses [PopScope] with `onPopInvokedWithResult` for zero-warning compatibility.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
    this.title,
    this.message,
  });

  final bool hasUnsavedChanges;
  final Widget child;
  final String? title;
  final String? message;

  static const String defaultTitle = 'ยังไม่ได้บันทึกการเปลี่ยนแปลง';
  static const String defaultMessage =
      'หากออกจากหน้านี้ ข้อมูลที่แก้ไขไว้จะไม่ถูกบันทึก ต้องการออกหรือไม่?';

  /// Prompts the user to confirm discarding unsaved form changes.
  ///
  /// Returns `true` if the user chooses to leave without saving, or `false`
  /// if they choose to stay or dismiss the dialog.
  static Future<bool> confirmDiscard(
    BuildContext context, {
    String? title,
    String? message,
    String stayLabel = 'อยู่หน้านี้ต่อ',
    String discardLabel = 'ออกโดยไม่บันทึก',
  }) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title ?? defaultTitle),
          content: Text(message ?? defaultMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(stayLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(discardLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldDiscard = await confirmDiscard(
          context,
          title: title,
          message: message,
        );
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    );
  }
}
