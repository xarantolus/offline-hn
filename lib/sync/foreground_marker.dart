import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Whether the app is on screen, readable from the background isolate.
///
/// The UI writes its process id while it is in the foreground. A file left
/// behind by a process that died is not believed: the id differs from the
/// current one, whereas the UI and the WorkManager isolate share a process.
class ForegroundMarker {
  ForegroundMarker(this._file, {int? currentPid}) : _pid = currentPid ?? pid;

  final File _file;
  final int _pid;

  static Future<ForegroundMarker> locate() async => ForegroundMarker(
    File(p.join((await getApplicationSupportDirectory()).path, 'foreground')),
  );

  bool get isForeground {
    try {
      return _file.readAsStringSync().trim() == '$_pid';
    } on FileSystemException {
      return false;
    }
  }

  Future<void> setForeground({required bool value}) async {
    if (value) {
      await _file.writeAsString('$_pid', flush: true);
    } else if (_file.existsSync()) {
      await _file.delete();
    }
  }
}
