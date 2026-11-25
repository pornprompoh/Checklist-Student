import 'package:web/web.dart' as web;

import 'in_app_browser_detector.dart';

/// Flutter Web implementation using `package:web/web.dart` (zero `dart:html`).
InAppBrowserInfo detectInAppBrowser() {
  final userAgent = web.window.navigator.userAgent;
  final currentUrl = web.window.location.href;
  return parseInAppBrowserInfo(userAgent: userAgent, currentUrl: currentUrl);
}

/// Triggers LINE/external browser navigation via `window.location.assign`.
bool openExternalBrowserUrl(String url) {
  final target = url.trim();
  if (target.isEmpty) return false;
  web.window.location.assign(target);
  return true;
}
