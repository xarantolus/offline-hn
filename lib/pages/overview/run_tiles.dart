import 'package:flutter/material.dart';
import 'package:offline_hn/data/policy/run_history.dart';
import 'package:offline_hn/data/policy/sync_status_text.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/ui/time_text.dart';
import 'package:offline_hn/ui/tokens.dart';

/// "Today 05:03 · 14 min · Completed", or what the run is doing right now.
String runTitle(
  BuildContext context,
  RunRecord run,
  DateTime now,
  SyncProgress? progress,
) {
  final when = whenText(context, run.startedAt, now: now);
  if (runState(run, now) == RunState.running && progress?.runId == run.id) {
    return '$when · ${progressLabel(progress!)}';
  }
  return runHeadline(run, now: now, when: when);
}

IconData stateIcon(RunState state) => switch (state) {
  RunState.running => Icons.sync,
  RunState.paused => Icons.pause_circle_outline,
  RunState.completed => Icons.check_circle_outline,
  RunState.failed => Icons.error_outline,
  RunState.stopped => Icons.stop_circle_outlined,
};

Color stateColor(BuildContext context, RunState state) => switch (state) {
  RunState.running => context.tokens.accent,
  RunState.failed => Theme.of(context).colorScheme.error,
  _ => context.tokens.muted,
};

class RunTile extends StatelessWidget {
  const RunTile({
    super.key,
    required this.run,
    required this.progress,
    required this.now,
    required this.onTap,
    this.detailed = false,
  });

  final RunRecord run;
  final SyncProgress? progress;
  final DateTime now;
  final VoidCallback onTap;

  /// Every fact the run recorded, instead of a one-line gist.
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final state = runState(run, now);
    final lines = detailed ? runOverview(run) : [runGist(run)];
    return ListTile(
      leading: Icon(stateIcon(state), color: stateColor(context, state)),
      title: Text(runTitle(context, run, now, progress), style: t.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(runCause(run), style: t.hint),
          for (final line in lines)
            if (line.isNotEmpty) Text(line, style: t.hint),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
