String formatAge(Duration age) {
  if (age.inDays >= 1) return '${age.inDays}d';
  if (age.inHours >= 1) return '${age.inHours}h';
  return '${age.inMinutes}m';
}

String formatCount(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String pluralize(int n, String one, [String? many]) =>
    '${formatCount(n)} ${n == 1 ? one : (many ?? '${one}s')}';

String formatSize(int bytes) {
  const kilo = 1024;
  if (bytes < kilo * kilo) return '${(bytes / kilo).round()} KB';
  return '${(bytes / (kilo * kilo)).toStringAsFixed(1)} MB';
}
