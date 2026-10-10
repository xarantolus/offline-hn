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

/// The downloaded ad-block lists, one file per configured URL. Nothing is
/// bundled: a capture reads every list in [directory] and runs without
/// network or cosmetic blocking when there is none. A failed download changes
/// nothing, so a list's last good copy stays.
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

  static const _extension = '.tsv';

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

  /// Downloads what is missing or stale when [mayDownload] allows the network;
  /// null when nothing was needed or allowed.
  Future<Map<String, FilterListStatus>?> ensureFresh({
    required bool mayDownload,
  }) async {
    if (!mayDownload) return null;
    final current = await settings.load();
    final due = current.filterListUrls.any(
      (url) => _due(url, current.filterListStatus[url]),
    );
    return due ? update() : null;
  }

  /// Deletes the copies and bookkeeping of lists no longer configured.
  Future<void> removeUnlisted() async {
    final current = await settings.load();
    await _removeUnlisted(current.filterListUrls);
    final kept = {
      for (final entry in current.filterListStatus.entries)
        if (current.filterListUrls.contains(entry.key)) entry.key: entry.value,
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
      statuses[url] = await _fetch(url, current.filterListStatus[url]);
    }
    await settings.set(Settings.filterListStatus, statuses);
    return statuses;
  }

  bool _due(String url, FilterListStatus? status) {
    if (status == null) return true;
    final now = _clock();
    final checked = status.checkedAt;
    if (checked != null && now.difference(checked) < retryAfter) return false;
    final updated = status.updatedAt;
    return updated == null ||
        !fileFor(url).existsSync() ||
        now.difference(updated) >= maxAge;
  }

  Future<FilterListStatus> _fetch(String url, FilterListStatus? before) async {
    final now = _clock();
    try {
      final compiled = await FilterSources.download(_client, url, now: now);
      await directory.create(recursive: true);
      final file = fileFor(url);
      final staging = File('${file.path}.tmp');
      await staging.writeAsString(compiled.text, flush: true);
      await staging.rename(file.path);
      return FilterListStatus(
        updatedAt: now,
        checkedAt: now,
        networkRules: compiled.stats.networkRules,
        cosmeticRules: compiled.stats.cosmeticRules,
      );
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
