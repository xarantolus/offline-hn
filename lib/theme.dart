import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_hn/ui/tokens.dart';

// HN orange (#FF6600) is 2.9:1 against white; this is the lightest orange
// that carries white text at 4.5:1.
const _themeColor = Color.fromRGBO(0xC9, 0x4F, 0x00, 1.0);
const _secondaryColor = Color.fromRGBO(0xD4, 0x58, 0x00, 1.0);

const _themeColorDark = Color.fromRGBO(0xB3, 0x44, 0x00, 1.0);
const _secondaryColorDark = Color.fromRGBO(0xC2, 0x4D, 0x00, 1.0);

extension SurfaceAccent on ColorScheme {
  /// Brand colour for text and icons drawn on a surface. [primary] is a fill
  /// that white sits on, and is too close to the surface to be read as text.
  Color get surfaceAccent => brightness == Brightness.dark
      ? AppTokens.dark.accent
      : AppTokens.light.accent;
}

// Fade-upwards, not the Android default side slide: pages are pushed from a
// vertically scrolled list.
const _pageTransitions = PageTransitionsTheme(
  builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
);

ThemeData _withComponents(ThemeData base, AppTokens tokens) {
  final scheme = base.colorScheme;
  Color pick(Set<WidgetState> s, Color on, Color off) =>
      s.contains(WidgetState.selected) ? on : off;
  return base.copyWith(
    extensions: [tokens],
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: Spacing.gutter),
    ),
    popupMenuTheme: PopupMenuThemeData(color: scheme.surface),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => pick(s, scheme.surface, scheme.outline),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => pick(s, scheme.surfaceAccent, tokens.hairline),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => pick(s, Colors.transparent, scheme.outline),
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: scheme.surfaceAccent,
      inactiveTrackColor: tokens.hairline,
      thumbColor: scheme.surfaceAccent,
      overlayColor: scheme.surfaceAccent.withValues(alpha: 0.16),
      activeTickMarkColor: scheme.surface,
      inactiveTickMarkColor: scheme.outline,
      valueIndicatorColor: scheme.surfaceAccent,
      valueIndicatorTextStyle: TextStyle(color: scheme.surface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.surfaceAccent,
      linearTrackColor: tokens.hairline,
    ),
  );
}

ThemeData get _lightBase =>
    ThemeData.from(
      colorScheme: const ColorScheme.light().copyWith(
        primary: _themeColor,
        secondary: _secondaryColor,
        surface: AppTokens.light.page,
        onSurface: AppTokens.light.text,
        surfaceContainerHighest: Colors.transparent,
        surfaceContainerLowest: Colors.transparent,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFFCE8DA),
        onSecondaryContainer: const Color(0xFF5C2200),
        outline: const Color(0xFF857F76),
        outlineVariant: const Color(0xFFD5CFC6),
      ),
      textTheme: Typography.blackHelsinki.copyWith(
        bodyMedium: const TextStyle(fontSize: 14),
      ),
    ).copyWith(
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actionsIconTheme: IconThemeData(color: Colors.white),
        // The bar is saturated blue in both themes, so the icons must be light.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );

ThemeData get _darkBase =>
    ThemeData.from(
      colorScheme: const ColorScheme.dark().copyWith(
        primary: _themeColorDark,
        onPrimary: Colors.white,
        secondary: _secondaryColorDark,
        surface: AppTokens.dark.page,
        onSurface: AppTokens.dark.text,
        surfaceContainerHighest: Colors.transparent,
        surfaceContainerLowest: Colors.transparent,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF4A2A15),
        onSecondaryContainer: const Color(0xFFFFDCC8),
        outline: const Color(0xFF9A948B),
        outlineVariant: const Color(0xFF4A453F),
      ),
      textTheme: Typography.whiteHelsinki.copyWith(
        bodyMedium: TextStyle(color: Colors.grey[200], fontSize: 14),
      ),
    ).copyWith(
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        actionsIconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.grey[700]!),
        ),
      ),
    );

ThemeData get lightTheme => _withComponents(_lightBase, AppTokens.light);

ThemeData get darkTheme => _withComponents(_darkBase, AppTokens.dark);
