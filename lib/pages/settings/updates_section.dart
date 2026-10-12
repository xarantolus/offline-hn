import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/sync/sync_controller.dart';
import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/pages/settings/last_update_tile.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

const _intervals = <int?>[null, 1, 2, 4, 6, 12];

class UpdatesSection extends StatelessWidget {
  const UpdatesSection({
    super.key,
    required this.store,
    required this.settings,
    required this.services,
  });

  final AppServices services;
  final SettingsStore store;
  final AppSettings settings;

  Future<void> _pickTime(BuildContext context) async {
    final current = settings.dailyTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    await store.set(Settings.dailyTime, DailyTime(picked.hour, picked.minute));
  }

  Future<void> _updateAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await services.sync.requestSync(SyncTrigger.manual);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result == SyncRequest.noConnection
                ? 'No connection. Nothing to fetch.'
                : 'Updating in the background',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final time = settings.dailyTime;
    final clock = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return SettingsSection(
      title: 'Updates',
      children: [
        LastUpdateTile(services: services, settings: settings),
        ListTile(
          title: Text('Update everything now', style: t.label),
          subtitle: Text(
            'Stories, comments and saved copies, as in the daily update',
            style: t.hint,
          ),
          trailing: const Icon(Icons.refresh),
          onTap: () => unawaited(_updateAll(context)),
        ),
        ListTile(
          title: Text('Refresh each day at', style: t.label),
          subtitle: Text(
            'Stories and comments are fetched in the background',
            style: t.hint,
          ),
          trailing: Text(clock, style: t.label),
          onTap: () => _pickTime(context),
        ),
        ListTile(
          title: Text('Also refresh every', style: t.label),
          subtitle: Text(
            'Keeps comment threads current during the day',
            style: t.hint,
          ),
          trailing: DropdownButton<int?>(
            value: settings.intervalHours,
            underline: const SizedBox.shrink(),
            style: t.label,
            items: [
              for (final hours in _intervals)
                DropdownMenuItem(
                  value: hours,
                  child: Text(hours == null ? 'Off' : '$hours h'),
                ),
            ],
            onChanged: (hours) => store.set(Settings.intervalHours, hours),
          ),
        ),
        SwitchListTile(
          title: Text('Wi-Fi only', style: t.label),
          subtitle: Text('Never use mobile data to refresh', style: t.hint),
          value: settings.wifiOnly,
          onChanged: (v) => store.set(Settings.wifiOnly, v),
        ),
        if (!settings.wifiOnly)
          SwitchListTile(
            title: Text('Saved copies on mobile data', style: t.label),
            subtitle: Text(
              'Otherwise only stories and comments, pages wait for Wi-Fi',
              style: t.hint,
            ),
            value: settings.pagesOnMobile,
            onChanged: (v) => store.set(Settings.pagesOnMobile, v),
          ),
      ],
    );
  }
}
