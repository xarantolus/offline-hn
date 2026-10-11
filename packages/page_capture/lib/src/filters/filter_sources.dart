import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:page_capture/src/filters/filter_list_text.dart';

abstract final class FilterSources {
  static const defaultLists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
  ];

  static const requestTimeout = Duration(seconds: 60);

  /// Where the scriptlets and redirect resources come from: uBlock Origin's,
  /// as compiled for adblock-rust. Downloaded like a list, never bundled.
  static const resourcesUrl =
      'https://raw.githubusercontent.com/brave/adblock-resources/master/dist/resources.json';

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

  /// Throws [FilterListException] unless [text] is a non-empty JSON list of
  /// named resources.
  static void checkResources(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FilterListException('not JSON');
    }
    final valid =
        decoded is List<Object?> &&
        decoded.isNotEmpty &&
        decoded.every((e) => e is Map<String, Object?> && e['name'] is String);
    if (!valid) throw const FilterListException('not a list of resources');
  }
}
