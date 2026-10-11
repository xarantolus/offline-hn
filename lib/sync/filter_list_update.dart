import 'package:flutter/foundation.dart';
import 'package:offline_hn/capture/filter_lists.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/sync/connection_probe.dart';

enum ListUpdateResult { updated, someFailed, noConnection, alreadyRunning }

/// The manual refresh of the filter lists: the same [FilterLists.update] a
/// sync uses when lists are stale, run now and not through the sync queue,
/// which would only join a sync that is already running.
class FilterListUpdate {
  FilterListUpdate({required this._lists, required this._probe});

  final FilterLists _lists;
  final ConnectionProbe _probe;

  final ValueNotifier<bool> running = ValueNotifier(false);

  Future<ListUpdateResult> run() async {
    if (running.value) return ListUpdateResult.alreadyRunning;
    if (await _probe.current() == ConnectionKind.none) {
      return ListUpdateResult.noConnection;
    }
    running.value = true;
    try {
      final statuses = await _lists.update();
      return statuses.values.any((s) => s.error != null)
          ? ListUpdateResult.someFailed
          : ListUpdateResult.updated;
    } finally {
      running.value = false;
    }
  }
}
