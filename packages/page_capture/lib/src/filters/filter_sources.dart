import 'package:http/http.dart' as http;
import 'package:page_capture/src/filters/compiled_filters.dart';
import 'package:page_capture/src/filters/filter_compiler.dart';

abstract final class FilterSources {
  static const defaultLists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
  ];

  static const requestTimeout = Duration(seconds: 60);

  /// Downloads and compiles one list. Throws [FilterListException] for an
  /// unusable URL, a failed request or text that is not a filter list.
  static Future<CompiledFilters> download(
    http.Client client,
    String url, {
    required DateTime now,
  }) async {
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
    return FilterCompiler.compile([response.body], generated: now);
  }
}
