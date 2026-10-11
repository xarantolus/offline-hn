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
  late final Map<FeedKind, Stream<List<LocalDay>>> _days = {
    for (final kind in FeedKind.values)
      kind: _services.stories.watchStoredDays(kind),
  };
  late final Stream<Set<FeedKind>> _enabled = _services.settings
      .watch()
      .map((s) => s.enabledFeeds)
      .distinct(setEquals);
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _pages = PageController();
  List<FeedKind> _shownKinds = FeedKind.values;

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
    _pages.dispose();
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
    final from = _shownKinds.indexOf(_kind);
    final to = _shownKinds.indexOf(kind);
    setState(() => _kind = kind);
    if ((from - to).abs() == 1) {
      unawaited(
        _pages.animateToPage(
          to,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    } else {
      _pages.jumpToPage(to);
    }
  }

  void _pageChanged(int index) {
    final kind = _shownKinds[index];
    if (kind != _kind) setState(() => _kind = kind);
  }

  void _followKinds(List<FeedKind> kinds) {
    if (listEquals(kinds, _shownKinds)) return;
    _shownKinds = kinds;
    final index = kinds.indexOf(_kind);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pages.hasClients) _pages.jumpToPage(index);
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
    return StreamBuilder<Set<FeedKind>>(
      stream: _enabled,
      builder: (context, enabled) {
        final kinds = _kindsFor(enabled.data);
        _followKinds(kinds);
        return StreamBuilder<List<LocalDay>>(
          stream: _days[_kind],
          builder: (context, snapshot) =>
              _scaffold(kinds, snapshot.data ?? const <LocalDay>[]),
        );
      },
    );
  }

  Widget _scaffold(List<FeedKind> kinds, List<LocalDay> days) {
    final today = localDayOf(DateTime.now());
    final day = shownDay(days, _picked, today);
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
          FeedSwitcher(
            selected: _kind,
            kinds: kinds,
            onSelected: _select,
            status: SyncStatusLine(services: _services),
          ),
          SyncBar(services: _services),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              physics: const BouncingScrollPhysics(),
              itemCount: kinds.length,
              onPageChanged: _pageChanged,
              itemBuilder: (context, index) => _FeedPane(
                services: _services,
                kind: kinds[index],
                days: _days[kinds[index]]!,
                picked: _picked,
                onRefresh: _refresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FeedKind> _kindsFor(Set<FeedKind>? enabled) {
    if (enabled == null || enabled.isEmpty) return FeedKind.values;
    return [
      for (final kind in FeedKind.values)
        if (enabled.contains(kind) || kind == _kind) kind,
    ];
  }
}

class _FeedPane extends StatelessWidget {
  const _FeedPane({
    required this.services,
    required this.kind,
    required this.days,
    required this.picked,
    required this.onRefresh,
  });

  final AppServices services;
  final FeedKind kind;
  final Stream<List<LocalDay>> days;
  final LocalDay? picked;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LocalDay>>(
      stream: days,
      builder: (context, snapshot) {
        final stored = snapshot.data ?? const <LocalDay>[];
        return FeedList(
          services: services,
          kind: kind,
          day: shownDay(stored, picked, localDayOf(DateTime.now())),
          storeEmpty: stored.isEmpty,
          onRefresh: onRefresh,
        );
      },
    );
  }
}
