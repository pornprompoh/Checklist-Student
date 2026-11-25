import 'in_app_browser_detector.dart';

/// Non-web stub implementation for VM and widget tests.
InAppBrowserInfo detectInAppBrowser() {
  return const InAppBrowserInfo(
    isInAppBrowser: false,
    isLineBrowser: false,
    appLabel: null,
    currentUrl: '',
    externalBrowserUrl: '',
  );
}

/// Non-web stub returning `false`.
bool openExternalBrowserUrl(String url) => false;
