import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/capture/archive_anchor.dart';

void main() {
  final location = Uri.parse('https://example.com/post/?utm=1');
  final copy = Uri.parse('file:///data/files/page.mhtml');

  group('snapshotLocation', () {
    test('reads the saved-from address out of the archive header', () {
      const header =
          'From: <Saved by Blink>\r\n'
          'Snapshot-Content-Location: https://example.com/post/?utm=1\r\n'
          'Subject: x\r\n';
      expect(snapshotLocation(header), location);
    });

    test('is null when the header has none', () {
      expect(snapshotLocation('From: <Saved by Blink>\r\n'), isNull);
    });
  });

  group('sameDocumentTarget', () {
    test('a jump within the saved page becomes the copy at that fragment', () {
      expect(
        sameDocumentTarget(
          Uri.parse('https://example.com/post/?utm=1#intro'),
          location,
          copy,
        ),
        Uri.parse('file:///data/files/page.mhtml#intro'),
      );
    });

    test('keeps an encoded fragment encoded', () {
      final target = sameDocumentTarget(
        Uri.parse('https://example.com/post/?utm=1#a%20b'),
        location,
        copy,
      );
      expect(target?.toString(), 'file:///data/files/page.mhtml#a%20b');
    });

    test('a bare # goes to the top of the copy', () {
      final target = sameDocumentTarget(
        Uri.parse('https://example.com/post/?utm=1#'),
        location,
        copy,
      );
      expect(target?.toString(), 'file:///data/files/page.mhtml');
    });

    test('another page, another query or no fragment stays a normal link', () {
      for (final other in [
        'https://example.com/other/#intro',
        'https://example.com/post/#intro',
        'https://example.com/post/?utm=1',
      ]) {
        expect(sameDocumentTarget(Uri.parse(other), location, copy), isNull);
      }
    });

    test('a copy not saved from a web address never matches', () {
      expect(
        sameDocumentTarget(
          Uri.parse('file:///x.mhtml#a'),
          Uri.parse('file:///x.mhtml'),
          copy,
        ),
        isNull,
      );
    });
  });
}
