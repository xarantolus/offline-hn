import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';

enum SyncAllowance { nothing, textOnly, textAndPages }

/// Manual and filter-list runs are the user asking, so they may use mobile
/// data for text even when automatic runs are limited to Wi-Fi. Filter lists
/// are never pages.
SyncAllowance syncAllowance({
  required SyncTrigger trigger,
  required ConnectionKind connection,
  required AppSettings settings,
}) {
  final userInitiated =
      trigger == SyncTrigger.manual || trigger == SyncTrigger.filterLists;
  final pagesWanted = trigger != SyncTrigger.filterLists;

  switch (connection) {
    case ConnectionKind.none:
      return SyncAllowance.nothing;
    case ConnectionKind.wifi:
      return pagesWanted ? SyncAllowance.textAndPages : SyncAllowance.textOnly;
    case ConnectionKind.mobile:
      if (settings.wifiOnly && !userInitiated) return SyncAllowance.nothing;
      return pagesWanted && settings.pagesOnMobile
          ? SyncAllowance.textAndPages
          : SyncAllowance.textOnly;
  }
}
