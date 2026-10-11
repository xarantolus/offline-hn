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
import 'package:page_capture/filters.dart';

const _a = 'https://lists.example/a.txt';
const _b = 'https://lists.example/b.txt';
const _resources = FilterSources.resourcesUrl;

String _list(int rules) =>
    '[Adblock Plus 2.0]\n${[for (var i = 0; i < rules; i++) '||ads$i.example.com^'].join('\n')}\n##.banner\n';

void main() {
  late AppDatabase db;
  late SettingsStore settings;
  late Directory directory;
  late DateTime now;
  late Map<String, String> served;
  late List<String> requested;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsStore(db);
    directory = Directory.systemTemp.createTempSync('filter_lists_test');
    now = DateTime.utc(2026, 10, 10, 6);
    served = {
      _a: _list(3),
      _b: _list(5),
      _resources: '[{"name":"noop.js","aliases":[],"content":"eA=="}]',
    };
    requested = [];
  });

  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });

  FilterLists lists() => FilterLists(
    directory: Directory('${directory.path}/lists'),
    settings: settings,
    client: MockClient((request) async {
      requested.add(request.url.toString());
      final body = served[request.url.toString()];
      return body == null
          ? http.Response('nope', 503)
          : http.Response(body, 200);
    }),
    clock: () => now,
  );

  Future<void> use(List<String> urls) =>
      settings.set(Settings.filterListUrls, urls);

  Future<Map<String, Object?>> statuses() async =>
      (await settings.load()).filterListStatus;

  test('the defaults are EasyList and EasyPrivacy', () async {
    expect((await settings.load()).filterListUrls, [
      'https://easylist.to/easylist/easylist.txt',
      'https://easylist.to/easylist/easyprivacy.txt',
    ]);
  });

  test('every configured list gets its own file and status', () async {
    await use([_a, _b]);
    final l = lists();
    final result = await l.update();

    expect(l.fileFor(_a).existsSync(), isTrue);
    expect(l.fileFor(_b).existsSync(), isTrue);
    expect(l.fileFor(_a).path, isNot(l.fileFor(_b).path));
    expect(result[_a]!.networkRules, 3);
    expect(result[_b]!.networkRules, 5);
    expect(result[_a]!.cosmeticRules, 1);
    expect(result[_a]!.updatedAt, now);
    expect(result[_a]!.error, isNull);
    expect((await settings.load()).filterListStatus[_b]!.networkRules, 5);
  });

  test('the resources file has a status of its own', () async {
    await use([_a]);
    final l = lists();
    final result = await l.update();

    expect(l.resourcesFile.readAsStringSync(), served[_resources]);
    expect(result[_resources]!.updatedAt, now);
    expect(result[_resources]!.error, isNull);
  });

  test('bad resources are reported and the lists still update', () async {
    await use([_a]);
    final l = lists();
    await l.update();
    final before = l.resourcesFile.readAsStringSync();

    now = now.add(const Duration(days: 8));
    served[_resources] = '<html>rate limited</html>';
    final result = await l.update();

    expect(result[_resources]!.error, isNotNull);
    expect(result[_resources]!.updatedAt, DateTime.utc(2026, 10, 10, 6));
    expect(l.resourcesFile.readAsStringSync(), before);
    expect(result[_a]!.error, isNull);
    expect(result[_a]!.updatedAt, now);
  });

  test('a list that fails is reported without stopping the others', () async {
    await use([_a, _b]);
    served[_a] = '<html>blocked</html>';
    final result = await lists().update();

    expect(result[_a]!.error, isNotNull);
    expect(result[_a]!.hasCopy, isFalse);
    expect(result[_b]!.error, isNull);
    expect(lists().fileFor(_a).existsSync(), isFalse);
  });

  test('a failed refresh keeps the last good copy and its time', () async {
    await use([_a]);
    final l = lists();
    await l.update();
    final before = l.fileFor(_a).readAsStringSync();

    now = now.add(const Duration(days: 8));
    served[_a] = '<html>error</html>';
    final result = await l.update();

    expect(l.fileFor(_a).readAsStringSync(), before);
    expect(result[_a]!.updatedAt, DateTime.utc(2026, 10, 10, 6));
    expect(result[_a]!.checkedAt, now);
    expect(result[_a]!.error, isNotNull);
    expect(result[_a]!.networkRules, 3);
  });

  test('an invalid URL is reported and never requested', () async {
    await use(['not a url', 'ftp://lists.example/a.txt', _a]);
    final result = await lists().update();

    expect(result['not a url']!.error, isNotNull);
    expect(result['ftp://lists.example/a.txt']!.error, isNotNull);
    expect(result[_a]!.error, isNull);
    expect(requested, [_a, _resources]);
  });

  test('removing a URL deletes its copy and bookkeeping', () async {
    await use([_a, _b]);
    final l = lists();
    await l.update();

    await use([_b]);
    await l.removeUnlisted();

    expect(l.fileFor(_a).existsSync(), isFalse);
    expect(l.fileFor(_b).existsSync(), isTrue);
    expect((await statuses()).keys, [_b, _resources]);
  });

  test('an update also drops lists that were removed', () async {
    await use([_a, _b]);
    final l = lists();
    await l.update();
    await use([_a]);
    await l.update();
    expect(l.fileFor(_b).existsSync(), isFalse);
    expect((await statuses()).keys, [_a, _resources]);
  });

  group('ensureFresh', () {
    test('downloads a newly added list and leaves the others alone', () async {
      await use([_a]);
      final l = lists();
      await l.update();
      requested.clear();

      await use([_a, _b]);
      expect(await l.ensureFresh(mayDownload: true), isNotNull);
      expect(requested, [_a, _b, _resources]);
      expect(l.fileFor(_b).existsSync(), isTrue);
    });

    test('does nothing while every copy is under a week old', () async {
      await use([_a, _b]);
      final l = lists();
      await l.update();
      requested.clear();
      now = now.add(const Duration(days: 6));
      expect(await l.ensureFresh(mayDownload: true), isNull);
      expect(requested, isEmpty);
    });

    test('refreshes once a copy is a week old', () async {
      await use([_a]);
      final l = lists();
      await l.update();
      now = now.add(const Duration(days: 8));
      expect(await l.ensureFresh(mayDownload: true), isNotNull);
      expect((await statuses())[_a], isNotNull);
    });

    test('does not retry a failure within the hour, then does', () async {
      await use([_a]);
      served.remove(_a);
      final l = lists();
      await l.update();
      requested.clear();

      now = now.add(const Duration(minutes: 30));
      expect(await l.ensureFresh(mayDownload: true), isNull);
      now = now.add(const Duration(minutes: 31));
      expect(await l.ensureFresh(mayDownload: true), isNotNull);
      expect(requested, [_a, _resources]);
    });

    test('a deleted file counts as no copy', () async {
      await use([_a]);
      final l = lists();
      await l.update();
      l.fileFor(_a).deleteSync();
      now = now.add(const Duration(hours: 2));
      expect(await l.ensureFresh(mayDownload: true), isNotNull);
      expect(l.fileFor(_a).existsSync(), isTrue);
    });

    test('a missing resources file is fetched on its own', () async {
      await use([_a]);
      final l = lists();
      await l.update();
      l.resourcesFile.deleteSync();
      now = now.add(const Duration(hours: 2));
      expect(await l.ensureFresh(mayDownload: true), isNotNull);
      expect(l.resourcesFile.existsSync(), isTrue);
    });

    test('never touches the network when the caller says it may not', () async {
      final l = lists();
      expect(await l.ensureFresh(mayDownload: false), isNull);
      expect(requested, isEmpty);
      expect(l.directory.existsSync(), isFalse);
    });
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
