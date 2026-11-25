import 'package:flutter/material.dart';

/// Immutable option item for [ClassSelectorDropdown].
class ClassSelectorOption {
  const ClassSelectorOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Compact, readable subject-class dropdown designed for the right slot of
/// [ClassWorkspaceBar] (Desktop `260–360px` wide) or full-width on mobile so
/// subject codes and room names (e.g. `ว31101 วิทยาการคำนวณ 1 · ม.4/1`) stay
/// clearly visible without truncation.
class ClassSelectorDropdown extends StatelessWidget {
  const ClassSelectorDropdown({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.enabled = true,
  });

  final List<ClassSelectorOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final validId = options.any((o) => o.id == selectedId)
        ? selectedId
        : options.first.id;

    return DropdownButtonFormField<String>(
      key: ValueKey<String?>('class_selector_$validId'),
      initialValue: validId,
      isExpanded: true,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surface,
        prefixIcon: Icon(
          Icons.class_outlined,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<String>(
            value: option.id,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: !enabled
          ? null
          : (value) {
              if (value != null && value != validId) {
                onSelected(value);
              }
            },
    );
  }
}
