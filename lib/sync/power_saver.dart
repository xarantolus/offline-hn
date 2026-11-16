import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

abstract interface class PowerSaver {
  Future<bool> isOn();
}

class PluginPowerSaver implements PowerSaver {
  PluginPowerSaver([Battery? battery]) : _battery = battery ?? Battery();

  final Battery _battery;

  /// A phone that will not say counts as not saving: updates are the point
  /// of the app, and the setting is only being respected, not enforced.
  @override
  Future<bool> isOn() async {
    try {
      return await _battery.isInBatterySaveMode;
    } on Exception catch (e) {
      debugPrintSynchronously('battery saver unknown: $e');
      return false;
    }
  }
}
