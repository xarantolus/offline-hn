import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class HnApiException implements Exception {
  const HnApiException(this.uri, {this.statusCode, this.cause});

  final Uri uri;
  final int? statusCode;
  final Object? cause;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'HnApiException($uri, status: $statusCode, $cause)';
}

class HnHttp {
  HnHttp({http.Client? client, this.timeout = const Duration(seconds: 15)})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<Object?> getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on Exception catch (e) {
      throw HnApiException(uri, cause: e);
    }
    if (response.statusCode != 200) {
      throw HnApiException(uri, statusCode: response.statusCode);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw HnApiException(uri, statusCode: response.statusCode, cause: e);
    }
  }

  void close() => _client.close();
}
