import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/data/policy/run_history.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/pages/overview/run_tiles.dart';
import 'package:offline_hn/pages/thread/thread_pager.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

void openRunDetails(BuildContext context, int runId) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => RunDetailsPage(runId: runId)));
}

/// One update: what it did, and what went wrong grouped by reason.
class RunDetailsPage extends StatefulWidget {
  const RunDetailsPage({super.key, required this.runId});

  final int runId;

  @override
  State<RunDetailsPage> createState() => _RunDetailsPageState();
}

class _RunDetailsPageState extends State<RunDetailsPage> {
  late final AppServices _services = AppServicesScope.of(context);
  late final Stream<RunRecord?> _run = _services.overview.watchRuns().map((
    runs,
  ) {
    for (final run in runs) {
      if (run.id == widget.runId) return run;
    }
    return null;
  });
  late final Stream<SyncProgress?> _progress = _services.sync.progress;
  Future<List<FailedItem>>? _failures;
  int _failureCount = -1;

  Future<List<FailedItem>> _failuresFor(RunRecord run) {
    final count =
        run.tally.threadsFailed +
        run.tally.articlesFailed +
        run.tally.linksFailed;
    if (count != _failureCount || _failures == null) {
      _failureCount = count;
      _failures = _services.overview.failedItems(run.id);
    }
    return _failures!;
  }

  void _open(FailedItem item) {
    final id = item.storyId;
    if (id == null) return;
    openThread(context, _services, storyId: id, storyIds: [id]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update')),
      body: StreamBuilder<RunRecord?>(
        stream: _run,
        builder: (context, snapshot) {
          final run = snapshot.data;
          if (run == null) {
            return snapshot.connectionState == ConnectionState.waiting
                ? const SizedBox.shrink()
                : const Center(child: Text('This update is no longer kept'));
          }
          return StreamBuilder<SyncProgress?>(
            stream: _progress,
            builder: (context, progress) => FutureBuilder<List<FailedItem>>(
              future: _failuresFor(run),
              builder: (context, failures) => _body(
                run,
                progress.data,
                groupFailures(failures.data ?? const []),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(
    RunRecord run,
    SyncProgress? progress,
    List<FailureGroup> groups,
  ) {
    final t = context.tokens;
    final now = DateTime.now();
    final state = runState(run, now);
    final overview = runOverview(run);
    final rows = <Widget>[for (final group in groups) ..._groupRows(group)];
    return ListView(
      padding: EdgeInsets.only(
        top: Spacing.lg,
        bottom: MediaQuery.viewPaddingOf(context).bottom + Spacing.lg,
      ),
      children: [
        SettingsSection(
          title: 'Summary',
          children: [
            ListTile(
              leading: Icon(
                stateIcon(state),
                color: stateColor(context, state),
              ),
              title: Text(
                runTitle(context, run, now, progress),
                style: t.label,
              ),
              subtitle: Text(runCause(run), style: t.hint),
            ),
            if (overview.isEmpty)
              ListTile(title: Text('Nothing was changed', style: t.label)),
            for (final line in overview)
              ListTile(dense: true, title: Text(line, style: t.label)),
          ],
        ),
        if (groups.isNotEmpty) ...[
          const SizedBox(height: Spacing.xl),
          const SectionLabel('Problems'),
          const SizedBox(height: Spacing.sm),
          const Hairline(),
          Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
          const Hairline(),
        ],
      ],
    );
  }

  List<Widget> _groupRows(FailureGroup group) {
    final t = context.tokens;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.gutter,
          Spacing.lg,
          Spacing.gutter,
          Spacing.xs,
        ),
        child: Text(
          '${group.reason} · ${formatCount(group.items.length)}',
          style: t.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      for (final item in group.items)
        ListTile(
          dense: true,
          title: Text(
            item.title ?? 'Removed since',
            style: t.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            failureKindLabel(item.kind, asThread: item.asThread),
            style: t.hint,
          ),
          onTap: item.storyId == null ? null : () => _open(item),
        ),
    ];
  }
}
