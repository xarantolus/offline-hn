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

    test('${entry.key}: depth rails are visible on the page', () {
      for (final level in [0, 1]) {
        final rail = Color.alphaBlend(tokens.railColor(level), tokens.page);
        expect(
          _contrast(rail, tokens.page),
          greaterThanOrEqualTo(2),
          reason: 'level $level',
        );
      }
    });

    test('${entry.key}: time picker text clears 4.5:1 on its fills', () {
      final picker = theme.timePickerTheme;
      for (final states in [
        <WidgetState>{},
        {WidgetState.selected},
      ]) {
        final fill = Color.alphaBlend(
          WidgetStateProperty.resolveAs<Color>(picker.hourMinuteColor!, states),
          tokens.page,
        );
        expect(
          _contrast(
            WidgetStateProperty.resolveAs<Color>(
              picker.hourMinuteTextColor!,
              states,
            ),
            fill,
          ),
          greaterThanOrEqualTo(4.5),
        );
        final dayFill = Color.alphaBlend(
          WidgetStateProperty.resolveAs<Color>(picker.dayPeriodColor!, states),
          tokens.page,
        );
        expect(
          _contrast(
            WidgetStateProperty.resolveAs<Color>(
              picker.dayPeriodTextColor!,
              states,
            ),
            dayFill,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('${entry.key}: the floating button carries white on its fill', () {
      final fab = theme.floatingActionButtonTheme;
      expect(fab.backgroundColor, theme.colorScheme.primary);
      expect(
        _contrast(fab.foregroundColor!, fab.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
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
