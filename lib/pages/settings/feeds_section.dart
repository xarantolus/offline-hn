import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

String feedLabel(FeedKind kind) =>
    kind.name[0].toUpperCase() + kind.name.substring(1);

class FeedsSection extends StatelessWidget {
  const FeedsSection({super.key, required this.store, required this.enabled});

  final SettingsStore store;
  final Set<FeedKind> enabled;

  void _toggle(FeedKind kind, bool on) {
    final next = {...enabled};
    if (on) {
      next.add(kind);
    } else if (next.length > 1) {
      next.remove(kind);
    }
    store.set(Settings.enabledFeeds, next);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Feeds',
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.gutter),
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final kind in FeedKind.values)
                FilterChip(
                  label: Text(feedLabel(kind)),
                  selected: enabled.contains(kind),
                  onSelected: (on) => _toggle(kind, on),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
