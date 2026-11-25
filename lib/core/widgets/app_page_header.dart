import 'package:flutter/material.dart';

/// Standard page header: title (+ optional inline [titleMeta]) on the left and
/// a single-row right-aligned action bar on wide screens (`>= 720px`).
///
/// Uses `Expanded` for the title side and `MainAxisSize.min` for actions so
/// buttons stay on one row and always sit flush against the right edge of the
/// container — even when only a single icon button (`⋯`) is present.
/// Stacks vertically below `720px` so narrow screens (`320px–640px`) never
/// overflow.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.titleMeta,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
  });

  static const double compactBreakpoint = 720;

  final String title;

  /// Optional subtle inline metadata placed beside [title] (e.g. today's Thai
  /// date on Dashboard) without adding a second row or competing with [actions].
  final Widget? titleMeta;

  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < compactBreakpoint;

        final titleText = Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (isCompact ? textTheme.titleLarge : textTheme.headlineSmall)
              ?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
        );

        final Widget titleHeadline = titleMeta == null
            ? titleText
            : Wrap(
                spacing: 10,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [titleText, titleMeta!],
              );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            titleHeadline,
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        );

        final headingRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(child: titleBlock),
          ],
        );

        final Widget mainArea;
        if (actions.isEmpty) {
          mainArea = headingRow;
        } else if (isCompact) {
          mainArea = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              headingRow,
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          );
        } else {
          mainArea = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: headingRow),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ],
          );
        }

        if (bottom == null) {
          return mainArea;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [mainArea, const SizedBox(height: 12), bottom!],
        );
      },
    );
  }
}
