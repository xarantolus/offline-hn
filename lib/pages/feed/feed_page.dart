import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/feed_tab.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/keep_window.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/pages/feed/feed_list.dart';
import 'package:offline_hn/pages/feed/search_page.dart';
import 'package:offline_hn/pages/feed/sync_status.dart';
import 'package:offline_hn/pages/overview/overview_page.dart';
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
  late final Stream<SyncProgress?> _progress = _services.sync.progress;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _pages = PageController();
  List<FeedTab> _shownTabs = FeedTab.values;

  FeedTab _tab = FeedTab.top;
  LocalDay? _picked;
  bool _askedForNotifications = false;
  int _keepDays = defaultKeepDays;

  /// Null until the settings have been read, so a list is never built with the
  /// wrong answer and then animated into the right one.
  bool? _hideRead;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_services.settings.watch().listen(_onSettings))
      ..add(_services.sync.progress.listen(_askForNotificationsOnce))
      ..add(_services.sync.connection.skip(1).listen(_onConnection));
  }

  void _onSettings(AppSettings settings) {
    if (settings.keepDays == _keepDays &&
        settings.hideReadStories == _hideRead) {
      return;
    }
    setState(() {
      _keepDays = settings.keepDays;
      _hideRead = settings.hideReadStories;
    });
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

  void _select(FeedTab tab) {
    if (tab == _tab) return;
    final from = _shownTabs.indexOf(_tab);
    final to = _shownTabs.indexOf(tab);
    setState(() => _tab = tab);
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
    final tab = _shownTabs[index];
    if (tab != _tab) setState(() => _tab = tab);
  }

  void _followTabs(List<FeedTab> tabs) {
    if (listEquals(tabs, _shownTabs)) return;
    _shownTabs = tabs;
    final index = tabs.indexOf(_tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pages.hasClients) _pages.jumpToPage(index);
    });
  }

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _services.sync.requestSync(SyncTrigger.refresh);
    if (result == SyncRequest.noConnection) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No connection. Nothing to fetch.')),
        );
    }
  }

  void _showRead() =>
      unawaited(_services.settings.set(Settings.hideReadStories, false));

  void _openSearch() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SearchPage(services: _services),
        ),
      ),
    );
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
        final tabs = _tabsFor(enabled.data);
        _followTabs(tabs);
        final kind = _tab.kind;
        return StreamBuilder<List<LocalDay>>(
          stream: kind == null ? null : _days[kind],
          initialData: const <LocalDay>[],
          builder: (context, snapshot) =>
              _scaffold(tabs, snapshot.data ?? const <LocalDay>[]),
        );
      },
    );
  }

  Widget _scaffold(List<FeedTab> tabs, List<LocalDay> stored) {
    final today = localDayOf(DateTime.now());
    final days = daysInWindow(stored, today, _keepDays);
    final day = shownDay(days, _picked, today);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const HackerNewsTitle(),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          if (_tab.kind != null)
            DayMenu(
              days: days,
              selected: day,
              today: today,
              onSelected: (d) => setState(() => _picked = d),
            ),
          StreamBuilder<SyncProgress?>(
            stream: _progress,
            builder: (context, progress) => progress.data == null
                ? IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => unawaited(_refresh()),
                  )
                : IconButton(
                    tooltip: 'Stop updating',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => unawaited(_services.sync.stop()),
                  ),
          ),
          PopupMenuButton<void>(
            itemBuilder: (_) => [
              PopupMenuItem<void>(
                onTap: () => unawaited(
                  _services.settings.set(
                    Settings.hideReadStories,
                    !(_hideRead ?? false),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(child: Text('Hide read stories')),
                    IgnorePointer(
                      child: Checkbox(
                        value: _hideRead ?? false,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<void>(
                onTap: () => openOverview(context),
                child: const Text('Overview'),
              ),
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
            selected: _tab,
            tabs: tabs,
            onSelected: _select,
            status: SyncStatusLine(services: _services),
          ),
          SyncBar(services: _services),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              physics: const BouncingScrollPhysics(),
              itemCount: tabs.length,
              onPageChanged: _pageChanged,
              itemBuilder: (context, index) => _hideRead == null
                  ? const SizedBox.shrink()
                  : _FeedPane(
                      services: _services,
                      kind: tabs[index].kind,
                      days: _days[tabs[index].kind],
                      picked: _picked,
                      keepDays: _keepDays,
                      hideRead: _hideRead ?? false,
                      onRefresh: _refresh,
                      onShowRead: _showRead,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<FeedTab> _tabsFor(Set<FeedKind>? enabled) {
    final kinds = enabled == null || enabled.isEmpty
        ? FeedKind.values
        : [
            for (final kind in FeedKind.values)
              if (enabled.contains(kind) || FeedTab.of(kind) == _tab) kind,
          ];
    return [for (final kind in kinds) FeedTab.of(kind), FeedTab.saved];
  }
}

class _FeedPane extends StatelessWidget {
  const _FeedPane({
    required this.services,
    required this.kind,
    required this.days,
    required this.picked,
    required this.keepDays,
    required this.hideRead,
    required this.onRefresh,
    required this.onShowRead,
  });

  final AppServices services;
  final FeedKind? kind;
  final Stream<List<LocalDay>>? days;
  final LocalDay? picked;
  final int keepDays;
  final bool hideRead;
  final Future<void> Function() onRefresh;
  final VoidCallback onShowRead;

  @override
  Widget build(BuildContext context) {
    final days = this.days;
    if (days == null) {
      return FeedList(
        services: services,
        kind: null,
        day: null,
        storeEmpty: false,
        hideRead: false,
        onRefresh: onRefresh,
        onShowRead: onShowRead,
      );
    }
    return StreamBuilder<List<LocalDay>>(
      stream: days,
      builder: (context, snapshot) {
        final stored = snapshot.data ?? const <LocalDay>[];
        final today = localDayOf(DateTime.now());
        return FeedList(
          services: services,
          kind: kind,
          day: shownDay(daysInWindow(stored, today, keepDays), picked, today),
          storeEmpty: stored.isEmpty,
          hideRead: hideRead,
          onRefresh: onRefresh,
          onShowRead: onShowRead,
        );
      },
    );
  }
}
