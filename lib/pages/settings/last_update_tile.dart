import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/overview_text.dart';
import 'package:offline_hn/data/policy/run_history.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/pages/overview/overview_page.dart';
import 'package:offline_hn/pages/overview/run_tiles.dart';
import 'package:offline_hn/ui/time_text.dart';
import 'package:offline_hn/ui/tokens.dart';

/// How the last update went and when the next is due; opens the overview.
class LastUpdateTile extends StatefulWidget {
  const LastUpdateTile({
    super.key,
    required this.services,
    required this.settings,
  });

  final AppServices services;
  final AppSettings settings;

  @override
  State<LastUpdateTile> createState() => _LastUpdateTileState();
}

class _LastUpdateTileState extends State<LastUpdateTile> {
  late final Stream<RunRecord?> _latest = widget.services.overview
      .watchLatestRun();
  late final Stream<SyncProgress?> _progress = widget.services.sync.progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return StreamBuilder<RunRecord?>(
      stream: _latest,
      builder: (context, latest) => StreamBuilder<SyncProgress?>(
        stream: _progress,
        builder: (context, progress) {
          final run = latest.data;
          final now = DateTime.now();
          final next = nextDailyText(
            settings: widget.settings,
            now: now,
            when: (at) => whenText(context, at),
          );
          return ListTile(
            title: Text('Last update', style: t.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run == null
                      ? 'No updates yet'
                      : runTitle(context, run, now, progress.data),
                  style: t.hint,
                ),
                Text('Next daily update: $next', style: t.hint),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openOverview(context),
          );
        },
      ),
    );
  }
}
