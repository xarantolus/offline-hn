import 'package:offline_hn/capture/filter_lists.dart';

abstract interface class FilterListSync {
  String get directoryPath;

  /// Downloads what is missing or old and says whether it did. Never throws
  /// for a failed list.
  Future<bool> ensureFresh();
}

class FilterListsSync implements FilterListSync {
  const FilterListsSync(this._lists);

  final FilterLists _lists;

  @override
  String get directoryPath => _lists.directory.path;

  @override
  Future<bool> ensureFresh() async =>
      await _lists.ensureFresh(mayDownload: true) != null;
}
