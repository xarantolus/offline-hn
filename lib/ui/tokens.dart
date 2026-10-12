import 'package:flutter/material.dart';

abstract final class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const gutter = 22.0;

  /// Space before the outermost depth rail, taken out of the text's own
  /// padding so the text stays put and the rails sit nearer to it.
  static const railInset = 5.0;
}

const _serif = 'serif';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.page,
    required this.text,
    required this.muted,
    required this.hairline,
    required this.divider,
    required this.siblingDivider,
    required this.accent,
    required this.accentWash,
    required this.marker,
    required this.codeBackground,
  });

  final Color page;
  final Color text;
  final Color muted;
  final Color hairline;
  final Color divider;

  /// Between replies at the same level; fainter than [hairline].
  final Color siblingDivider;
  final Color accent;
  final Color accentWash;
  final Color marker;
  final Color codeBackground;

  static const light = AppTokens(
    page: Color(0xFFFBF9F4),
    text: Color(0xFF1C1B18),
    muted: Color(0xFF5C584E),
    hairline: Color(0xFFDAD4C6),
    divider: Color(0xFFB5AD9B),
    siblingDivider: Color(0xFFE7E2D6),
    accent: Color(0xFFB03F00),
    accentWash: Color(0xFFFCE8DA),
    marker: Color(0xFF00695C),
    codeBackground: Color(0xFFF1EDE3),
  );

  static const dark = AppTokens(
    page: Color(0xFF1A1917),
    text: Color(0xFFECE8DF),
    muted: Color(0xFFABA598),
    hairline: Color(0xFF3A3731),
    divider: Color(0xFF6A6558),
    siblingDivider: Color(0xFF2C2A26),
    accent: Color(0xFFFF9A5C),
    accentWash: Color(0xFF3A2A1F),
    marker: Color(0xFF4DD0C0),
    codeBackground: Color(0xFF242320),
  );

  /// Every foreground/background pair that carries small text.
  Map<String, (Color, Color)> get textPairs => {
    'text on page': (text, page),
    'muted on page': (muted, page),
    'accent on page': (accent, page),
    'accent on wash': (accent, accentWash),
    'marker on page': (marker, page),
    'text on code': (text, codeBackground),
  };

  TextStyle get storyTitle => TextStyle(
    fontFamily: _serif,
    fontSize: 21,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: text,
  );

  TextStyle get storyTitleRead => storyTitle.copyWith(color: muted);

  TextStyle get threadTitle => TextStyle(
    fontFamily: _serif,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: text,
  );

  TextStyle get smallCaps => TextStyle(
    fontSize: 11.5,
    height: 1.3,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w600,
    color: muted,
  );

  /// Alternating neutral and accent, both visible against [page].
  Color railColor(int level) => level.isEven
      ? muted.withValues(alpha: 0.65)
      : accent.withValues(alpha: 0.75);

  TextStyle get label => TextStyle(fontSize: 16, color: text);

  TextStyle get hint => TextStyle(fontSize: 12.5, color: muted);

  TextStyle get switcher =>
      const TextStyle(fontFamily: _serif, fontSize: 15.5, height: 1.1);

  TextStyle commentBody(double size) =>
      TextStyle(fontSize: size, height: 1.33, color: text);

  @override
  AppTokens copyWith({
    Color? page,
    Color? text,
    Color? muted,
    Color? hairline,
    Color? divider,
    Color? siblingDivider,
    Color? accent,
    Color? accentWash,
    Color? marker,
    Color? codeBackground,
  }) {
    return AppTokens(
      page: page ?? this.page,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      hairline: hairline ?? this.hairline,
      divider: divider ?? this.divider,
      siblingDivider: siblingDivider ?? this.siblingDivider,
      accent: accent ?? this.accent,
      accentWash: accentWash ?? this.accentWash,
      marker: marker ?? this.marker,
      codeBackground: codeBackground ?? this.codeBackground,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      page: Color.lerp(page, other.page, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      siblingDivider: Color.lerp(siblingDivider, other.siblingDivider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentWash: Color.lerp(accentWash, other.accentWash, t)!,
      marker: Color.lerp(marker, other.marker, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
