// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptureSuccess _$CaptureSuccessFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CaptureSuccess',
  json,
  ($checkedConvert) {
    final val = CaptureSuccess(
      duration: $checkedConvert(
        'millis',
        (v) => _milliseconds((v as num).toInt()),
      ),
      bytes: $checkedConvert('bytes', (v) => (v as num).toInt()),
      resourceCount: $checkedConvert('resources', (v) => (v as num).toInt()),
      blockedRequests: $checkedConvert(
        'blocked',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      removedElements: $checkedConvert(
        'removed',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      consentHandlers: $checkedConvert(
        'consent',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      finalUrl: $checkedConvert(
        'finalUrl',
        (v) => v == null ? null : Uri.parse(v as String),
      ),
      listsMissing: $checkedConvert('listsMissing', (v) => v as bool? ?? false),
      timings: $checkedConvert(
        'phases',
        (v) => v == null ? const CaptureTimings() : _timings(v as Map),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'duration': 'millis',
    'resourceCount': 'resources',
    'blockedRequests': 'blocked',
    'removedElements': 'removed',
    'consentHandlers': 'consent',
    'timings': 'phases',
  },
);

CaptureFailure _$CaptureFailureFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CaptureFailure', json, ($checkedConvert) {
      final val = CaptureFailure(
        duration: $checkedConvert(
          'millis',
          (v) => _milliseconds((v as num).toInt()),
        ),
        kind: $checkedConvert(
          'error',
          (v) => $enumDecode(_$CaptureFailureKindEnumMap, v),
        ),
        message: $checkedConvert('message', (v) => v as String? ?? ''),
        httpStatus: $checkedConvert('httpStatus', (v) => (v as num?)?.toInt()),
        contentType: $checkedConvert('contentType', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'duration': 'millis', 'kind': 'error'});

const _$CaptureFailureKindEnumMap = {
  CaptureFailureKind.timeout: 'timeout',
  CaptureFailureKind.http: 'http',
  CaptureFailureKind.ssl: 'ssl',
  CaptureFailureKind.network: 'network',
  CaptureFailureKind.tooLarge: 'tooLarge',
  CaptureFailureKind.unsupportedContent: 'unsupportedContent',
  CaptureFailureKind.cancelled: 'cancelled',
  CaptureFailureKind.internal: 'internal',
};
