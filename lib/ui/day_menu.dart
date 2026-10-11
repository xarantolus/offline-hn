import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/local_day.dart';

String dayLabel(BuildContext context, LocalDay day, LocalDay today) {
  final gap = today.asUtcMidnight.difference(day.asUtcMidnight).inDays;
  return switch (gap) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime(day.year, day.month, day.day)),
  };
}

class DayMenu extends StatelessWidget {
  const DayMenu({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelected,
    required this.today,
  });

  final List<LocalDay> days;
  final LocalDay selected;
  final LocalDay today;
  final ValueChanged<LocalDay> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LocalDay>(
      tooltip: 'Choose day',
      enabled: days.isNotEmpty,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final day in days)
          CheckedPopupMenuItem(
            value: day,
            checked: day == selected,
            child: Text(dayLabel(context, day, today)),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayLabel(context, selected, today),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
