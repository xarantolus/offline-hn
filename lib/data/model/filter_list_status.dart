import 'dart:convert';

/// What the last attempts at one filter list achieved.
class FilterListStatus {
  const FilterListStatus({
    this.updatedAt,
    this.checkedAt,
    this.networkRules = 0,
    this.cosmeticRules = 0,
    this.error,
  });

  /// When a good copy was last stored; null if there never was one.
  final DateTime? updatedAt;

  /// When a download was last tried, successful or not.
  final DateTime? checkedAt;
  final int networkRules;
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

  Map<String, Object?> toJson() => {
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'checkedAt': checkedAt?.toUtc().toIso8601String(),
    'networkRules': networkRules,
    'cosmeticRules': cosmeticRules,
    'error': error,
  };

  static FilterListStatus fromJson(Map<String, Object?> json) =>
      FilterListStatus(
        updatedAt: _time(json['updatedAt']),
        checkedAt: _time(json['checkedAt']),
        networkRules: json['networkRules'] is int
            ? json['networkRules']! as int
            : 0,
        cosmeticRules: json['cosmeticRules'] is int
            ? json['cosmeticRules']! as int
            : 0,
        error: json['error'] is String ? json['error']! as String : null,
      );

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  static Map<String, FilterListStatus> decodeAll(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('filter list status', raw);
    }
    return {
      for (final entry in decoded.entries)
        if (entry.value is Map<String, Object?>)
          entry.key: fromJson(entry.value! as Map<String, Object?>),
    };
  }

  static String encodeAll(Map<String, FilterListStatus> statuses) => jsonEncode(
    {for (final entry in statuses.entries) entry.key: entry.value.toJson()},
  );
}
