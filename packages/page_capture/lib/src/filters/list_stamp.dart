/// `2026-10-10T12:42:34.000Z`: fixed width, so stamps compare as plain strings.
String listStamp(DateTime time) => DateTime.fromMillisecondsSinceEpoch(
  time.millisecondsSinceEpoch ~/ 1000 * 1000,
  isUtc: true,
).toIso8601String();
