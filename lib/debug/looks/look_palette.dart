import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

@immutable
class LookPalette {
  const LookPalette({
    required this.page,
    required this.surface,
    required this.hairline,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentWash,
    required this.marker,
    required this.codeBackground,
    required this.brightness,
  });

  final Color page;
  final Color surface;
  final Color hairline;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentWash;
  final Color marker;
  final Color codeBackground;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  /// Every foreground/background pair that carries small text.
  Map<String, (Color, Color)> get textPairs => {
    'text on page': (text, page),
    'text on surface': (text, surface),
    'muted on page': (muted, page),
    'muted on surface': (muted, surface),
    'accent on page': (accent, page),
    'accent on surface': (accent, surface),
    'accent on wash': (accent, accentWash),
    'marker on page': (marker, page),
    'marker on surface': (marker, surface),
    'text on code': (text, codeBackground),
  };
}

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
