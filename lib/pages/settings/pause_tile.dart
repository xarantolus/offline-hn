import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/update_pause.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/ui/tokens.dart';

enum _Choice { untilDate, indefinitely, resume }

/// Holds back the daily, periodic and on-open updates. The buttons that
/// update on request keep working.
class PauseTile extends StatelessWidget {
  const PauseTile({super.key, required this.store, required this.settings});

  final SettingsStore store;
  final AppSettings settings;

  Future<void> _choose(BuildContext context, {required bool paused}) async {
    final choice = await showDialog<_Choice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pause automatic updates'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _Choice.untilDate),
            child: const Text('Until a date…'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _Choice.indefinitely),
            child: const Text('Until I turn them back on'),
          ),
          if (paused)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, _Choice.resume),
              child: const Text('Turn them back on now'),
            ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _Choice.untilDate:
        await _pickDate(context);
      case _Choice.indefinitely:
        await store.set(Settings.updatePause, const UpdatePause.indefinitely());
      case _Choice.resume:
        await store.reset(Settings.updatePause);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final tomorrow = localDayOf(DateTime.now()).next().asUtcMidnight;
    final first = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final resumeOn = settings.updatePause?.resumeOn;
    final current = resumeOn == null
        ? null
        : DateTime(resumeOn.year, resumeOn.month, resumeOn.day);
    final picked = await showDatePicker(
      context: context,
      helpText: 'Start updating again on',
      firstDate: first,
      lastDate: first.add(const Duration(days: 366)),
      initialDate: current != null && !current.isBefore(first)
          ? current
          : first.add(const Duration(days: 6)),
    );
    if (picked == null) return;
    await store.set(
      Settings.updatePause,
      UpdatePause.until(LocalDay(picked.year, picked.month, picked.day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pause = settings.updatePause;
    final paused = automaticUpdatesPaused(pause, DateTime.now());
    final resumeOn = pause?.resumeOn;
    final String state;
    final String hint;
    if (!paused) {
      state = 'Off';
      hint = 'Stop the daily and regular updates for a while';
    } else if (resumeOn == null) {
      state = 'Paused';
      hint = 'Until you turn them back on. Refreshing by hand still works';
    } else {
      final day = MaterialLocalizations.of(
        context,
      ).formatMediumDate(DateTime(resumeOn.year, resumeOn.month, resumeOn.day));
      state = 'Paused';
      hint = 'They start again on $day. Refreshing by hand still works';
    }
    return ListTile(
      title: Text('Pause automatic updates', style: t.label),
      subtitle: Text(hint, style: t.hint),
      trailing: Text(state, style: t.label),
      onTap: () => _choose(context, paused: paused),
    );
  }
}
