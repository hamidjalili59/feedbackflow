import 'package:web/web.dart' as web;

/// Opens the current page path using the feedbackflow:// custom URL scheme.
/// If the app is installed, Android will intercept and open it.
/// If not installed, nothing visible happens (the browser can't handle the scheme).
void openDeepLink() {
  final path = web.window.location.pathname;
  final deepLink = 'feedbackflow:/$path';
  // Use window.location to trigger the scheme. On Android Chrome, this
  // will prompt "Open in app?" if the app is installed.
  web.window.location.href = deepLink;
}
