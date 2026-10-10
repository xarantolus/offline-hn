import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';
import 'package:offline_hn/debug/mock_data.dart';

enum EntryAction {
  openSaved('Open saved copy', Icons.offline_pin_outlined),
  openLive('Open live site', Icons.open_in_new),
  save('Save', Icons.bookmark_border),
  share('Share', Icons.ios_share);

  const EntryAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

@immutable
class SettingsStyle {
  const SettingsStyle({
    this.density = VisualDensity.standard,
    this.usageBarHeight = 8,
    this.usageBarRadius = 4,
    this.sectionGap = Spacing.xl,
  });

  final VisualDensity density;
  final double usageBarHeight;
  final double usageBarRadius;
  final double sectionGap;
}

/// One visual direction. Pages own the state and layout of each screen; a kit
/// supplies the pieces that make it look the way it does.
abstract class LookKit {
  const LookKit();

  String get name;
  String get summary;

  LookPalette paletteFor(Brightness brightness);

  EdgeInsets get feedPadding => EdgeInsets.zero;
  EdgeInsets get threadPadding => EdgeInsets.zero;
  double get progressHeight => 2;
  SettingsStyle get settingsStyle => const SettingsStyle();

  Widget feedHeader(
    LookPalette p,
    FeedKind selected,
    ValueChanged<FeedKind> onSelected,
    String status,
  );

  Widget storyRow(LookPalette p, MockStory story, int position);

  Widget feedSeparator(LookPalette p);

  Widget threadHeader(LookPalette p, MockThread thread);

  Widget commentRow(
    LookPalette p,
    VisibleComment item,
    double textSize,
    VoidCallback onToggle,
  );

  Widget threadSeparator(LookPalette p);

  Widget entryBody(
    LookPalette p,
    MockStory story,
    ValueChanged<EntryAction> onAction,
  );

  Widget settingsSection(LookPalette p, String title, List<Widget> children);
}
