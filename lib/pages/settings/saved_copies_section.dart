import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/viewer_kind.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/ui/commit_slider.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

const _gigabyte = 1024 * 1024 * 1024;
const _minBudget = 0.5;
const _maxBudget = 4.0;

class SavedCopiesSection extends StatefulWidget {
  const SavedCopiesSection({
    super.key,
    required this.store,
    required this.pages,
    required this.viewer,
    required this.budgetBytes,
  });

  final SettingsStore store;
  final PageRepository pages;
  final ViewerKind viewer;
  final int budgetBytes;

  @override
  State<SavedCopiesSection> createState() => _SavedCopiesSectionState();
}

class _SavedCopiesSectionState extends State<SavedCopiesSection> {
  late final Stream<PageUsage> _usage = widget.pages.watchUsage();
  double? _preview;

  double get _budgetGb => _preview ?? widget.budgetBytes / _gigabyte;

  @override
  void didUpdateWidget(SavedCopiesSection old) {
    super.didUpdateWidget(old);
    if (old.budgetBytes != widget.budgetBytes) _preview = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SettingsSection(
      title: 'Saved copies',
      children: [
        ListTile(
          title: Text('Open with', style: t.label),
          subtitle: Text(
            'The browser shows the page as it was saved, with its own '
            'controls',
            style: t.hint,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            0,
            Spacing.gutter,
            Spacing.lg,
          ),
          child: SegmentedButton<ViewerKind>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ViewerKind.customTab,
                label: Text('Custom tab'),
              ),
              ButtonSegment(
                value: ViewerKind.inApp,
                label: Text('In-app viewer'),
              ),
            ],
            selected: {widget.viewer},
            onSelectionChanged: (s) =>
                widget.store.set(Settings.viewer, s.single),
          ),
        ),
        ListTile(
          title: Text('Storage budget', style: t.label),
          trailing: Text('${_budgetGb.toStringAsFixed(1)} GB', style: t.label),
        ),
        CommitSlider(
          value: widget.budgetBytes / _gigabyte,
          min: _minBudget,
          max: _maxBudget,
          divisions: ((_maxBudget - _minBudget) / 0.5).round(),
          label: (v) => '${v.toStringAsFixed(1)} GB',
          onChanged: (v) => setState(() => _preview = v),
          onCommit: (v) => widget.store.set(
            Settings.pageBudgetBytes,
            (v * _gigabyte).round(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            Spacing.xs,
            Spacing.gutter,
            Spacing.lg,
          ),
          child: StreamBuilder<PageUsage>(
            stream: _usage,
            builder: (context, snapshot) => UsageBar(
              used: snapshot.data?.bytes ?? 0,
              count: snapshot.data?.count ?? 0,
              budget: _budgetGb * _gigabyte,
            ),
          ),
        ),
      ],
    );
  }
}

class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.used,
    required this.count,
    required this.budget,
  });

  final int used;
  final int count;
  final double budget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (used / budget).clamp(0.0, 1.0),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '${formatSize(used)} of ${formatSize(budget.round())} used · '
          '${pluralize(count, 'saved copy', 'saved copies')}',
          style: context.tokens.hint,
        ),
      ],
    );
  }
}
