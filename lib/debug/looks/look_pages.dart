import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/look_kit.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';
import 'package:offline_hn/debug/mock_data.dart';

LookPalette _palette(BuildContext context, LookKit kit) =>
    kit.paletteFor(Theme.of(context).brightness);

double _bottomInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom + Spacing.lg;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, required this.kit});

  final LookKit kit;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  FeedKind _kind = FeedKind.top;
  bool _refreshing = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleStop(const Duration(seconds: 45));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleStop(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, () {
      if (mounted) setState(() => _refreshing = false);
    });
  }

  void _refresh() {
    setState(() => _refreshing = true);
    _scheduleStop(const Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    final kit = widget.kit;
    final p = _palette(context, kit);
    final stories = storiesFor(_kind);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: const Text('Offline HN'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          kit.feedHeader(
            p,
            _kind,
            (k) => setState(() => _kind = k),
            'Updated $mockUpdatedAt · $mockConnection',
          ),
          SizedBox(
            height: kit.progressHeight,
            child: _refreshing
                ? LinearProgressIndicator(
                    minHeight: kit.progressHeight,
                    color: p.accent,
                    backgroundColor: p.hairline,
                  )
                : null,
          ),
          Expanded(
            child: ListView.separated(
              key: PageStorageKey<FeedKind>(_kind),
              padding: kit.feedPadding.copyWith(
                bottom: kit.feedPadding.bottom + _bottomInset(context),
              ),
              itemCount: stories.length,
              separatorBuilder: (_, _) => kit.feedSeparator(p),
              itemBuilder: (_, i) => kit.storyRow(p, stories[i], i + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.kit, required this.thread});

  final LookKit kit;
  final MockThread thread;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  late final Set<int> _collapsed = widget.thread.initiallyCollapsed;

  void _toggle(int id) {
    setState(() {
      if (!_collapsed.remove(id)) _collapsed.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kit = widget.kit;
    final p = _palette(context, kit);
    final items = widget.thread.visible(_collapsed);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(title: const Text('Comments')),
      body: ListView.separated(
        padding: kit.threadPadding.copyWith(
          bottom: kit.threadPadding.bottom + _bottomInset(context),
        ),
        itemCount: items.length + 1,
        separatorBuilder: (_, i) =>
            i == 0 ? const SizedBox.shrink() : kit.threadSeparator(p),
        itemBuilder: (_, i) {
          if (i == 0) return kit.threadHeader(p, widget.thread);
          final item = items[i - 1];
          return kit.commentRow(p, item, 15, () => _toggle(item.comment.id));
        },
      ),
    );
  }
}

class EntryPage extends StatelessWidget {
  const EntryPage({super.key, required this.kit, required this.story});

  final LookKit kit;
  final MockStory story;

  void _onAction(BuildContext context, EntryAction action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(action.label)));
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette(context, kit);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(title: const Text('Story')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: _bottomInset(context)),
        child: kit.entryBody(p, story, (a) => _onAction(context, a)),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.kit});

  final LookKit kit;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _textSize = 15;
  TimeOfDay _schedule = const TimeOfDay(hour: 6, minute: 0);
  bool _wifiOnly = true;
  double _budgetGb = 2;
  final Set<FeedKind> _feeds = {FeedKind.top, FeedKind.ask};

  static const _usedGb = 1.3;

  static const _preview = MockComment(
    id: -1,
    author: 'pgrunwald',
    age: Duration(minutes: 22),
    depth: 0,
    blocks: [
      Paragraph(
        'Nice write-up. The retry section is the best part, and the '
        'backoff reference is worth a read: https://example.org/backoff',
      ),
    ],
  );

  Future<void> _pickSchedule() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _schedule,
    );
    if (!mounted || picked == null) return;
    setState(() => _schedule = picked);
  }

  @override
  Widget build(BuildContext context) {
    final kit = widget.kit;
    final p = _palette(context, kit);
    final style = kit.settingsStyle;
    final theme = Theme.of(context);
    final label = theme.textTheme.bodyLarge!.copyWith(color: p.text);
    final hint = theme.textTheme.bodySmall!.copyWith(
      color: p.muted,
      fontSize: 12.5,
    );
    final fraction = (_usedGb / _budgetGb).clamp(0.0, 1.0);

    Widget tile(
      String title,
      String? subtitle,
      Widget trailing, {
      VoidCallback? onTap,
    }) {
      return ListTile(
        visualDensity: style.density,
        title: Text(title, style: label),
        subtitle: subtitle == null ? null : Text(subtitle, style: hint),
        trailing: trailing,
        onTap: onTap,
      );
    }

    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: Spacing.lg,
          bottom: _bottomInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            kit.settingsSection(p, 'Reading', [
              tile(
                'Comment text size',
                null,
                Text('${_textSize.round()} pt', style: label),
              ),
              Slider(
                value: _textSize,
                min: 12,
                max: 22,
                divisions: 10,
                label: '${_textSize.round()}',
                onChanged: (v) => setState(() => _textSize = v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.xs,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: kit.commentRow(
                  p,
                  const VisibleComment(
                    comment: _preview,
                    collapsed: false,
                    hiddenCount: 0,
                    hasChildren: false,
                  ),
                  _textSize,
                  () {},
                ),
              ),
            ]),
            SizedBox(height: style.sectionGap),
            kit.settingsSection(p, 'Updates', [
              tile(
                'Refresh each day at',
                'Stories and comments are fetched in the background',
                Text(_schedule.format(context), style: label),
                onTap: _pickSchedule,
              ),
              SwitchListTile(
                visualDensity: style.density,
                title: Text('Wi-Fi only', style: label),
                subtitle: Text('Never use mobile data to refresh', style: hint),
                value: _wifiOnly,
                onChanged: (v) => setState(() => _wifiOnly = v),
              ),
            ]),
            SizedBox(height: style.sectionGap),
            kit.settingsSection(p, 'Feeds', [
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final f in FeedKind.values)
                      FilterChip(
                        label: Text(
                          f.name[0].toUpperCase() + f.name.substring(1),
                        ),
                        selected: _feeds.contains(f),
                        onSelected: (on) => setState(() {
                          on ? _feeds.add(f) : _feeds.remove(f);
                        }),
                      ),
                  ],
                ),
              ),
            ]),
            SizedBox(height: style.sectionGap),
            kit.settingsSection(p, 'Storage', [
              tile(
                'Storage budget',
                null,
                Text('${_budgetGb.toStringAsFixed(1)} GB', style: label),
              ),
              Slider(
                value: _budgetGb,
                min: 0.5,
                max: 4,
                divisions: 7,
                label: '${_budgetGb.toStringAsFixed(1)} GB',
                onChanged: (v) => setState(() => _budgetGb = v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.xs,
                  Spacing.lg,
                  Spacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(style.usageBarRadius),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: style.usageBarHeight,
                        color: p.accent,
                        backgroundColor: p.hairline,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      '${_usedGb.toStringAsFixed(1)} GB of '
                      '${_budgetGb.toStringAsFixed(1)} GB used · 118 saved copies',
                      style: hint,
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
