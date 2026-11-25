import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/grade_result.dart';

/// Semantic grade & special-grade (`ร` / `มส`) indicator displayed in
/// [FrozenGradeGrid] and [StudentProfileDrawer] with tabular figures.
class SpecialGradeBadge extends StatelessWidget {
  const SpecialGradeBadge({
    super.key,
    required this.result,
    this.onTap,
    this.compact = false,
  });

  final GradeResult result;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final override = result.specialGradeOverride;
    final advice = result.specialGradeAdvice;

    Widget content;
    if (override != null && override.trim().isNotEmpty) {
      content = _TagPill(
        label: override,
        background: semantic.dangerContainer,
        foreground: semantic.danger,
        compact: compact,
        emphasized: true,
      );
    } else {
      final subBadge = _buildSubBadge(context);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.evaluatedGrade,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? textTheme.titleSmall : textTheme.titleLarge)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  fontFeatures: AppTheme.tabularFigures,
                ),
          ),
          if (subBadge != null) ...[
            SizedBox(height: compact ? 2 : 4),
            subBadge,
          ],
        ],
      );
    }

    if (advice.reasons.isNotEmpty && override == null) {
      content = Tooltip(message: advice.reasons.join('\n'), child: content);
    } else if (override == null &&
        (result.wasRResolved || result.wasMsResolved)) {
      content = Tooltip(message: _resolvedTooltip(), child: content);
    }

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 2 : 4,
        ),
        child: content,
      ),
    );
  }

  Widget? _buildSubBadge(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final advice = result.specialGradeAdvice;

    if (advice.recommendR || advice.recommendMs) {
      final label = advice.recommendR && advice.recommendMs
          ? 'แนะนำ ร/มส'
          : (advice.recommendMs ? 'แนะนำ มส' : 'แนะนำ ร');
      return _TagPill(
        label: label,
        background: semantic.warningContainer,
        foreground: semantic.warning,
        compact: compact,
        emphasized: false,
      );
    }

    if (result.wasRResolved || result.wasMsResolved) {
      final label = result.wasRResolved && result.wasMsResolved
          ? 'เคยแก้ ร/มส'
          : (result.wasMsResolved ? 'เคยแก้ มส' : 'เคยแก้ ร');
      return _TagPill(
        label: label,
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
        compact: compact,
        emphasized: false,
      );
    }
    return null;
  }

  String _resolvedTooltip() {
    final resolvedAt = result.resolvedGradeAt;
    if (resolvedAt == null) {
      return 'ประวัติฝั่งครู: นักเรียนดำเนินการแก้เกรดพิเศษผ่านแล้ว';
    }
    return 'แก้เกรดพิเศษผ่านเมื่อ ${ThaiDateFormatter.formatShortDate(resolvedAt.toLocal())}';
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.compact,
    required this.emphasized,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool compact;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = emphasized
        ? (compact ? textTheme.labelLarge : textTheme.titleSmall)
        : textTheme.labelSmall;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? (compact ? 10 : 12) : (compact ? 5 : 8),
        vertical: emphasized ? (compact ? 3 : 5) : (compact ? 1 : 2),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
