import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/store_overview.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/overview_text.dart';
import 'package:offline_hn/data/policy/run_history.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/pages/overview/run_details_page.dart';
import 'package:offline_hn/pages/overview/run_tiles.dart';
import 'package:offline_hn/pages/settings/saved_copies_section.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/time_text.dart';
import 'package:offline_hn/ui/tokens.dart';

void openOverview(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const OverviewPage()));
}

/// What is stored, how updates are set up, and what the recent ones did.
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late final AppServices _services = AppServicesScope.of(context);
  late final Stream<AppSettings> _settings = _services.settings.watch();
  late final Stream<StoreOverview> _store = _services.overview.watchStore();
  late final Stream<List<RunRecord>> _runs = _services.overview.watchRuns();
  late final Stream<SyncProgress?> _progress = _services.sync.progress;
  late final Stream<DateTime?> _lastSync = _services.sync.lastSync;
  late final Stream<ConnectionKind> _connection = _services.sync.connection;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Spacing.xl);
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: StreamBuilder<AppSettings>(
        stream: _settings,
        builder: (context, settings) {
          final current = settings.data;
          if (current == null) return const SizedBox.shrink();
          return ListView(
            padding: EdgeInsets.only(
              top: Spacing.lg,
              bottom: MediaQuery.viewPaddingOf(context).bottom + Spacing.lg,
            ),
            children: [
              _StoredSection(store: _store, settings: current),
              gap,
              _UpdatesSection(
                settings: current,
                lastSync: _lastSync,
                connection: _connection,
              ),
              gap,
              StreamBuilder<List<RunRecord>>(
                stream: _runs,
                builder: (context, runs) => StreamBuilder<SyncProgress?>(
                  stream: _progress,
                  builder: (context, progress) =>
                      _RunsSections(runs: runs.data, progress: progress.data),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.name, this.value, {this.more});

  final String name;
  final String value;
  final String? more;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListTile(
      title: Text(name, style: t.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.hint.copyWith(fontSize: 14)),
          if (more != null && more!.isNotEmpty) Text(more!, style: t.hint),
        ],
      ),
    );
  }
}

class _StoredSection extends StatelessWidget {
  const _StoredSection({required this.store, required this.settings});

  final Stream<StoreOverview> store;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StoreOverview>(
      stream: store,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return SettingsSection(
          title: 'Stored now',
          children: data == null
              ? const [SizedBox(height: Spacing.xxl)]
              : [
                  _Fact(
                    'Stories',
                    storiesLine(data, (d) => dateText(context, d)),
                    more: feedsLine(data.perFeed),
                  ),
                  _Fact('Comments', threadsLine(data)),
                  _Fact('Article pages', articlesLine(data)),
                  _Fact('Linked pages', linkedLine(data)),
                  _Fact(
                    'Bookmarked',
                    pluralize(data.bookmarked, 'story', 'stories'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.gutter,
                      Spacing.md,
                      Spacing.gutter,
                      Spacing.lg,
                    ),
                    child: UsageBar(
                      used: data.copyBytes,
                      count: data.articles + data.linkedPages,
                      budget: settings.pageBudgetBytes.toDouble(),
                    ),
                  ),
                ],
        );
      },
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection({
    required this.settings,
    required this.lastSync,
    required this.connection,
  });

  final AppSettings settings;
  final Stream<DateTime?> lastSync;
  final Stream<ConnectionKind> connection;

  @override
  Widget build(BuildContext context) {
    final lists = filterListSummary(
      settings.filterListUrls,
      settings.filterListStatus,
    );
    return SettingsSection(
      title: 'Updates',
      children: [
        StreamBuilder<DateTime?>(
          stream: lastSync,
          builder: (context, last) => _Fact(
            'Last successful update',
            last.data == null ? 'None yet' : whenText(context, last.data!),
          ),
        ),
        _Fact(
          'Next update',
          nextUpdateText(
            settings: settings,
            now: DateTime.now(),
            when: (at) => whenText(context, at),
          ),
        ),
        StreamBuilder<ConnectionKind>(
          stream: connection,
          builder: (context, link) => _Fact(
            'Connection',
            link.data == null ? '' : connectionNote(link.data!, settings),
          ),
        ),
        _Fact(
          'Filter lists',
          filterListsLine(lists, (at) => whenText(context, at)),
        ),
      ],
    );
  }
}

class _RunsSections extends StatelessWidget {
  const _RunsSections({required this.runs, required this.progress});

  final List<RunRecord>? runs;
  final SyncProgress? progress;

  @override
  Widget build(BuildContext context) {
    final list = runs;
    if (list == null) return const SizedBox.shrink();
    if (list.isEmpty) {
      return SettingsSection(
        title: 'Last update',
        children: [
          ListTile(title: Text('No updates yet', style: context.tokens.label)),
        ],
      );
    }
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: 'Last update',
          children: [
            RunTile(
              run: list.first,
              progress: progress,
              now: now,
              detailed: true,
              onTap: () => openRunDetails(context, list.first.id),
            ),
          ],
        ),
        if (list.length > 1) ...[
          const SizedBox(height: Spacing.xl),
          SettingsSection(
            title: 'Earlier',
            children: [
              for (final run in list.skip(1))
                RunTile(
                  run: run,
                  progress: progress,
                  now: now,
                  onTap: () => openRunDetails(context, run.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
