import 'package:flutter/material.dart';
import 'package:offline_hn/debug/pages/settings_page.dart';

class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key});

  void _open(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <(String, WidgetBuilder)>[
      ('Settings', (_) => const MockSettingsPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Design gallery')),
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
