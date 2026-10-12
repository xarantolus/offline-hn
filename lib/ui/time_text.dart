import 'package:flutter/material.dart';
import 'package:offline_hn/data/policy/run_history.dart';

String clockText(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(at.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

String dateText(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatShortMonthDay(at.toLocal());

/// "Today 05:03", in the phone's own clock and calendar.
String whenText(BuildContext context, DateTime at, {DateTime? now}) =>
    whenLabel(
      at: at,
      now: now ?? DateTime.now(),
      clock: clockText(context, at),
      date: (day) => dateText(context, day),
    );
