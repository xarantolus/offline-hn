import 'package:offline_hn/data/model/local_day.dart';

/// Automatic updates held back until [resumeOn] begins, or until they are
/// turned back on when it is null.
class UpdatePause {
  const UpdatePause.until(LocalDay this.resumeOn);

  const UpdatePause.indefinitely() : resumeOn = null;

  final LocalDay? resumeOn;

  static const _indefinitely = 'indefinitely';

  static UpdatePause decode(String raw) {
    if (raw == _indefinitely) return const UpdatePause.indefinitely();
    final parts = raw.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) {
      throw FormatException('update pause', raw);
    }
    return UpdatePause.until(LocalDay(parts[0]!, parts[1]!, parts[2]!));
  }

  String encode() => resumeOn?.toString() ?? _indefinitely;

  @override
  bool operator ==(Object other) =>
      other is UpdatePause && other.resumeOn == resumeOn;

  @override
  int get hashCode => resumeOn.hashCode;
}
