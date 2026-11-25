import 'package:flutter/material.dart';

/// Ultra-thin (`4px`) fade-on-scroll scrollbar for long-scrolling zones.
///
/// Remains completely invisible while idle (`thumbVisibility: false`) and
/// gently fades in only while scrolling (`fadeDuration: 200ms`,
/// `timeToFade: 600ms`).
class AppSubtleScrollbar extends StatelessWidget {
  const AppSubtleScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.scrollbarOrientation,
  });

  final Widget child;
  final ScrollController? controller;
  final ScrollNotificationPredicate notificationPredicate;
  final ScrollbarOrientation? scrollbarOrientation;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return RawScrollbar(
      controller: controller,
      thumbVisibility: false,
      trackVisibility: false,
      interactive: true,
      thickness: 4.0,
      radius: const Radius.circular(999),
      fadeDuration: const Duration(milliseconds: 200),
      timeToFade: const Duration(milliseconds: 600),
      thumbColor: onSurface.withValues(alpha: 0.20),
      notificationPredicate: notificationPredicate,
      scrollbarOrientation: scrollbarOrientation,
      child: child,
    );
  }
}
