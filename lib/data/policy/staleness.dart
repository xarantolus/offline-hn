const staleAfter = Duration(hours: 2);

/// A last sync in the future means the clock was set back; that cannot be
/// trusted as fresh.
bool isStale(DateTime? lastSuccessfulSync, DateTime now) {
  if (lastSuccessfulSync == null) return true;
  final age = now.difference(lastSuccessfulSync);
  return age.isNegative || age > staleAfter;
}
