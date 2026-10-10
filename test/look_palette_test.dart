import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/debug/looks/all_looks.dart';
import 'package:offline_hn/debug/looks/cards.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';

void main() {
  for (final kit in allLooks) {
    for (final brightness in Brightness.values) {
      test('${kit.name} ${brightness.name}: small text clears 4.5:1', () {
        final pairs = kit.paletteFor(brightness).textPairs;
        for (final MapEntry(:key, :value) in pairs.entries) {
          expect(
            contrastRatio(value.$1, value.$2),
            greaterThanOrEqualTo(4.5),
            reason: key,
          );
        }
      });
    }
  }

  test('monogram colours clear 4.5:1 for every domain', () {
    for (final domain in [
      'github.com',
      'lwn.net',
      'x.org',
      'arxiv.org',
      'jvns.ca',
    ]) {
      for (final dark in [true, false]) {
        final (bg, fg) = Monogram.colorsFor(domain, dark);
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: domain,
        );
      }
    }
  });

  test('monogram is stable per domain', () {
    expect(
      Monogram.colorsFor('lwn.net', false),
      Monogram.colorsFor('lwn.net', false),
    );
    expect(Monogram.letters('blog.cloudflare.com'), 'cl');
  });
}
