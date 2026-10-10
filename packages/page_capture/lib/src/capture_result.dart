/// Where a capture spent its time. A phase it never reached is zero.
class CaptureTimings {
  const CaptureTimings({
    this.load = Duration.zero,
    this.idle = Duration.zero,
    this.scroll = Duration.zero,
    this.cleanup = Duration.zero,
    this.save = Duration.zero,
  });

  factory CaptureTimings.fromMap(Object? raw) {
    Duration phase(String name) {
      final value = raw is Map<Object?, Object?> ? raw[name] : null;
      return Duration(milliseconds: value is num ? value.toInt() : 0);
    }

    return CaptureTimings(
      load: phase('load'),
      idle: phase('idle'),
      scroll: phase('scroll'),
      cleanup: phase('cleanup'),
      save: phase('save'),
    );
  }

  /// Until the main document finished loading.
  final Duration load;

  /// Waiting for the page's resources to go quiet after that.
  final Duration idle;

  /// Scrolling through the page, then waiting for quiet again.
  final Duration scroll;

  /// Consent popup wait and settle, overlay and element removal, final settle.
  final Duration cleanup;

  /// `saveWebArchive`.
  final Duration save;
}

enum CaptureFailureKind {
  timeout,
  http,
  ssl,
  network,
  tooLarge,
  unsupportedContent,
  cancelled,
  internal,
}

sealed class CaptureResult {
  const CaptureResult({required this.duration});

  factory CaptureResult.fromMap(Map<Object?, Object?> map) {
    final duration = Duration(milliseconds: _int(map['millis']) ?? 0);
    if (map['ok'] == true) {
      return CaptureSuccess(
        duration: duration,
        bytes: _int(map['bytes']) ?? 0,
        resourceCount: _int(map['resources']) ?? 0,
        blockedRequests: _int(map['blocked']) ?? 0,
        removedElements: _int(map['removed']) ?? 0,
        consentHandlers: [
          for (final name in map['consent'] as List<Object?>? ?? const [])
            if (name is String) name,
        ],
        finalUrl: map['finalUrl'] as String?,
        listsMissing: map['listsMissing'] == true,
        timings: CaptureTimings.fromMap(map['phases']),
      );
    }
    return CaptureFailure(
      duration: duration,
      kind: _kind(map['error'] as String?),
      message: map['message'] as String? ?? '',
      httpStatus: _int(map['httpStatus']),
      contentType: map['contentType'] as String?,
    );
  }

  final Duration duration;

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static CaptureFailureKind _kind(String? name) {
    for (final kind in CaptureFailureKind.values) {
      if (kind.name == name) return kind;
    }
    return CaptureFailureKind.internal;
  }
}

class CaptureSuccess extends CaptureResult {
  const CaptureSuccess({
    required super.duration,
    required this.bytes,
    required this.resourceCount,
    this.blockedRequests = 0,
    this.removedElements = 0,
    this.consentHandlers = const [],
    this.finalUrl,
    this.listsMissing = false,
    this.timings = const CaptureTimings(),
  });

  final int bytes;
  final int resourceCount;
  final int blockedRequests;
  final int removedElements;

  /// Names of the consent managers whose popup was rejected.
  final List<String> consentHandlers;
  final String? finalUrl;

  /// Network or element blocking was asked for but no filter list was
  /// available, so the page was captured without it.
  final bool listsMissing;
  final CaptureTimings timings;
}

class CaptureFailure extends CaptureResult {
  const CaptureFailure({
    required super.duration,
    required this.kind,
    this.message = '',
    this.httpStatus,
    this.contentType,
  });

  final CaptureFailureKind kind;
  final String message;
  final int? httpStatus;

  /// Set for [CaptureFailureKind.unsupportedContent].
  final String? contentType;

  bool get isPdf => contentType == 'application/pdf';
}
