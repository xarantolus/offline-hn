import 'package:json_annotation/json_annotation.dart';

part 'capture_result.g.dart';

/// Where a capture spent its time. A phase it never reached is zero.
class CaptureTimings {
  const CaptureTimings({
    this.load = Duration.zero,
    this.idle = Duration.zero,
    this.scroll = Duration.zero,
    this.cleanup = Duration.zero,
    this.save = Duration.zero,
  });

  factory CaptureTimings.fromJson(Map<Object?, Object?> json) {
    Duration phase(String name) =>
        Duration(milliseconds: json[name] as int? ?? 0);

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

Duration _milliseconds(int value) => Duration(milliseconds: value);

CaptureTimings _timings(Map<Object?, Object?> value) =>
    CaptureTimings.fromJson(value);

sealed class CaptureResult {
  const CaptureResult({required this.duration});

  /// The payload comes from this package's own native side, so a payload that
  /// does not match throws.
  factory CaptureResult.fromMap(Map<Object?, Object?> map) {
    final json = Map<String, Object?>.from(map);
    return switch (json['ok']) {
      true => CaptureSuccess.fromJson(json),
      false => CaptureFailure.fromJson(json),
      final other => throw FormatException('capture result ok', other),
    };
  }

  @JsonKey(name: 'millis', fromJson: _milliseconds)
  final Duration duration;
}

@JsonSerializable(createToJson: false, checked: true)
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

  factory CaptureSuccess.fromJson(Map<String, Object?> json) =>
      _$CaptureSuccessFromJson(json);

  final int bytes;
  @JsonKey(name: 'resources')
  final int resourceCount;
  @JsonKey(name: 'blocked')
  final int blockedRequests;
  @JsonKey(name: 'removed')
  final int removedElements;

  /// Names of the consent managers whose popup was rejected.
  @JsonKey(name: 'consent')
  final List<String> consentHandlers;
  final Uri? finalUrl;

  /// Network or element blocking was asked for but no filter list was
  /// available, so the page was captured without it.
  final bool listsMissing;
  @JsonKey(name: 'phases', fromJson: _timings)
  final CaptureTimings timings;
}

@JsonSerializable(createToJson: false, checked: true)
class CaptureFailure extends CaptureResult {
  const CaptureFailure({
    required super.duration,
    required this.kind,
    this.message = '',
    this.httpStatus,
    this.contentType,
  });

  factory CaptureFailure.fromJson(Map<String, Object?> json) =>
      _$CaptureFailureFromJson(json);

  @JsonKey(name: 'error')
  final CaptureFailureKind kind;
  final String message;
  final int? httpStatus;

  /// Set for [CaptureFailureKind.unsupportedContent].
  final String? contentType;

  bool get isPdf => contentType == 'application/pdf';
}
