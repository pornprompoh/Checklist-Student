import 'package:flutter/material.dart';

/// Flat hairline-bordered surface card (`16px` radius, `1px` `outlineVariant`)
/// with optional desktop hover highlight (subtle tinted border + soft shadow)
/// and click cursor when interactive.
class AppSurfaceCard extends StatefulWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.enableHoverHighlight = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  /// Enables subtle desktop hover border + tinted shadow lift even when actions
  /// live on buttons inside the card rather than a whole-card [onTap].
  final bool enableHoverHighlight;

  @override
  State<AppSurfaceCard> createState() => _AppSurfaceCardState();
}

class _AppSurfaceCardState extends State<AppSurfaceCard> {
  bool _isHovered = false;

  bool get _tracksHover => widget.onTap != null || widget.enableHoverHighlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasHeader = widget.title != null || widget.trailing != null;
    final radius = BorderRadius.circular(16);
    final hovered = _tracksHover && _isHovered;

    final effectiveBorderColor = hovered
        ? colorScheme.primary.withValues(alpha: 0.4)
        : (widget.borderColor ?? colorScheme.outlineVariant);

    final content = Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 12),
                  widget.trailing!,
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
          widget.child,
        ],
      ),
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: effectiveBorderColor),
        boxShadow: hovered
            ? <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: widget.onTap == null
            ? content
            : InkWell(
                borderRadius: radius,
                mouseCursor: SystemMouseCursors.click,
                onTap: widget.onTap,
                child: content,
              ),
      ),
    );

    if (!_tracksHover) {
      return card;
    }
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: card,
    );
  }
}
