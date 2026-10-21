import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/pages/settings/about_section.dart';
import 'package:offline_hn/pages/settings/cleanup_section.dart';
import 'package:offline_hn/pages/settings/feeds_section.dart';
import 'package:offline_hn/pages/settings/keep_section.dart';
import 'package:offline_hn/pages/settings/reading_section.dart';
import 'package:offline_hn/pages/settings/saved_copies_section.dart';
import 'package:offline_hn/pages/settings/updates_section.dart';
import 'package:offline_hn/ui/tokens.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppServices _services = AppServicesScope.of(context);
  late final Stream<AppSettings> _settings = _services.settings.watch();

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Spacing.xl);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<AppSettings>(
        stream: _settings,
        builder: (context, snapshot) {
          final settings = snapshot.data;
          if (settings == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: Spacing.lg,
              bottom: MediaQuery.viewPaddingOf(context).bottom + Spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReadingSection(
                  store: _services.settings,
                  textScale: settings.commentTextScale,
                  order: settings.commentOrder,
                ),
                gap,
                UpdatesSection(
                  services: _services,
                  store: _services.settings,
                  settings: settings,
                ),
                gap,
                FeedsSection(
                  store: _services.settings,
                  enabled: settings.enabledFeeds,
                ),
                gap,
                KeepSection(store: _services.settings, days: settings.keepDays),
                gap,
                SavedCopiesSection(
                  store: _services.settings,
                  pages: _services.pages,
                  viewer: settings.viewer,
                  budgetBytes: settings.pageBudgetBytes,
                ),
                gap,
                CleanupSection(services: _services, settings: settings),
                gap,
                const AboutSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}
