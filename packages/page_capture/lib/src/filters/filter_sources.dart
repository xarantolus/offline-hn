import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:page_capture/src/filters/filter_list_text.dart';

abstract final class FilterSources {
  static const defaultLists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
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
