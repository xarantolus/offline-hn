import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'filter_list_status.g.dart';

/// What the last attempts at one filter list achieved.
@JsonSerializable(checked: true)
class FilterListStatus {
  const FilterListStatus({
    this.updatedAt,
    this.checkedAt,
    this.networkRules = 0,
    this.cosmeticRules = 0,
    this.error,
  });

  factory FilterListStatus.fromJson(Map<String, Object?> json) =>
      _$FilterListStatusFromJson(json);

  /// When a good copy was last stored; null if there never was one.
  @JsonKey(toJson: _utc)
  final DateTime? updatedAt;

  /// When a download was last tried, successful or not.
  @JsonKey(toJson: _utc)
  final DateTime? checkedAt;
  @JsonKey(defaultValue: 0)
  final int networkRules;
  @JsonKey(defaultValue: 0)
  final int cosmeticRules;

  /// Why the last attempt failed; null after a success.
  final String? error;

  bool get hasCopy => updatedAt != null;

  FilterListStatus failed(String message, DateTime now) => FilterListStatus(
    updatedAt: updatedAt,
    checkedAt: now,
    networkRules: networkRules,
    cosmeticRules: cosmeticRules,
    error: message,
  );

  Map<String, Object?> toJson() => _$FilterListStatusToJson(this);

  static Map<String, FilterListStatus> decodeAll(String raw) {
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return {
      for (final entry in decoded.entries)
        entry.key: FilterListStatus.fromJson(
          entry.value! as Map<String, Object?>,
        ),
    };
  }

  static String encodeAll(Map<String, FilterListStatus> statuses) => jsonEncode(
    {for (final entry in statuses.entries) entry.key: entry.value.toJson()},
  );
}

String? _utc(DateTime? time) => time?.toUtc().toIso8601String();
