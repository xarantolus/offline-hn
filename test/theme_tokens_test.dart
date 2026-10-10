import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/theme.dart';
import 'package:offline_hn/ui/tokens.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  for (final entry in {'light': lightTheme, 'dark': darkTheme}.entries) {
    final theme = entry.value;
    final tokens = theme.extension<AppTokens>()!;

    test('${entry.key}: small text clears 4.5:1', () {
      for (final MapEntry(:key, :value) in tokens.textPairs.entries) {
        expect(
          _contrast(value.$1, value.$2),
          greaterThanOrEqualTo(4.5),
          reason: key,
        );
      }
    });

    test('${entry.key}: filled button label is legible', () {
      final scheme = theme.colorScheme;
      expect(
        _contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('${entry.key}: page matches the scaffold', () {
      expect(theme.colorScheme.surface, tokens.page);
      expect(theme.colorScheme.onSurface, tokens.text);
    });

    test('${entry.key}: switch and slider parts stand out from the page', () {
      final on = {WidgetState.selected};
      final sw = theme.switchTheme;
      final track = sw.trackColor!.resolve(on)!;
      final thumb = sw.thumbColor!.resolve(on)!;
      expect(_contrast(track, tokens.page), greaterThanOrEqualTo(3));
      expect(_contrast(thumb, track), greaterThanOrEqualTo(3));
      expect(
        _contrast(sw.thumbColor!.resolve({})!, tokens.page),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(theme.sliderTheme.activeTrackColor!, tokens.page),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(theme.sliderTheme.thumbColor!, tokens.page),
        greaterThanOrEqualTo(3),
      );
    });
  }
}
