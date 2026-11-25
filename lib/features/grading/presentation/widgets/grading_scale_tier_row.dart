import 'package:flutter/material.dart';

/// Single editable grade-tier row (`grade` label + `minScore >=`) used inside
/// `GradingScaleEditorCard`.
class GradingScaleTierRow extends StatelessWidget {
  const GradingScaleTierRow({
    super.key,
    required this.gradeController,
    required this.minScoreController,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final TextEditingController gradeController;
  final TextEditingController minScoreController;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: gradeController,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'เกรด',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: minScoreController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'คะแนนขั้นต่ำ (>=)',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'ลบช่วงเกรดนี้',
            visualDensity: VisualDensity.compact,
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }
}
