import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';

enum SyncAllowance { nothing, textOnly, textAndPages }

/// A manual run is the user asking, so it may use mobile data for text even
/// when automatic runs are limited to Wi-Fi.
SyncAllowance syncAllowance({
  required SyncTrigger trigger,
  required ConnectionKind connection,
  required AppSettings settings,
}) {
  final userInitiated = trigger == SyncTrigger.manual;

  switch (connection) {
    case ConnectionKind.none:
      return SyncAllowance.nothing;
    case ConnectionKind.wifi:
      return SyncAllowance.textAndPages;
    case ConnectionKind.mobile:
      if (settings.wifiOnly && !userInitiated) return SyncAllowance.nothing;
      return settings.pagesOnMobile
          ? SyncAllowance.textAndPages
          : SyncAllowance.textOnly;
  }
}
