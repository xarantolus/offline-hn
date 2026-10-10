class LocalDay implements Comparable<LocalDay> {
  const LocalDay(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  LocalDay next() {
    final d = DateTime.utc(year, month, day + 1);
    return LocalDay(d.year, d.month, d.day);
  }

  DateTime get asUtcMidnight => DateTime.utc(year, month, day);

  @override
  int compareTo(LocalDay other) => asUtcMidnight.compareTo(other.asUtcMidnight);

  @override
  bool operator ==(Object other) =>
      other is LocalDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

class DayBounds {
  const DayBounds(this.startUtc, this.endUtc);

  final DateTime startUtc;
  final DateTime endUtc;

  bool contains(DateTime instant) =>
      !instant.isBefore(startUtc) && instant.isBefore(endUtc);
}
