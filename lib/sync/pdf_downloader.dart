import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

sealed class PdfResult {
  const PdfResult();
}

class PdfSaved extends PdfResult {
  const PdfSaved(this.bytes);

  final int bytes;
}

class PdfTooLarge extends PdfResult {
  const PdfTooLarge();
}

class PdfFailed extends PdfResult {
  const PdfFailed(this.reason);

  final String reason;
}

class PdfDownloader {
  PdfDownloader({
    http.Client? client,
    this.timeout = const Duration(minutes: 2),
    this.connectTimeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  static const _magic = [0x25, 0x50, 0x44, 0x46];

  final http.Client _client;
  final Duration timeout;
  final Duration connectTimeout;

  /// Writes to a staging file and renames it, so [target] is either complete
  /// or absent.
  Future<PdfResult> download(
    Uri url,
    File target, {
    required int maxBytes,
  }) async {
    final staging = File('${target.path}.part');
    try {
      return await _fetch(url, staging, target, maxBytes).timeout(timeout);
    } on Exception catch (e) {
      return PdfFailed('$e');
    } finally {
      if (staging.existsSync()) await staging.delete();
    }
  }

  Future<PdfResult> _fetch(
    Uri url,
    File staging,
    File target,
    int maxBytes,
  ) async {
    final response = await _client
        .send(http.Request('GET', url))
        .timeout(connectTimeout);
    if (response.statusCode != 200) {
      return PdfFailed('answered ${response.statusCode}');
    }
    final declared = response.contentLength;
    if (declared != null && declared > maxBytes) return const PdfTooLarge();

    await staging.parent.create(recursive: true);
    final sink = staging.openWrite();
    var bytes = 0;
    var first = true;
    try {
      await for (final chunk in response.stream) {
        if (first) {
          first = false;
          if (!_looksLikePdf(chunk)) return const PdfFailed('not a PDF');
        }
        bytes += chunk.length;
        if (bytes > maxBytes) return const PdfTooLarge();
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
    if (bytes == 0) return const PdfFailed('empty response');
    await staging.rename(target.path);
    return PdfSaved(bytes);
  }

  bool _looksLikePdf(List<int> chunk) {
    if (chunk.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (chunk[i] != _magic[i]) return false;
    }
    return true;
  }
}
