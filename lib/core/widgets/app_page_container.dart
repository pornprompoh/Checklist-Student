import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Single Source of Truth for teacher page outer padding, content max-width,
/// and vertical rhythm across Desktop, Tablet, and Mobile viewports.
abstract final class AppPageLayout {
  static const double desktopBreakpoint = 900.0;
  static const double tabletBreakpoint = 600.0;
  static const double standardMaxWidth = 1320.0;
  static const double sectionGap = 16.0;

  /// Standard responsive outer padding shared identically across all teacher pages:
  /// - Desktop (`>= 900px`): `28px` horizontal, `24px` vertical
  /// - Tablet (`600..899px`): `20px` all around
  /// - Mobile (`< 600px`): `16px` all around
  static EdgeInsets outerPaddingForWidth(double width) {
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.fromLTRB(28, 24, 28, 24);
    }
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(16);
  }

  /// Standard vertical gap between [AppPageHeader] and the first body section:
  /// `20px` on Desktop/Tablet, `16px` on Mobile.
  static double headerGapForWidth(double width) =>
      width >= tabletBreakpoint ? 20.0 : 16.0;
}

/// Unified teacher page spatial container locking `Alignment.topLeft`,
/// responsive outer padding (`28/20/16px`), `standardMaxWidth` (`1320px`), and
/// identical tight width across both [header] and [child] so right edges always
/// align cleanly in both `standardMaxWidth` and `fullBleedWidth` modes.
class AppPageContainer extends StatelessWidget {
  /// Standard vertical scrolling page shell.
  const AppPageContainer.scrollable({
    super.key,
    this.header,
    required this.child,
    this.maxWidth = AppPageLayout.standardMaxWidth,
    this.fullBleedWidth = false,
    this.scrollController,
    this.primary,
    this.headerGap,
  }) : _isViewport = false;

  /// Full-viewport non-scrolling outer shell for pages with independent inner
  /// scroll panes (e.g., Split-Pane rosters, Export Studio, or Frozen Gradebook).
  const AppPageContainer.viewport({
    super.key,
    this.header,
    required this.child,
    this.maxWidth = AppPageLayout.standardMaxWidth,
    this.fullBleedWidth = false,
    this.headerGap,
  }) : _isViewport = true,
       scrollController = null,
       primary = null;

  /// Optional top header widget (typically [AppPageHeader] or a header wrapper).
  final Widget? header;

  /// Main page body rendered below [header]. In [AppPageContainer.viewport],
  /// this child is wrapped in [Expanded].
  final Widget child;

  /// Maximum content width when [fullBleedWidth] is `false`.
  final double maxWidth;

  /// When `true`, expands horizontally across the full available viewport width
  /// while preserving the exact same left/top outer padding as standard pages.
  final bool fullBleedWidth;

  /// Optional scroll controller for [AppPageContainer.scrollable].
  final ScrollController? scrollController;

  /// Optional `primary` flag passed to [SingleChildScrollView] when
  /// [scrollController] is null.
  final bool? primary;

  /// Optional override for the vertical spacing between [header] and [child].
  final double? headerGap;

  final bool _isViewport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = AppPageLayout.outerPaddingForWidth(
          constraints.maxWidth,
        );
        final resolvedGap =
            headerGap ?? AppPageLayout.headerGapForWidth(constraints.maxWidth);
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - padding.horizontal,
        );
        final targetWidth = fullBleedWidth
            ? availableWidth
            : math.min(availableWidth, maxWidth);

        if (_isViewport) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[header!, SizedBox(height: resolvedGap)],
              Expanded(child: child),
            ],
          );
          return Padding(
            padding: padding,
            child: _wrapWidth(content, targetWidth),
          );
        }

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[header!, SizedBox(height: resolvedGap)],
            child,
          ],
        );
        return SingleChildScrollView(
          controller: scrollController,
          primary: scrollController == null ? primary : false,
          padding: padding,
          child: _wrapWidth(content, targetWidth),
        );
      },
    );
  }

  Widget _wrapWidth(Widget content, double targetWidth) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: targetWidth, child: content),
    );
  }
}
