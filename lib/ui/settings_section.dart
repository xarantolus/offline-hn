import 'package:flutter/material.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title),
        const SizedBox(height: Spacing.sm),
        const Hairline(),
        Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        const Hairline(),
      ],
    );
  }
}
