import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'unsaved_changes_provider.dart';

/// Guards forms (such as settings or grading plan editors) against accidental
/// navigation away when unsaved edits exist.
///
/// Combines [PopScope] (for system/browser back navigation) with
/// [unsavedChangesStateProvider] (so [AppShellScaffold] sidebar/bottom-bar tab
/// switches and sign-out actions prompt the user as well).
class UnsavedChangesGuard extends ConsumerStatefulWidget {
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
  ConsumerState<UnsavedChangesGuard> createState() =>
      _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends ConsumerState<UnsavedChangesGuard> {
  final Object _ownerToken = Object();
  late final UnsavedChangesNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(unsavedChangesStateProvider.notifier);
    _scheduleSync(widget.hasUnsavedChanges);
  }

  @override
  void didUpdateWidget(covariant UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasUnsavedChanges != widget.hasUnsavedChanges) {
      _scheduleSync(widget.hasUnsavedChanges);
    }
  }

  @override
  void dispose() {
    Future<void>.microtask(() => _notifier.setDirty(_ownerToken, false));
    super.dispose();
  }

  void _scheduleSync(bool isDirty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _notifier.setDirty(_ownerToken, isDirty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldDiscard = await UnsavedChangesGuard.confirmDiscard(
          context,
          title: widget.title,
          message: widget.message,
        );
        if (shouldDiscard && context.mounted) {
          _notifier.setDirty(_ownerToken, false);
          Navigator.of(context).pop(result);
        }
      },
      child: widget.child,
    );
  }
}
