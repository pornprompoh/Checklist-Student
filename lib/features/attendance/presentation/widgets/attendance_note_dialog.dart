import 'package:flutter/material.dart';

/// Lightweight dialog for editing a student's per-session attendance note or
/// a session-level note, complete with Thai quick-fill chips.
class AttendanceNoteDialog extends StatefulWidget {
  const AttendanceNoteDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.initialNote = '',
    this.quickSuggestions = defaultStudentSuggestions,
  });

  static const List<String> defaultStudentSuggestions = <String>[
    'ลาป่วย',
    'ลากิจ',
    'กิจกรรมโรงเรียน',
    'ไปห้องพยาบาล',
  ];

  final String title;
  final String? subtitle;
  final String initialNote;
  final List<String> quickSuggestions;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String initialNote = '',
    List<String> quickSuggestions = defaultStudentSuggestions,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => AttendanceNoteDialog(
        title: title,
        subtitle: subtitle,
        initialNote: initialNote,
        quickSuggestions: quickSuggestions,
      ),
    );
  }

  @override
  State<AttendanceNoteDialog> createState() => _AttendanceNoteDialogState();
}

class _AttendanceNoteDialogState extends State<AttendanceNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              Text(
                widget.subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.quickSuggestions.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in widget.quickSuggestions)
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () {
                        _controller.text = suggestion;
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ',
                hintText: 'พิมพ์หมายเหตุเพิ่มเติม (เว้นว่างเพื่อลบ)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('ตกลง'),
        ),
      ],
    );
  }
}
