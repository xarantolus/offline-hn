import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/sync_status_text.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/ui/small_caps.dart';

/// "Updated 06:12 · wifi", or what the running sync is doing.
class SyncStatusLine extends StatefulWidget {
  const SyncStatusLine({super.key, required this.services});

  final AppServices services;

  @override
  State<SyncStatusLine> createState() => _SyncStatusLineState();
}

class _SyncStatusLineState extends State<SyncStatusLine> {
  late final Stream<SyncProgress?> _progress = widget.services.sync.progress;
  late final Stream<DateTime?> _lastSync = widget.services.sync.lastSync;
  late final Stream<ConnectionKind> _connection =
      widget.services.sync.connection;
  late final Stream<DateTime?> _stored = widget.services.stories
      .watchNewestFetch();

  String? _clock(DateTime? at) {
    if (at == null) return null;
    final l10n = MaterialLocalizations.of(context);
    return l10n.formatTimeOfDay(
      TimeOfDay.fromDateTime(at.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncProgress?>(
      stream: _progress,
      builder: (context, progress) => StreamBuilder<DateTime?>(
        stream: _lastSync,
        builder: (context, last) => StreamBuilder<DateTime?>(
          stream: _stored,
          builder: (context, stored) => StreamBuilder<ConnectionKind>(
            stream: _connection,
            builder: (context, connection) => SmallCaps(
              syncStatusText(
                progress: progress.data,
                updatedAt: _clock(last.data),
                storedAt: _clock(stored.data),
                connection: connection.data,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin bar while a sync runs, and nothing the rest of the time.
class SyncBar extends StatefulWidget {
  const SyncBar({super.key, required this.services});

  final AppServices services;

  @override
  State<SyncBar> createState() => _SyncBarState();
}

class _SyncBarState extends State<SyncBar> {
  late final Stream<SyncProgress?> _progress = widget.services.sync.progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: StreamBuilder<SyncProgress?>(
        stream: _progress,
        builder: (context, snapshot) {
          final progress = snapshot.data;
          if (progress == null) return const SizedBox.shrink();
          final known = progress.total > 0;
          return LinearProgressIndicator(
            value: known ? progress.done / progress.total : null,
          );
        },
      ),
    );
  }
}
