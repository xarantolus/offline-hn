import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {'light': lightTheme, 'dark': darkTheme}.entries) {
    test('${entry.key} app bar title is legible', () {
      final bar = entry.value.appBarTheme;
      expect(
        _contrast(bar.foregroundColor!, bar.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('${entry.key} tonal containers keep their label legible', () {
      final scheme = entry.value.colorScheme;
      expect(
        _contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('${entry.key} surface accent reads on the surface', () {
      final scheme = entry.value.colorScheme;
      expect(
        _contrast(scheme.surfaceAccent, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  test('pages slide in from the right and fill with the page colour', () {
    for (final theme in [lightTheme, darkTheme]) {
      final builder =
          theme.pageTransitionsTheme.builders[TargetPlatform.android]!
              as SharedAxisPageTransitionsBuilder;
      expect(builder.transitionType, SharedAxisTransitionType.horizontal);
      expect(builder.fillColor, theme.colorScheme.surface);
    }
  });
}
