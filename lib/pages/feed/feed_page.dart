import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/pages/feed/feed_list.dart';
import 'package:offline_hn/pages/feed/sync_status.dart';
import 'package:offline_hn/pages/settings/settings_page.dart';
import 'package:offline_hn/sync/sync_controller.dart';
import 'package:offline_hn/ui/day_menu.dart';
import 'package:offline_hn/ui/feed_switcher.dart';
import 'package:offline_hn/ui/hacker_news_title.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final AppServices _services = AppServicesScope.of(context);
  late Stream<List<LocalDay>> _days = _services.stories.watchStoredDays(_kind);
  late final Stream<Set<FeedKind>> _enabled = _services.settings
      .watch()
      .map((s) => s.enabledFeeds)
      .distinct(setEquals);
  final _subscriptions = <StreamSubscription<Object?>>[];

  FeedKind _kind = FeedKind.top;
  LocalDay? _picked;
  bool _askedForNotifications = false;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_services.sync.progress.listen(_askForNotificationsOnce))
      ..add(_services.sync.connection.skip(1).listen(_onConnection));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  void _askForNotificationsOnce(Object? progress) {
    if (progress == null || _askedForNotifications) return;
    _askedForNotifications = true;
    unawaited(_services.askForNotificationsOnce());
  }

  void _onConnection(ConnectionKind kind) {
    if (kind != ConnectionKind.none) {
      unawaited(_services.sync.catchUpIfStale());
    }
  }

  void _select(FeedKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _days = _services.stories.watchStoredDays(kind);
    });
  }

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _services.sync.requestSync(SyncTrigger.manual);
    if (result == SyncRequest.noConnection) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No connection. Nothing to fetch.')),
        );
    }
  }

  void _openSettings() {
    unawaited(
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LocalDay>>(
      stream: _days,
      builder: (context, snapshot) {
        final days = snapshot.data ?? const <LocalDay>[];
        final today = localDayOf(DateTime.now());
        final picked = _picked;
        final day = picked != null && days.contains(picked)
            ? picked
            : (days.isEmpty ? today : days.first);
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const HackerNewsTitle(),
            actions: [
              DayMenu(
                days: days,
                selected: day,
                today: today,
                onSelected: (d) => setState(() => _picked = d),
              ),
              IconButton(
                tooltip: 'Fetch now',
                icon: const Icon(Icons.refresh),
                onPressed: () => unawaited(_refresh()),
              ),
              PopupMenuButton<void>(
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    onTap: _openSettings,
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              StreamBuilder<Set<FeedKind>>(
                stream: _enabled,
                builder: (context, enabled) => FeedSwitcher(
                  selected: _kind,
                  kinds: _kindsFor(enabled.data),
                  onSelected: _select,
                  status: SyncStatusLine(services: _services),
                ),
              ),
              SyncBar(services: _services),
              Expanded(
                child: FeedList(
                  services: _services,
                  kind: _kind,
                  day: day,
                  storeEmpty: days.isEmpty,
                  onRefresh: _refresh,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<FeedKind> _kindsFor(Set<FeedKind>? enabled) {
    if (enabled == null || enabled.isEmpty) return FeedKind.values;
    final shown = [
      for (final kind in FeedKind.values)
        if (enabled.contains(kind) || kind == _kind) kind,
    ];
    return shown;
  }
}
