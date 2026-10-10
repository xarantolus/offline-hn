import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _assets = 'packages/page_capture/assets';

/// Adds the licences of the lists and scripts that capture bundles.
void registerCaptureLicenses() {
  LicenseRegistry.addLicense(() async* {
    final version = (await rootBundle.loadString(
      '$_assets/autoconsent/VERSION',
    )).trim();
    yield LicenseEntryWithLineBreaks([
      '@duckduckgo/autoconsent $version',
    ], await rootBundle.loadString('$_assets/autoconsent/LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'EasyList and EasyPrivacy',
    ], await rootBundle.loadString('$_assets/filters/NOTICE.txt'));
  });
}
