// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_list_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilterListStatus _$FilterListStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FilterListStatus', json, ($checkedConvert) {
      final val = FilterListStatus(
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        checkedAt: $checkedConvert(
          'checkedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        networkRules: $checkedConvert(
          'networkRules',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        cosmeticRules: $checkedConvert(
          'cosmeticRules',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$FilterListStatusToJson(FilterListStatus instance) =>
    <String, dynamic>{
      'updatedAt': _utc(instance.updatedAt),
      'checkedAt': _utc(instance.checkedAt),
      'networkRules': instance.networkRules,
      'cosmeticRules': instance.cosmeticRules,
      'error': instance.error,
    };
