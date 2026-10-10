Map<String, Object?>? jsonMap(Object? value) {
  if (value is! Map<String, Object?>) return null;
  return value;
}

List<Object?> jsonList(Object? value) =>
    value is List<Object?> ? value : const [];

String? jsonString(Object? value) => value is String ? value : null;

int? jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool jsonBool(Object? value) => value is bool && value;

DateTime? jsonEpochSeconds(Object? value) {
  final seconds = jsonInt(value);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}
