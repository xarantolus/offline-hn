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
    this.stallTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  static const _magic = [0x25, 0x50, 0x44, 0x46, 0x2d];

  /// A PDF may be preceded by a little junk; readers accept the signature
  /// anywhere in the first kilobyte.
  static const _signatureWindow = 1024;

  static const _maxRedirects = 5;

  final http.Client _client;

  /// The whole download, from the request to the last byte.
  final Duration timeout;

  /// Until the response headers arrive.
  final Duration connectTimeout;

  /// The longest wait for the next piece of the body.
  final Duration stallTimeout;

  /// Writes to a staging file and renames it, so [target] is either complete
  /// or absent: any failure leaves nothing behind.
  Future<PdfResult> download(
    Uri url,
    File target, {
    required int maxBytes,
  }) async {
    final staging = File('${target.path}.part');
    try {
      return await _fetch(url, staging, target, maxBytes);
    } on TimeoutException {
      return const PdfFailed('timed out');
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
    final clock = Stopwatch()..start();
    final request = http.Request('GET', url)
      ..followRedirects = true
      ..maxRedirects = _maxRedirects;
    final response = await _client.send(request).timeout(connectTimeout);
    if (response.statusCode != 200) {
      await response.stream.listen(null).cancel();
      return PdfFailed(
        response.statusCode == 204
            ? 'no content'
            : 'answered ${response.statusCode}',
      );
    }
    final declared = response.contentLength;
    if (declared != null && declared > maxBytes) {
      await response.stream.listen(null).cancel();
      return const PdfTooLarge();
    }

    await staging.parent.create(recursive: true);
    final sink = staging.openWrite();
    final head = <int>[];
    var checked = false;
    var bytes = 0;
    try {
      await for (final chunk in response.stream.timeout(stallTimeout)) {
        if (clock.elapsed > timeout) throw TimeoutException('download');
        bytes += chunk.length;
        if (bytes > maxBytes) return const PdfTooLarge();
        if (!checked) {
          head.addAll(chunk);
          if (_hasSignature(head)) {
            checked = true;
            sink.add(head);
          } else if (head.length >= _signatureWindow) {
            return const PdfFailed('not a PDF');
          }
          continue;
        }
        sink.add(chunk);
      }
      if (!checked) {
        if (!_hasSignature(head)) {
          return PdfFailed(bytes == 0 ? 'empty response' : 'not a PDF');
        }
        sink.add(head);
      }
    } finally {
      await sink.close();
    }
    if (declared != null && declared != bytes) {
      return const PdfFailed('incomplete download');
    }
    await staging.rename(target.path);
    return PdfSaved(bytes);
  }

  bool _hasSignature(List<int> head) {
    final window = head.length < _signatureWindow
        ? head.length
        : _signatureWindow;
    for (var start = 0; start + _magic.length <= window; start++) {
      var match = true;
      for (var i = 0; i < _magic.length && match; i++) {
        match = head[start + i] == _magic[i];
      }
      if (match) return true;
    }
    return false;
  }
}
