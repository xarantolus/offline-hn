import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/keep_window.dart';
import 'package:offline_hn/data/policy/overview_text.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

String keepOptionLabel(int days) {
  final text = keepWindowText(days);
  return text[0].toUpperCase() + text.substring(1);
}

class KeepSection extends StatelessWidget {
  const KeepSection({super.key, required this.store, required this.days});

  final SettingsStore store;
  final int days;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SettingsSection(
      title: 'Keeping stories',
      children: [
        ListTile(
          title: Text('Keep stories from', style: t.label),
          subtitle: Text(
            'Older stories, comments and saved pages are removed on the next '
            'update. Bookmarks and stories you opened recently stay.',
            style: t.hint,
          ),
          trailing: DropdownButton<int>(
            value: days,
            underline: const SizedBox.shrink(),
            items: [
              for (var n = minKeepDays; n <= maxKeepDays; n++)
                DropdownMenuItem(value: n, child: Text(keepOptionLabel(n))),
            ],
            onChanged: (n) {
              if (n != null) store.set(Settings.keepDays, n);
            },
          ),
        ),
      ],
    );
  }
}
