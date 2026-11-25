import 'package:flutter/material.dart';

/// Standard page header: title + short description on the left and a wrapping
/// action bar on the right. Stacks cleanly below `640px` using the closed
/// spacing scale (`4, 8, 12, 16`).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
  });

  static const double compactBreakpoint = 640;

  final String title;
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

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (isCompact ? textTheme.titleLarge : textTheme.headlineSmall)
                  ?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
            ),
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

        final actionWrap = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );

        final Widget mainArea;
        if (actions.isEmpty) {
          mainArea = headingRow;
        } else if (isCompact) {
          mainArea = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [headingRow, const SizedBox(height: 12), actionWrap],
          );
        } else {
          mainArea = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: headingRow),
              const SizedBox(width: 16),
              Flexible(flex: 2, child: actionWrap),
            ],
          );
        }

        if (bottom == null) {
          return mainArea;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [mainArea, const SizedBox(height: 16), bottom!],
        );
      },
    );
  }
}
