import 'package:offline_hn/data/api/models.dart';

int? lenientInt(Object? value) => switch (value) {
  final num n => n.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};

String? lenientString(Object? value) => value is String ? value : null;

bool lenientBool(Object? value) => value is bool && value;

DateTime? epochSeconds(Object? value) {
  final seconds = lenientInt(value);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}

Uri? lenientUri(Object? value) {
  final uri = value is String ? Uri.tryParse(value) : null;
  return uri != null && uri.hasScheme && uri.host.isNotEmpty ? uri : null;
}

ItemType? lenientItemType(Object? value) {
  for (final type in ItemType.values) {
    if (type.name == value) return type;
  }
  return null;
}

List<int> lenientIds(Object? value) => [
  if (value is List<Object?>)
    for (final id in value) ?lenientInt(id),
];

List<String> lenientStrings(Object? value) => [
  if (value is List<Object?>)
    for (final s in value) ?lenientString(s),
];

List<T> lenientObjects<T>(
  Object? value,
  T Function(Map<String, Object?> json) read,
) => [
  if (value is List<Object?>)
    for (final item in value)
      if (item is Map<String, Object?>) read(item),
];
