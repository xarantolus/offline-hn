import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _assets = 'packages/page_capture/assets';

/// Adds the licences of the lists, scripts and libraries that capture uses.
void registerCaptureLicenses() {
  LicenseRegistry.addLicense(() async* {
    final version = (await rootBundle.loadString(
      '$_assets/autoconsent/VERSION',
    )).trim();
    yield LicenseEntryWithLineBreaks([
      '@duckduckgo/autoconsent $version',
    ], await rootBundle.loadString('$_assets/autoconsent/LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'Filter lists, scriptlets and resources used for page cleanup',
    ], await rootBundle.loadString('$_assets/filters/NOTICE.txt'));
    final notice = await rootBundle.loadString('$_assets/adblock/NOTICE.txt');
    final licence = await rootBundle.loadString('$_assets/adblock/LICENSE');
    yield LicenseEntryWithLineBreaks(['adblock-rust'], '$notice\n$licence');
    final brave = (await rootBundle.loadString('$_assets/procedural/VERSION'))
        .trim();
    yield LicenseEntryWithLineBreaks(
      ['Brave procedural cosmetic filters'],
      'Procedural cosmetic filters are applied with code from brave-core by '
      'Brave Software (https://github.com/brave/brave-core, commit $brave): '
      'procedural_filters.ts unchanged, and the action loop from '
      'content_cosmetic.ts with its connection to the browser replaced. Both '
      'are under the Mozilla Public License 2.0, whose text follows; their '
      'source is in the app, in procedural_filters.js and apply.js.\n\n'
      '${await rootBundle.loadString('$_assets/procedural/LICENSE')}',
    );
  });
}
