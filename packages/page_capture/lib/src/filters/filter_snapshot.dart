import 'package:http/http.dart' as http;
import 'package:page_capture/src/filters/compiled_filters.dart';
import 'package:page_capture/src/filters/filter_compiler.dart';

abstract final class FilterSources {
  static const lists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
  ];

  static const requestTimeout = Duration(seconds: 60);

  /// Downloads and compiles the lists; throws before returning anything if one
  /// is bad, so callers never store half an update.
  static Future<CompiledFilters> download(
    http.Client client, {
    required DateTime now,
  }) async {
    final texts = [for (final url in lists) await _get(client, url)];
    return FilterCompiler.compile(texts, generated: now);
  }

  static Future<String> _get(http.Client client, String url) async {
    final response = await client.get(Uri.parse(url)).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw FilterListException('$url answered ${response.statusCode}');
    }
    return response.body;
  }
}
