import 'package:flutter/material.dart';

String dayLabel(BuildContext context, DateTime day, DateTime today) {
  final gap = DateUtils.dateOnly(today)
      .difference(DateUtils.dateOnly(day))
      .inDays;
  return switch (gap) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => MaterialLocalizations.of(context).formatMediumDate(day),
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

  final List<DateTime> days;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DateTime>(
      tooltip: 'Choose day',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final day in days)
          CheckedPopupMenuItem(
            value: day,
            checked: DateUtils.isSameDay(day, selected),
            child: Text(dayLabel(context, day, today)),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
