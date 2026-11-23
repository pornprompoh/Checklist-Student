import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks active forms that currently hold unsaved edits so navigation chrome
/// (such as [AppShellScaffold] sidebar/bottom-bar tabs and sign-out actions)
/// can prompt before discarding changes.
class UnsavedChangesNotifier extends Notifier<bool> {
  final Set<Object> _dirtyOwners = <Object>{};

  @override
  bool build() => false;

  /// Registers or clears dirty state for a specific [owner] token.
  void setDirty(Object owner, bool isDirty) {
    if (!ref.mounted) {
      return;
    }
    final changed = isDirty
        ? _dirtyOwners.add(owner)
        : _dirtyOwners.remove(owner);
    if (changed) {
      state = _dirtyOwners.isNotEmpty;
    }
  }

  /// Clears all dirty owners after the user confirms discarding changes.
  void clearAll() {
    if (!ref.mounted) {
      return;
    }
    _dirtyOwners.clear();
    if (state) {
      state = false;
    }
  }
}

final unsavedChangesStateProvider =
    NotifierProvider<UnsavedChangesNotifier, bool>(UnsavedChangesNotifier.new);
