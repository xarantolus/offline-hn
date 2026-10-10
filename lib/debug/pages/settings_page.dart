import 'package:flutter/material.dart';
import 'package:offline_hn/ui/comment_block.dart';
import 'package:offline_hn/ui/comment_row.dart';
import 'package:offline_hn/ui/feed_switcher.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

class MockSettingsPage extends StatefulWidget {
  const MockSettingsPage({super.key});

  @override
  State<MockSettingsPage> createState() => _MockSettingsPageState();
}

class _MockSettingsPageState extends State<MockSettingsPage> {
  double _textSize = 15;
  TimeOfDay _schedule = const TimeOfDay(hour: 5, minute: 0);
  bool _wifiOnly = true;
  double _budgetGb = 1;
  final Set<FeedKind> _feeds = {FeedKind.top, FeedKind.ask};

  static const _usedGb = 0.7;

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
    final t = context.tokens;
    final clock = MaterialLocalizations.of(context).formatTimeOfDay(
      _schedule,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    const gap = SizedBox(height: Spacing.xl);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: Spacing.lg,
          bottom: MediaQuery.viewPaddingOf(context).bottom + Spacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              title: 'Reading',
              children: [
                ListTile(
                  title: Text('Comment text size', style: t.label),
                  trailing: Text('${_textSize.round()} pt', style: t.label),
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
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: CommentRow(
                    author: 'pgrunwald',
                    age: const Duration(minutes: 22),
                    depth: 0,
                    textSize: _textSize,
                    blocks: const [
                      Paragraph(
                        'Nice write-up. The retry section is the best part, '
                        'and the backoff reference is worth a read: '
                        'https://example.org/backoff',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gap,
            SettingsSection(
              title: 'Updates',
              children: [
                ListTile(
                  title: Text('Refresh each day at', style: t.label),
                  subtitle: Text(
                    'Stories and comments are fetched in the background',
                    style: t.hint,
                  ),
                  trailing: Text(clock, style: t.label),
                  onTap: _pickSchedule,
                ),
                SwitchListTile(
                  title: Text('Wi-Fi only', style: t.label),
                  subtitle: Text(
                    'Never use mobile data to refresh',
                    style: t.hint,
                  ),
                  value: _wifiOnly,
                  onChanged: (v) => setState(() => _wifiOnly = v),
                ),
              ],
            ),
            gap,
            SettingsSection(
              title: 'Feeds',
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.gutter),
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
              ],
            ),
            gap,
            SettingsSection(
              title: 'Storage',
              children: [
                ListTile(
                  title: Text('Storage budget', style: t.label),
                  trailing: Text(
                    '${_budgetGb.toStringAsFixed(1)} GB',
                    style: t.label,
                  ),
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
                    Spacing.gutter,
                    Spacing.xs,
                    Spacing.gutter,
                    Spacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_usedGb / _budgetGb).clamp(0.0, 1.0),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '${_usedGb.toStringAsFixed(1)} GB of '
                        '${_budgetGb.toStringAsFixed(1)} GB used · '
                        '118 saved copies',
                        style: t.hint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
