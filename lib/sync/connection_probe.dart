import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_hn/data/model/sync_enums.dart';

abstract interface class ConnectionProbe {
  Future<ConnectionKind> current();
}

/// Wi-Fi and ethernet are not metered; anything else that carries traffic is
/// treated as if it were.
ConnectionKind connectionKindOf(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return ConnectionKind.wifi;
  }
  if (results.contains(ConnectivityResult.mobile) ||
      results.contains(ConnectivityResult.vpn) ||
      results.contains(ConnectivityResult.other)) {
    return ConnectionKind.mobile;
  }
  return ConnectionKind.none;
}

class PluginConnectionProbe implements ConnectionProbe {
  PluginConnectionProbe([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<ConnectionKind> current() async =>
      connectionKindOf(await _connectivity.checkConnectivity());
}
