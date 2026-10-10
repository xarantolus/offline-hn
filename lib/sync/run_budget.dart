/// WorkManager stops a job at about ten minutes; a run that would not finish
/// pauses at a checkpoint instead and is continued by a new job.
class RunBudget {
  RunBudget({required this.startedAt, this.limit = const Duration(minutes: 9)});

  final DateTime startedAt;
  final Duration limit;

  /// Whether an item that can take up to [worstCase] still fits.
  bool fits(DateTime now, Duration worstCase) =>
      now.add(worstCase).isBefore(startedAt.add(limit));
}
