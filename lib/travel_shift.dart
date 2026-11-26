import 'dart:math' as math;

import 'l10n.dart';

/// A single scheduled dose-time step during a timezone travel transition.
class DoseShiftStep {
  const DoseShiftStep({
    required this.stepIndex,
    required this.date,
    required this.timeHHmm,
    required this.remainingShiftMinutes,
    required this.note,
  });

  final int stepIndex;
  final DateTime date;
  final String timeHHmm;
  final int remainingShiftMinutes;
  final String note;
}

String _formatMinutesHHmm(int totalMinutes) {
  final m = ((totalMinutes % 1440) + 1440) % 1440;
  final hh = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Formats a UTC offset in hours (e.g. `7.0` -> `UTC+7`, `5.5` -> `UTC+5:30`).
String formatUtcOffset(double offsetHours) {
  final totalMin = (offsetHours * 60).round();
  if (totalMin == 0) {
    return 'UTC+0';
  }
  final sign = totalMin >= 0 ? '+' : '-';
  final absMin = totalMin.abs();
  final h = absMin ~/ 60;
  final m = absMin % 60;
  if (m == 0) {
    return 'UTC$sign$h';
  }
  return 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
}

/// Computes a gentle, step-by-step schedule to shift a medication time from
/// [originUtcOffsetHours] to [destUtcOffsetHours] without abrupt hormone drops or stacking.
List<DoseShiftStep> computeTimezoneShiftPlan({
  required String baseTimeHHmm,
  required double originUtcOffsetHours,
  required double destUtcOffsetHours,
  required DateTime departureDate,
  double maxShiftHoursPerDay = 2.0,
  int intervalDays = 1,
}) {
  final parts = baseTimeHHmm.split(':');
  final baseHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8).clamp(0, 23) : 8;
  final baseMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0).clamp(0, 59) : 0;
  final baseMinutes = baseHour * 60 + baseMinute;

  var diffMinutes = ((destUtcOffsetHours - originUtcOffsetHours) * 60).round();
  while (diffMinutes > 720) {
    diffMinutes -= 1440;
  }
  while (diffMinutes <= -720) {
    diffMinutes += 1440;
  }

  final stepDayGap = math.max(1, intervalDays);
  final maxStepMin = math.max(30, (maxShiftHoursPerDay * 60).round());
  final startDay = DateTime(departureDate.year, departureDate.month, departureDate.day);

  // Equivalent biological time in destination clock on arrival day.
  var currentClockMin = baseMinutes + diffMinutes;
  var remaining = -diffMinutes;

  final steps = <DoseShiftStep>[
    DoseShiftStep(
      stepIndex: 0,
      date: startDay,
      timeHHmm: _formatMinutesHHmm(currentClockMin),
      remainingShiftMinutes: remaining,
      note: remaining == 0
          ? tr('No timezone shift needed — keep {0} local time.', [baseTimeHHmm])
          : tr('Arrival equivalent of your usual {0} ({1})', [
              baseTimeHHmm,
              formatUtcOffset(originUtcOffsetHours),
            ]),
    ),
  ];

  var idx = 1;
  while (remaining != 0 && idx <= 24) {
    final stepDelta = remaining.abs() <= maxStepMin
        ? remaining
        : (remaining.isNegative ? -maxStepMin : maxStepMin);
    currentClockMin += stepDelta;
    remaining -= stepDelta;
    final date = DateTime(
      startDay.year,
      startDay.month,
      startDay.day + idx * stepDayGap,
    );
    final dirLabel = stepDelta > 0 ? tr('later') : tr('earlier');
    final absDelta = stepDelta.abs();
    final shiftText = absDelta % 60 == 0
        ? tr('{0}h {1}', [absDelta ~/ 60, dirLabel])
        : tr('{0}m {1}', [absDelta, dirLabel]);

    steps.add(
      DoseShiftStep(
        stepIndex: idx,
        date: date,
        timeHHmm: _formatMinutesHHmm(currentClockMin),
        remainingShiftMinutes: remaining,
        note: remaining == 0
            ? tr('Target {0} local time reached ({1})', [baseTimeHHmm, shiftText])
            : tr('Shift {0} toward {1}', [shiftText, baseTimeHHmm]),
      ),
    );
    idx++;
  }

  return steps;
}
