import 'package:flutter_web_plugins/url_strategy.dart';

/// Configures Path URL Strategy on Flutter Web so clean URLs such as
/// `/student/<teacherCode>?openExternalBrowser=1` resolve without `#`.
///
/// Safe to invoke on all platforms (no-op on non-web VM/test targets).
void configureAppUrlStrategy() {
  usePathUrlStrategy();
}
