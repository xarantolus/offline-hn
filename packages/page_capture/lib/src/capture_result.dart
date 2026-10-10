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
