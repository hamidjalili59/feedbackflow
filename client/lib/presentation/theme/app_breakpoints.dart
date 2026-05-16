import 'package:flutter/widgets.dart';

/// Material 3-aligned responsive breakpoints used across the app.
///
/// - compact:  phones in portrait (<600 dp)
/// - medium:   tablets in portrait, large phones in landscape (600–905 dp)
/// - expanded: tablets in landscape, small desktops (905–1240 dp)
/// - large:    desktop (>=1240 dp)
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 905;
  static const double expanded = 1240;

  /// Maximum readable content width on very wide screens.
  static const double contentMax = 1180;

  /// Maximum width for narrow content blocks (login card, public form).
  static const double narrowContentMax = 460;
}

enum AppWindowSize { compact, medium, expanded, large }

extension AppWindowSizeX on AppWindowSize {
  bool get isCompact => this == AppWindowSize.compact;
  bool get isMediumOrUp => index >= AppWindowSize.medium.index;
  bool get isExpandedOrUp => index >= AppWindowSize.expanded.index;
}

AppWindowSize windowSizeFromWidth(double width) {
  if (width < AppBreakpoints.compact) return AppWindowSize.compact;
  if (width < AppBreakpoints.medium) return AppWindowSize.medium;
  if (width < AppBreakpoints.expanded) return AppWindowSize.expanded;
  return AppWindowSize.large;
}

extension BuildContextWindow on BuildContext {
  AppWindowSize get windowSize =>
      windowSizeFromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompactWidth =>
      MediaQuery.sizeOf(this).width < AppBreakpoints.compact;

  bool get isMediumWidth {
    final w = MediaQuery.sizeOf(this).width;
    return w >= AppBreakpoints.compact && w < AppBreakpoints.medium;
  }

  bool get isExpandedWidth =>
      MediaQuery.sizeOf(this).width >= AppBreakpoints.medium;
}
