import 'dart:async';

import 'package:flutter/services.dart';
import 'package:page_capture/src/capture_cancellation.dart';
import 'package:page_capture/src/capture_options.dart';
import 'package:page_capture/src/capture_result.dart';

abstract final class PageCapture {
  static const _channel = MethodChannel('io.github.xarantolus/page_capture');

  static var _nextId = 0;

  /// Saves [url] as a web archive at [outputPath]. Two captures run at a
  /// time; further calls wait their turn. Never throws for a failed page: that is a
  /// [CaptureFailure].
  static Future<CaptureResult> capture(
    Uri url,
    String outputPath, {
    CaptureOptions options = const CaptureOptions(),
    CaptureCancellation? cancellation,
  }) async {
    final id = _nextId++;
    unawaited(
      cancellation?.whenCancelled.then(
        (_) => _channel.invokeMethod<void>('cancel', {'id': id}),
      ),
    );
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>('capture', {
        'id': id,
        'url': url.toString(),
        'outputPath': outputPath,
        ...options.toMap(),
      });
      return CaptureResult.fromMap(raw ?? const {});
    } on PlatformException catch (e) {
      return CaptureFailure(
        duration: Duration.zero,
        kind: CaptureFailureKind.internal,
        message: e.message ?? e.code,
      );
    }
  }

  /// False when no browser can take the archive.
  static Future<bool> openInCustomTab(String path) async =>
      await _channel.invokeMethod<bool>('openInCustomTab', {'path': path}) ??
      false;

  /// False when no app can show PDFs.
  static Future<bool> openPdf(String path) async =>
      await _channel.invokeMethod<bool>('openPdf', {'path': path}) ?? false;
}
