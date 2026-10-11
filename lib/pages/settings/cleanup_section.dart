import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/pages/settings/filter_lists_page.dart';
import 'package:offline_hn/pages/settings/update_lists_tile.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

class CleanupSection extends StatelessWidget {
  const CleanupSection({
    super.key,
    required this.services,
    required this.settings,
  });

  final AppServices services;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final store = services.settings;
    return SettingsSection(
      title: 'Page cleanup',
      children: [
        SwitchListTile(
          title: Text('Block ads and trackers', style: t.label),
          subtitle: Text(
            'Applied when a page is saved, using the filter lists',
            style: t.hint,
          ),
          value: settings.adBlocking,
          onChanged: (v) => store.set(Settings.adBlocking, v),
        ),
        SwitchListTile(
          title: Text('Reject cookie popups', style: t.label),
          subtitle: Text(
            'Declines consent banners before the page is saved',
            style: t.hint,
          ),
          value: settings.rejectCookiePopups,
          onChanged: (v) => store.set(Settings.rejectCookiePopups, v),
        ),
        ListTile(
          title: Text('Filter lists', style: t.label),
          subtitle: Text(
            '${settings.filterListUrls.length} configured',
            style: t.hint,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FilterListsPage()),
          ),
        ),
        UpdateListsTile(services: services),
      ],
    );
  }
}
