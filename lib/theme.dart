import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _lightSurfaceAccent = Color.fromRGBO(0xB0, 0x3F, 0x00, 1.0);
const _darkSurfaceAccent = Color.fromRGBO(0xFF, 0x9A, 0x5C, 1.0);

// HN orange (#FF6600) is 2.9:1 against white; this is the lightest orange
// that carries white text at 4.5:1.
const _themeColor = Color.fromRGBO(0xC9, 0x4F, 0x00, 1.0);
const _secondaryColor = Color.fromRGBO(0xD4, 0x58, 0x00, 1.0);

const _themeColorDark = Color.fromRGBO(0xB3, 0x44, 0x00, 1.0);
const _secondaryColorDark = Color.fromRGBO(0xC2, 0x4D, 0x00, 1.0);

extension SurfaceAccent on ColorScheme {
  /// Brand colour for text and icons drawn on a surface. [primary] is a fill
  /// that white sits on, and is too close to the surface to be read as text.
  Color get surfaceAccent =>
      brightness == Brightness.dark ? _darkSurfaceAccent : _lightSurfaceAccent;
}

// Fade-upwards, not the Android default side slide: pages are pushed from a
// vertically scrolled list.
const _pageTransitions = PageTransitionsTheme(
  builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
);

ThemeData get lightTheme =>
    ThemeData.from(
      colorScheme: const ColorScheme.light().copyWith(
        primary: _themeColor,
        secondary: _secondaryColor,
        surface: Colors.grey[200],
        surfaceContainerHighest: Colors.transparent,
        surfaceContainerLowest: Colors.transparent,
        onSecondary: Colors.white,
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

ThemeData get darkTheme =>
    ThemeData.from(
      colorScheme: const ColorScheme.dark().copyWith(
        primary: _themeColorDark,
        secondary: _secondaryColorDark,
        surface: Colors.grey[900],
        surfaceContainerHighest: Colors.transparent,
        surfaceContainerLowest: Colors.transparent,
        onSecondary: Colors.white,
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
