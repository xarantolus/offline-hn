import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:page_capture/src/filters/filter_list_text.dart';

abstract final class FilterSources {
  /// What each default list is, for the settings page.
  static const defaultNames = {
    'https://easylist.to/easylist/easylist.txt': 'EasyList',
    'https://easylist.to/easylist/easyprivacy.txt': 'EasyPrivacy',
    'https://easylist.to/easylist/fanboy-annoyance.txt':
        "Fanboy's Annoyance (with the EasyList Cookie List and social widgets)",
    'https://ublockorigin.github.io/uAssets/filters/annoyances-cookies.txt':
        'uBlock Origin: Cookie notices',
    'https://ublockorigin.github.io/uAssets/filters/annoyances-others.txt':
        'uBlock Origin: Other annoyances',
    'https://ublockorigin.github.io/uAssets/filters/filters.txt':
        'uBlock Origin: Filters',
    'https://ublockorigin.github.io/uAssets/filters/privacy.txt':
        'uBlock Origin: Privacy',
    'https://ublockorigin.github.io/uAssets/filters/badware.txt':
        'uBlock Origin: Badware risks',
    'https://ublockorigin.github.io/uAssets/filters/unbreak.txt':
        'uBlock Origin: Unbreak',
    'https://ublockorigin.github.io/uAssets/filters/quick-fixes.txt':
        'uBlock Origin: Quick fixes',
    'https://filters.adtidy.org/extension/ublock/filters/11.txt':
        'AdGuard: Mobile ads',
    'https://filters.adtidy.org/extension/ublock/filters/18.txt':
        'AdGuard: Cookie notices',
    'https://filters.adtidy.org/extension/ublock/filters/19.txt':
        'AdGuard: Popups',
    'https://filters.adtidy.org/extension/ublock/filters/20.txt':
        'AdGuard: Mobile app banners',
    'https://filters.adtidy.org/extension/ublock/filters/21.txt':
        'AdGuard: Other annoyances',
    'https://filters.adtidy.org/extension/ublock/filters/22.txt':
        'AdGuard: Widgets',
    'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1&mimetype=plaintext':
        "Peter Lowe's ad servers",
    'https://easylist-downloads.adblockplus.org/antiadblockfilters.txt':
        'Adblock Warning Removal',
  };

  static const defaultLists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
    'https://easylist.to/easylist/fanboy-annoyance.txt',
    'https://ublockorigin.github.io/uAssets/filters/annoyances-cookies.txt',
    'https://ublockorigin.github.io/uAssets/filters/annoyances-others.txt',
    'https://ublockorigin.github.io/uAssets/filters/filters.txt',
    'https://ublockorigin.github.io/uAssets/filters/privacy.txt',
    'https://ublockorigin.github.io/uAssets/filters/badware.txt',
    'https://ublockorigin.github.io/uAssets/filters/unbreak.txt',
    'https://ublockorigin.github.io/uAssets/filters/quick-fixes.txt',
    'https://filters.adtidy.org/extension/ublock/filters/11.txt',
    'https://filters.adtidy.org/extension/ublock/filters/18.txt',
    'https://filters.adtidy.org/extension/ublock/filters/19.txt',
    'https://filters.adtidy.org/extension/ublock/filters/20.txt',
    'https://filters.adtidy.org/extension/ublock/filters/21.txt',
    'https://filters.adtidy.org/extension/ublock/filters/22.txt',
    'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1&mimetype=plaintext',
    'https://easylist-downloads.adblockplus.org/antiadblockfilters.txt',
  ];

  /// Where in the filter lists directory the resources are kept.
  static const resourcesFileName = 'resources.ubo';

  static const requestTimeout = Duration(seconds: 60);

  /// Index of the uBlock Origin scriptlet and redirect resources that
  /// Ghostery publishes, newest revision last. Downloaded like a list, never
  /// bundled.
  static const resourcesUrl =
      'https://cdn.ghostery.com/adblocker/resources/ublock-resources/metadata.json';

  static const _headerLine = r'^\S+ [a-z]+/[a-z0-9.+-]+(;base64)?$';

  /// The newest resources text. Throws [FilterListException] when either
  /// request fails or the answer is not what was expected.
  static Future<String> downloadResources(http.Client client) async {
    final index = await download(client, resourcesUrl);
    final Object? decoded;
    try {
      decoded = jsonDecode(index);
    } on FormatException {
      throw const FilterListException('resources index is not JSON');
    }
    final revisions = decoded is Map<String, Object?>
        ? decoded['revisions']
        : null;
    if (revisions is! List<Object?> || revisions.last is! String) {
      throw const FilterListException('resources index has no revision');
    }
    final base = Uri.parse(resourcesUrl).resolve('${revisions.last}/list.txt');
    return download(client, base.toString());
  }

  static final _include = RegExp(
    r'^!#include[ \t]+(\S+)[ \t]*$',
    multiLine: true,
  );

  /// [download], with each `!#include` line replaced by the file it names.
  /// The engine does not follow includes. Only one level, relative to [url]
  /// and on the same host: that is all the published lists use.
  static Future<String> downloadList(http.Client client, String url) async {
    final body = await download(client, url);
    final base = Uri.parse(url);
    final parts = <String>[];
    var from = 0;
    for (final match in _include.allMatches(body)) {
      final included = base.resolve(match.group(1)!);
      if (included.host != base.host) {
        throw const FilterListException('include on another host');
      }
      parts
        ..add(body.substring(from, match.start))
        ..add(await download(client, included.toString()));
      from = match.end;
    }
    if (parts.isEmpty) return body;
    return (parts..add(body.substring(from))).join();
  }

  /// The body served at [url]. Throws [FilterListException] for an unusable
  /// URL or a failed request.
  static Future<String> download(http.Client client, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        !uri.isScheme('https') && !uri.isScheme('http')) {
      throw const FilterListException('not an http(s) URL');
    }
    final http.Response response;
    try {
      response = await client.get(uri).timeout(requestTimeout);
    } on Exception catch (e) {
      throw FilterListException('download failed: $e');
    }
    if (response.statusCode != 200) {
      throw FilterListException('answered ${response.statusCode}');
    }
    return response.body;
  }

  /// Throws [FilterListException] unless [text] starts like a resources file:
  /// a `name mime-type` line.
  static void checkResources(String text) {
    final first = text.trimLeft().split('\n').first.trim();
    if (!RegExp(_headerLine).hasMatch(first)) {
      throw const FilterListException('not a resources file');
    }
  }
}
