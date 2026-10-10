import 'package:offline_hn/capture/filter_lists.dart';

abstract interface class FilterListSync {
  String get directoryPath;

  /// Downloads what is missing or old. Never throws for a failed list.
  Future<void> ensureFresh();

  Future<void> updateNow();
}

class FilterListsSync implements FilterListSync {
  const FilterListsSync(this._lists);

  final FilterLists _lists;

  @override
  String get directoryPath => _lists.directory.path;

  @override
  Future<void> ensureFresh() => _lists.ensureFresh(mayDownload: true);

  @override
  Future<void> updateNow() => _lists.update();
}
