const resumeWindow = Duration(hours: 3);

bool canResumeRun(DateTime startedAt, DateTime now) =>
    now.difference(startedAt) <= resumeWindow;

/// Longer than the slowest single item (a page capture is cut off at about
/// two and a half minutes).
const runHeartbeatTimeout = Duration(minutes: 4);

/// An open run whose process was killed never finishes; without a recent sign
/// of life it must not be shown as running.
bool runIsAlive(DateTime heartbeat, DateTime now) {
  final age = now.difference(heartbeat);
  return age.isNegative || age <= runHeartbeatTimeout;
}
