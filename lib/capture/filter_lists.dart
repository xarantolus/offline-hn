import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:page_capture/filters.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

sealed class FilterUpdate {
  const FilterUpdate();
}

class FilterUpdated extends FilterUpdate {
  const FilterUpdated(this.stats);

  final FilterStats stats;
}

class FilterUpdateFailed extends FilterUpdate {
  const FilterUpdateFailed(this.message);

  final String message;
}

/// The downloaded ad-block lists. Nothing is bundled: a capture reads
/// [directory] and runs without network or cosmetic blocking when it is empty.
/// A failed update changes nothing, so the last good copy stays.
class FilterLists {
  FilterLists({
    required this.directory,
    required this.settings,
    http.Client? client,
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  static const filtersFile = 'filters.tsv';
  static const maxAge = Duration(days: 7);

  final Directory directory;
  final SettingsStore settings;
  final http.Client _client;
  final DateTime Function() _clock;

  static Future<Directory> locate() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'filter_lists'),
  );

  File get _filters => File(p.join(directory.path, filtersFile));

  /// Downloads when there is no good copy or it is older than [maxAge], and
  /// [mayDownload] allows the network. Returns null when nothing was needed or
  /// allowed.
  Future<FilterUpdate?> ensureFresh({required bool mayDownload}) async {
    if (!mayDownload) return null;
    final updatedAt = (await settings.load()).filterListsUpdatedAt;
    final fresh =
        updatedAt != null &&
        _filters.existsSync() &&
        _clock().difference(updatedAt) < maxAge;
    return fresh ? null : update();
  }

  /// Never throws: a failure is reported and the previous copy stays.
  Future<FilterUpdate> update() async {
    try {
      final compiled = await FilterSources.download(_client, now: _clock());
      await directory.create(recursive: true);
      final staging = File('${_filters.path}.tmp');
      await staging.writeAsString(compiled.text, flush: true);
      await staging.rename(_filters.path);
      await settings.set(Settings.filterListsUpdatedAt, compiled.generated);
      return FilterUpdated(compiled.stats);
    } on Exception catch (e) {
      return FilterUpdateFailed('$e');
    }
  }
}
