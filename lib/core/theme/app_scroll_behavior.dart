import 'package:flutter/material.dart';

/// Global [ScrollBehavior] that suppresses Flutter Web's automatic persistent
/// scrollbars across the application.
///
/// Key long-scrolling panes opt into fade-on-scroll feedback explicitly using
/// `AppSubtleScrollbar`.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
