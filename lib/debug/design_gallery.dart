import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/all_looks.dart';
import 'package:offline_hn/debug/looks/look_kit.dart';
import 'package:offline_hn/debug/looks/look_pages.dart';
import 'package:offline_hn/debug/mock_data.dart';

class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design gallery')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          for (final kit in allLooks)
            Card(
              child: ListTile(
                title: Text(kit.name),
                subtitle: Text(kit.summary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => LookMenu(kit: kit)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LookMenu extends StatelessWidget {
  const LookMenu({super.key, required this.kit});

  final LookKit kit;

  void _open(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <(String, WidgetBuilder)>[
      ('Feed', (_) => FeedPage(kit: kit)),
      ('Comment thread', (_) => ThreadPage(kit: kit, thread: mockThread)),
      (
        'Comment thread, short',
        (_) => ThreadPage(kit: kit, thread: mockShortThread),
      ),
      ('Story entry', (_) => EntryPage(kit: kit, story: mockThreadStory)),
      ('Settings', (_) => SettingsPage(kit: kit)),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(kit.name)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          for (final (label, builder) in screens)
            ListTile(
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, builder),
            ),
        ],
      ),
    );
  }
}
