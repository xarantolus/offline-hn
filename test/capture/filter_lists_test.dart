import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_hn/capture/capture_settings.dart';
import 'package:offline_hn/capture/filter_lists.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:page_capture/page_capture.dart';
import 'package:path/path.dart' as p;

String _list(int rules) =>
    '[Adblock Plus 2.0]\n${[for (var i = 0; i < rules; i++) '||ads$i.example.com^'].join('\n')}\n';

void main() {
  late AppDatabase db;
  late SettingsStore settings;
  late Directory directory;
  final now = DateTime.utc(2026, 10, 10, 6);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsStore(db);
    directory = Directory.systemTemp.createTempSync('filter_lists_test');
  });

  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });

  FilterLists listsWith(http.Client client) => FilterLists(
    directory: Directory(p.join(directory.path, 'lists')),
    settings: settings,
    client: client,
    clock: () => now,
  );

  MockClient answering(Map<String, String> bodies) => MockClient(
    (request) async => bodies.containsKey(request.url.toString())
        ? http.Response(bodies[request.url.toString()]!, 200)
        : http.Response('nope', 503),
  );

  final good = {for (final url in FilterSources.lists) url: _list(1500)};

  test('an update writes the compiled lists and records the time', () async {
    final lists = listsWith(answering(good));
    final result = await lists.update();
    expect(result, isA<FilterUpdated>());
    expect(
      File(p.join(lists.directory.path, FilterLists.filtersFile))
          .readAsStringSync(),
      startsWith('#offline-hn-filters\t1\t2026-10-10T06:00:00.000Z'),
    );
    expect((await settings.load()).filterListsUpdatedAt, now);
  });

  test('a failed update keeps the last good copy and the old time', () async {
    final lists = listsWith(answering(good));
    await lists.update();
    final before = File(p.join(lists.directory.path, FilterLists.filtersFile))
        .readAsStringSync();

    final broken = {...good, FilterSources.lists.last: '<html>error</html>'};
    final failing = FilterLists(
      directory: lists.directory,
      settings: settings,
      client: answering(broken),
      clock: () => now.add(const Duration(days: 8)),
    );
    expect(await failing.update(), isA<FilterUpdateFailed>());

    expect(
      File(p.join(lists.directory.path, FilterLists.filtersFile))
          .readAsStringSync(),
      before,
    );
    expect((await settings.load()).filterListsUpdatedAt, now);
  });

  test('a download error writes nothing at all', () async {
    final lists = listsWith(answering({}));
    expect(await lists.update(), isA<FilterUpdateFailed>());
    expect(lists.directory.existsSync(), isFalse);
    expect((await settings.load()).filterListsUpdatedAt, isNull);
  });

  group('ensureFresh', () {
    test('downloads when there is no copy', () async {
      final lists = listsWith(answering(good));
      expect(await lists.ensureFresh(mayDownload: true), isA<FilterUpdated>());
    });

    test('does nothing while the copy is younger than a week', () async {
      final lists = listsWith(answering(good));
      await lists.update();
      final later = FilterLists(
        directory: lists.directory,
        settings: settings,
        client: answering({}),
        clock: () => now.add(const Duration(days: 6)),
      );
      expect(await later.ensureFresh(mayDownload: true), isNull);
    });

    test('downloads again once the copy is a week old', () async {
      final lists = listsWith(answering(good));
      await lists.update();
      final later = FilterLists(
        directory: lists.directory,
        settings: settings,
        client: answering(good),
        clock: () => now.add(const Duration(days: 8)),
      );
      expect(await later.ensureFresh(mayDownload: true), isA<FilterUpdated>());
      expect(
        (await settings.load()).filterListsUpdatedAt,
        now.add(const Duration(days: 8)),
      );
    });

    test(
      'a missing file counts as no copy even with a recorded time',
      () async {
        final lists = listsWith(answering(good));
        await settings.set(Settings.filterListsUpdatedAt, now);
        expect(
          await lists.ensureFresh(mayDownload: true),
          isA<FilterUpdated>(),
        );
      },
    );

    test('never touches the network when the caller says it may not', () async {
      final lists = listsWith(answering(good));
      expect(await lists.ensureFresh(mayDownload: false), isNull);
      expect(lists.directory.existsSync(), isFalse);
    });

    test(
      'a failed download with no copy reports it and leaves nothing',
      () async {
        final lists = listsWith(answering({}));
        expect(
          await lists.ensureFresh(mayDownload: true),
          isA<FilterUpdateFailed>(),
        );
      },
    );
  });

  test('settings choose which cleanup layers a capture runs', () {
    final off = captureOptionsFor(
      AppSettings.fromRaw({
        Settings.adBlocking.key: 'false',
        Settings.rejectCookiePopups.key: 'true',
      }),
      filterListsDirectory: '/lists',
    );
    expect(off.cleanup.blockRequests, isFalse);
    expect(off.cleanup.hideElements, isFalse);
    expect(off.cleanup.rejectConsent, isTrue);
    expect(off.filterListsDirectory, '/lists');
    expect(off.maxBytes, 25 * 1024 * 1024);
  });
}
