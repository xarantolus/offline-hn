import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:offline_hn/data/model/filter_list_status.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:page_capture/filters.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The downloaded ad-block lists, one file per configured URL, and the
/// resources file that scriptlets and redirects need, with a status entry of
/// its own. Nothing is bundled: a capture reads every list in [directory] and
/// runs without network or cosmetic blocking when there is none, and without
/// scriptlets when there are no resources. A failed download changes nothing,
/// so the last good copy stays.
class FilterLists {
  FilterLists({
    required this.directory,
    required this.settings,
    http.Client? client,
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  static const maxAge = Duration(days: 7);

  /// A list that failed, or has gone stale, is not asked for again sooner.
  static const retryAfter = Duration(hours: 1);

  static const _extension = '.txt';

  final Directory directory;
  final SettingsStore settings;
  final http.Client _client;
  final DateTime Function() _clock;

  static Future<Directory> locate() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'filter_lists'),
  );

  File fileFor(String url) => File(
    p.join(directory.path, '${sha1.convert(utf8.encode(url))}$_extension'),
  );

  File get resourcesFile =>
      File(p.join(directory.path, FilterSources.resourcesFileName));

  /// Downloads what is missing or stale when [mayDownload] allows the network;
  /// null when nothing was needed or allowed.
  Future<Map<String, FilterListStatus>?> ensureFresh({
    required bool mayDownload,
  }) async {
    if (!mayDownload) return null;
    final current = await settings.load();
    final due =
        current.filterListUrls.any(
          (url) => _due(url, fileFor(url), current.filterListStatus[url]),
        ) ||
        _due(
          FilterSources.resourcesUrl,
          resourcesFile,
          current.filterListStatus[FilterSources.resourcesUrl],
        );
    return due ? update() : null;
  }

  /// Deletes the copies and bookkeeping of lists no longer configured.
  Future<void> removeUnlisted() async {
    final current = await settings.load();
    await _removeUnlisted(current.filterListUrls);
    final kept = {
      for (final entry in current.filterListStatus.entries)
        if (current.filterListUrls.contains(entry.key) ||
            entry.key == FilterSources.resourcesUrl)
          entry.key: entry.value,
    };
    if (kept.length != current.filterListStatus.length) {
      await settings.set(Settings.filterListStatus, kept);
    }
  }

  /// Fetches every configured list. Never throws: each failure is recorded
  /// against its list and the other lists carry on.
  Future<Map<String, FilterListStatus>> update() async {
    final current = await settings.load();
    final urls = current.filterListUrls.toSet().toList();
    await _removeUnlisted(urls);
    final statuses = <String, FilterListStatus>{};
    for (final url in urls) {
      statuses[url] = await _refresh(
        current.filterListStatus[url],
        fileFor(url),
        () => FilterSources.downloadList(_client, url),
        (text, now) {
          final counts = FilterListText.inspect(text);
          return FilterListStatus(
            updatedAt: now,
            checkedAt: now,
            networkRules: counts.networkRules,
            cosmeticRules: counts.cosmeticRules,
          );
        },
      );
    }
    statuses[FilterSources.resourcesUrl] = await _refresh(
      current.filterListStatus[FilterSources.resourcesUrl],
      resourcesFile,
      () => FilterSources.downloadResources(_client),
      (text, now) {
        FilterSources.checkResources(text);
        return FilterListStatus(updatedAt: now, checkedAt: now);
      },
    );
    await settings.set(Settings.filterListStatus, statuses);
    return statuses;
  }

  bool _due(String url, File file, FilterListStatus? status) {
    if (status == null) return true;
    final now = _clock();
    final checked = status.checkedAt;
    if (checked != null && now.difference(checked) < retryAfter) return false;
    final updated = status.updatedAt;
    return updated == null ||
        !file.existsSync() ||
        now.difference(updated) >= maxAge;
  }

  Future<FilterListStatus> _refresh(
    FilterListStatus? before,
    File file,
    Future<String> Function() fetch,
    FilterListStatus Function(String text, DateTime now) accept,
  ) async {
    final now = _clock();
    try {
      final text = await fetch();
      final status = accept(text, now);
      await directory.create(recursive: true);
      final staging = File('${file.path}.tmp');
      await staging.writeAsString(text, flush: true);
      await staging.rename(file.path);
      return status;
    } on FilterListException catch (e) {
      return (before ?? const FilterListStatus()).failed(e.message, now);
    } on Exception catch (e) {
      return (before ?? const FilterListStatus()).failed('$e', now);
    }
  }

  Future<void> _removeUnlisted(List<String> urls) async {
    if (!directory.existsSync()) return;
    final wanted = {for (final url in urls) fileFor(url).path};
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.endsWith(_extension) &&
          !wanted.contains(entity.path)) {
        await entity.delete();
      }
    }
  }
}
