import 'in_app_browser_detector_stub.dart'
    if (dart.library.js_interop) 'in_app_browser_detector_web.dart'
    as impl;

/// Detection result describing whether the app is opened inside a chat/social
/// in-app browser (LINE, Facebook, Instagram) and providing a safe external URL.
class InAppBrowserInfo {
  const InAppBrowserInfo({
    required this.isInAppBrowser,
    required this.isLineBrowser,
    this.appLabel,
    required this.currentUrl,
    required this.externalBrowserUrl,
  });

  final bool isInAppBrowser;
  final bool isLineBrowser;
  final String? appLabel;
  final String currentUrl;
  final String externalBrowserUrl;
}

/// Pure parser inspecting [userAgent] and [currentUrl] to detect LINE,
/// Facebook, or Instagram in-app browsers and append `openExternalBrowser=1`
/// without clobbering existing query parameters.
InAppBrowserInfo parseInAppBrowserInfo({
  required String userAgent,
  required String currentUrl,
}) {
  final isLine = userAgent.contains('Line/');
  final isFacebook = userAgent.contains('FBAN') || userAgent.contains('FBAV');
  final isInstagram = userAgent.contains('Instagram');
  final isInApp = isLine || isFacebook || isInstagram;

  final String? appLabel = isLine
      ? 'LINE'
      : (isFacebook ? 'Facebook' : (isInstagram ? 'Instagram' : null));

  return InAppBrowserInfo(
    isInAppBrowser: isInApp,
    isLineBrowser: isLine,
    appLabel: appLabel,
    currentUrl: currentUrl,
    externalBrowserUrl: buildExternalBrowserUrl(currentUrl),
  );
}

/// Appends `openExternalBrowser=1` to [rawUrl] while preserving all existing
/// path segments, query parameters, and fragments.
String buildExternalBrowserUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return trimmed;
  final updatedQuery = Map<String, String>.from(uri.queryParameters)
    ..['openExternalBrowser'] = '1';
  return uri.replace(queryParameters: updatedQuery).toString();
}

/// Detects in-app browsers on Flutter Web (safe no-op defaults on VM/tests).
InAppBrowserInfo detectInAppBrowser() => impl.detectInAppBrowser();

/// Navigates to [url] externally on Flutter Web (no-op returning `false` on VM).
bool openExternalBrowserUrl(String url) => impl.openExternalBrowserUrl(url);
