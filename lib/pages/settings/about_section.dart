import 'package:flutter/material.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SettingsSection(
      title: 'About',
      children: [
        ListTile(
          title: Text('Open source licences', style: t.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context),
        ),
        ListTile(
          title: Text('Version', style: t.label),
          trailing: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, info) =>
                Text(info.data?.version ?? '', style: t.label),
          ),
        ),
      ],
    );
  }
}
