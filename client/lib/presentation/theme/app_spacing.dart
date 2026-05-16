import 'package:flutter/widgets.dart';

/// Shared spacing and radius scale used across the app.
///
/// The scale follows a 4dp baseline and keeps pages/cards/forms visually
/// consistent on mobile and web.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusXxl = 28;

  static const EdgeInsets page = EdgeInsets.all(md);
  static const EdgeInsets pageWide = EdgeInsets.all(xl);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardLarge = EdgeInsets.all(lg);
  static const EdgeInsets field = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  static const SizedBox gapXxs = SizedBox(height: xxs);
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);

  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
}
