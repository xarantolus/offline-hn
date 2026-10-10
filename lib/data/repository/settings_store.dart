import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/settings.dart';

class SettingsStore {
  const SettingsStore(this._db);

  final AppDatabase _db;

  Future<AppSettings> load() async =>
      AppSettings.fromRaw(_toMap(await _db.select(_db.settingEntries).get()));

  Stream<AppSettings> watch() => _db
      .select(_db.settingEntries)
      .watch()
      .map((rows) => AppSettings.fromRaw(_toMap(rows)));

  Future<void> set<T>(Setting<T> setting, T value) => _db
      .into(_db.settingEntries)
      .insertOnConflictUpdate(
        SettingEntriesCompanion.insert(
          key: setting.key,
          value: setting.encode(value),
        ),
      );

  Future<void> reset<T>(Setting<T> setting) => (_db.delete(
    _db.settingEntries,
  )..where((e) => e.key.equals(setting.key))).go();

  Map<String, String> _toMap(List<SettingRow> rows) => {
    for (final row in rows) row.key: row.value,
  };
}
