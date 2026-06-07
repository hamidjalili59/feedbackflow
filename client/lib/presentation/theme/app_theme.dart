import 'package:flutter/material.dart';

import 'app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static const primary = Color(0xFF4169F5);
  static const primaryStrong = Color(0xFF3658D9);
  static const background = Color(0xFFF4F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF181B34);
  static const muted = Color(0xFF858BA6);
  static const success = Color(0xFF32C76F);
  static const warning = Color(0xFF7C6CF2);
  static const danger = Color(0xFFFF525D);

  /// AbarFaNum keeps Persian and Latin digits visually aligned with the mockups.
  static const String primaryFontFamily = 'AbarFaNum';

  /// Chinese glyphs should not use the Persian UI font. We intentionally use
  /// common system CJK font families first so Flutter Web/Desktop can render
  /// Chinese with the platform's native typeface without bundling a large font.
  static const String chineseFontFamily = 'Noto Sans SC';

  static ThemeData light([Locale? locale]) =>
      _build(Brightness.light, locale: locale);
  static ThemeData dark([Locale? locale]) =>
      _build(Brightness.dark, locale: locale);

  static ThemeData _build(Brightness brightness, {Locale? locale}) {
    final dark = brightness == Brightness.dark;
    final useChineseFont = locale?.languageCode == 'zh';
    final fontFamily = useChineseFont ? chineseFontFamily : primaryFontFamily;
    final fallbackFonts = useChineseFont
        ? const [
            'Noto Sans CJK SC',
            'Microsoft YaHei',
            'PingFang SC',
            'Heiti SC',
            'SimHei',
            'Noto Sans',
            'Roboto',
            'Arial',
          ]
        : const ['Abar', 'AbarNoEn', 'Noto Sans Arabic', 'Noto Sans', 'Roboto'];

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
          primary: primary,
          surface: dark ? const Color(0xFF151A2D) : surface,
          error: danger,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: dark
              ? const Color(0xFF25346B)
              : const Color(0xFFE8EEFF),
          onPrimaryContainer: dark ? const Color(0xFFDDE5FF) : primaryStrong,
          secondary: success,
          tertiary: warning,
          surface: dark ? const Color(0xFF151A2D) : surface,
          onSurface: dark ? const Color(0xFFEFF2FF) : ink,
          onSurfaceVariant: dark ? const Color(0xFFADB4CF) : muted,
          outlineVariant: dark
              ? const Color(0xFF303955)
              : const Color(0xFFE4E9F3),
          surfaceContainerHighest: dark
              ? const Color(0xFF20263E)
              : const Color(0xFFF1F4FA),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.55,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.55),
          bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.5),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0B1020) : background,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0xFF161C30) : surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.28 : 0.055),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF11172A) : surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9BAFF8),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.78),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? const Color(0xFF202842) : surface,
        selectedColor: dark ? const Color(0xFF25346B) : const Color(0xFFE8EEFF),
        checkmarkColor: primary,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: dark
            ? const Color(0xFF0F1426).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        indicatorColor: dark
            ? const Color(0xFF25346B)
            : const Color(0xFFE8EEFF),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: dark
            ? const Color(0xFF25346B)
            : const Color(0xFFE8EEFF),
        selectedIconTheme: const IconThemeData(color: primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: dark ? const Color(0xFF0F1426) : background,
        elevation: 0,
        indicatorColor: dark
            ? const Color(0xFF25346B)
            : const Color(0xFFE8EEFF),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: dark ? const Color(0xFF161C30) : surface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: dark ? const Color(0xFF131A2D) : background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xFFE5EAF4),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  static BoxDecoration pageGradient(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xFF0B1020), Color(0xFF10182B), Color(0xFF0B1020)]
            : const [Color(0xFFF4F7FB), Color(0xFFF4F7FB), Color(0xFFEEF3F9)],
      ),
    );
  }
}
