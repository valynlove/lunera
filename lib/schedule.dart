import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'models.dart';
import 'l10n.dart';

String two(int n) => n.toString().padLeft(2, '0');
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
String slotKey(DateTime at) => '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
(int, int) hm(String s) {
  final p = s.split(':');
  return (int.parse(p[0]), int.parse(p[1]));
}

/// "Hari ini" menurut pengaturan awal hari (mis. 04:00: pukul 02:00 masih dihitung kemarin).
DateTime logicalToday(Prefs p) => DateUtils.dateOnly(DateTime.now().subtract(Duration(minutes: p.dayStart)));

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String scheduleText(Therapy t) {
  final n = t.times.length;
  switch (t.kind) {
    case 'weekly':
      final d = [...t.weekdays]..sort();
      return tr('Every {0}', [d.map((x) => tr(_dayNames[x - 1])).join(', ')]);
    case 'monthly':
      return tr('Every month on day {0}', [t.monthDay]);
    case 'asneeded':
      return tr('As needed');
    default:
      if (t.everyDays == 1) return n > 1 ? tr('Every day, {0} times', [n]) : tr('Every day');
      return tr('Every {0} {0?day|days}', [t.everyDays]);
  }
}

int cycleOf(Therapy t) => switch (t.kind) {
      'weekly' => (7 / (t.weekdays.isEmpty ? 1 : t.weekdays.length)).round().clamp(1, 7),
      'monthly' => 30,
      'asneeded' => 14,
      _ => t.everyDays < 1 ? 1 : t.everyDays,
    };

/// Waktu jadwal untuk [t] pada tanggal [from] sampai [to] (inklusif).
List<DateTime> occurrences(Therapy t, DateTime from, DateTime to) {
  if (t.asNeeded) return [];
  final out = <DateTime>[];
  final times = [...t.times]..sort();
  final n = daysBetween(from, to);
  for (var i = 0; i <= n; i++) {
    final d = DateTime(from.year, from.month, from.day + i);
    final sinceStart = daysBetween(t.start, d);
    if (sinceStart < 0) continue;
    final monthLen = DateTime(d.year, d.month + 1, 0).day;
    final ok = switch (t.kind) {
      'weekly' => t.weekdays.contains(d.weekday),
      'monthly' => d.day == (t.monthDay < monthLen ? t.monthDay : monthLen),
      _ => sinceStart % (t.everyDays < 1 ? 1 : t.everyDays) == 0,
    };
    if (!ok) continue;
    for (final s in times) {
      final (h, m) = hm(s);
      out.add(DateTime(d.year, d.month, d.day, h, m));
    }
  }
  return out;
}

/// status: taken | skipped | overdue | late | today | upcoming
class Slot {
  const Slot(this.t, this.at, this.log, this.status);
  final Therapy t;
  final DateTime at;
  final DoseLog? log;
  final String status;
  bool get taken => log != null && !log!.skipped;
  bool get skipped => log?.skipped ?? false;
  bool get pending => log == null;
}

List<Slot> buildSlots(List<Therapy> ths, List<DoseLog> logs, Prefs p, {int back = 3, int ahead = 40}) {
  final now = DateTime.now(), today = logicalToday(p);
  final from = DateTime(today.year, today.month, today.day - back);
  final to = DateTime(today.year, today.month, today.day + ahead);
  final out = <Slot>[];
  for (final t in ths) {
    final tl = logs.where((l) => l.therapyId == t.id).toList();
    if (t.rolling && t.kind == 'interval' && t.everyDays > 1) {
      // Jadwal berikutnya = tanggal dosis terakhir + N hari (atau tanggal mulai jika belum ada catatan).
      final last = tl.fold<DoseLog?>(null, (a, b) => a == null || b.at.isAfter(a.at) ? b : a);
      final first = last == null ? DateUtils.dateOnly(t.start) : DateTime(last.at.year, last.at.month, last.at.day + t.everyDays);
      if (last != null && sameDay(last.at, today)) out.add(Slot(t, last.at, last, last.skipped ? 'skipped' : 'taken'));
      final rtimes = [...t.times]..sort();
      for (var k = 0;; k++) {
        final d = DateTime(first.year, first.month, first.day + k * t.everyDays);
        if (d.isAfter(to)) break;
        if (d.isBefore(today) && k > 0) continue;
        for (final s in rtimes) {
          final (h, m) = hm(s);
          final at = DateTime(d.year, d.month, d.day, h, m);
          final st = d.isBefore(today) ? 'overdue' : (d.isAfter(today) ? 'upcoming' : (at.isBefore(now) ? 'late' : 'today'));
          out.add(Slot(t, at, null, st));
        }
      }
      continue;
    }
    final byKey = {for (final l in tl) if (l.slot != null) l.slot!: l};
    // Catatan lama tanpa jadwal: cocokkan per hari (hanya jika jadwalnya sekali sehari).
    final legacy = t.times.length <= 1 ? tl.where((l) => l.slot == null).toList() : <DoseLog>[];
    for (final at in occurrences(t, from, to)) {
      final log = byKey[slotKey(at)] ?? legacy.where((l) => sameDay(l.at, at)).firstOrNull;
      final d = DateUtils.dateOnly(at);
      final st = log != null
          ? (log.skipped ? 'skipped' : 'taken')
          : d.isBefore(today)
              ? 'overdue'
              : d.isAfter(today)
                  ? 'upcoming'
                  : (at.isBefore(now) ? 'late' : 'today');
      out.add(Slot(t, at, log, st));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

/// Lokasi berikutnya yang disarankan (bergantian sesuai daftar lokasi).
String suggestPlace(Prefs p, List<DoseLog> logsDesc, String therapyId) {
  if (p.places.isEmpty) return '';
  final last = logsDesc.where((l) => l.therapyId == therapyId && l.places.isNotEmpty).firstOrNull;
  if (last == null) return p.places.first;
  final i = p.places.indexOf(last.places.first);
  return p.places[(i + 1) % p.places.length];
}

String hrtDuration(DateTime from, DateTime to) {
  var y = to.year - from.year, m = to.month - from.month, d = to.day - from.day;
  if (d < 0) {
    m -= 1;
    d += DateTime(to.year, to.month, 0).day;
  }
  if (m < 0) {
    y -= 1;
    m += 12;
  }
  final parts = [if (y > 0) tr('{0} {0?year|years}', [y]), if (m > 0) tr('{0} {0?month|months}', [m]), if (d > 0 || (y == 0 && m == 0)) tr('{0} {0?day|days}', [d])];
  return parts.join(' ');
}

/// Urgency tier for medication and equipment reorder planning.
enum RefillUrgency {
  depleted,
  critical,
  reorderSoon,
  healthy,
}

/// Estimated remaining supply horizon based on linked active therapy cadence.
class SupplyForecast {
  const SupplyForecast({
    required this.daysLeft,
    required this.runOutDate,
    required this.reorderDate,
    required this.urgency,
    this.bufferDays = 7,
  });

  final int daysLeft;
  final DateTime runOutDate;
  final DateTime reorderDate;
  final RefillUrgency urgency;
  final int bufferDays;

  bool get needsReorder =>
      urgency == RefillUrgency.critical ||
      urgency == RefillUrgency.reorderSoon ||
      urgency == RefillUrgency.depleted;
}

SupplyForecast? estimateSupplyForecast(
  Supply s,
  List<Therapy> therapies, {
  DateTime? now,
  int bufferDays = 7,
}) {
  if (s.perDose <= 0) return null;

  double cadencePerDay(Therapy t) =>
      t.daily ? math.max(1, t.times.length).toDouble() : 1.0 / math.max(1, cycleOf(t));

  final active = therapies.where((t) => !t.asNeeded).toList();
  double dosesPerDay = 0;

  if (!s.generic) {
    var matched = active.where((t) => t.supplyId == s.id).toList();
    if (matched.isEmpty) {
      final needle = s.name.trim().toLowerCase();
      if (needle.isNotEmpty) {
        matched = active
            .where((t) =>
                t.name.trim().toLowerCase().contains(needle) ||
                needle.contains(t.name.trim().toLowerCase()))
            .toList();
      }
    }
    if (matched.isEmpty && active.length == 1) {
      matched = active;
    }
    for (final t in matched) {
      dosesPerDay += cadencePerDay(t);
    }
  } else {
    for (final t in active.where((t) => t.route == 'inj')) {
      dosesPerDay += cadencePerDay(t);
    }
  }

  if (dosesPerDay <= 0) return null;
  final base = now ?? DateTime.now();

  if (s.qty <= 0) {
    return SupplyForecast(
      daysLeft: 0,
      runOutDate: DateTime(base.year, base.month, base.day),
      reorderDate: DateTime(base.year, base.month, base.day),
      urgency: RefillUrgency.depleted,
      bufferDays: bufferDays,
    );
  }

  final remainingDoses = s.qty / s.perDose;
  final daysLeft = (remainingDoses / dosesPerDay).floor();
  final runOutDate = DateTime(base.year, base.month, base.day + daysLeft);

  final reorderOffset = math.max(0, daysLeft - bufferDays);
  final reorderDate = DateTime(base.year, base.month, base.day + reorderOffset);

  final RefillUrgency urgency;
  if (daysLeft <= 0) {
    urgency = RefillUrgency.depleted;
  } else if (daysLeft <= bufferDays) {
    urgency = RefillUrgency.critical;
  } else if (daysLeft <= bufferDays + 7) {
    urgency = RefillUrgency.reorderSoon;
  } else {
    urgency = RefillUrgency.healthy;
  }

  return SupplyForecast(
    daysLeft: daysLeft,
    runOutDate: runOutDate,
    reorderDate: reorderDate,
    urgency: urgency,
    bufferDays: bufferDays,
  );
}

/// Guidance for optimal trough blood-draw timing and 90-day routine bloodwork.
class TroughLabReminder {
  const TroughLabReminder({
    this.nextTroughSlot,
    this.daysSinceLastLab,
    this.nextRoutineLabDate,
    required this.isDue,
  });

  final Slot? nextTroughSlot;
  final int? daysSinceLastLab;
  final DateTime? nextRoutineLabDate;
  final bool isDue;
}

TroughLabReminder? computeTroughLabReminder(
  List<Therapy> therapies,
  List<DoseLog> logs,
  List<Lab> labs,
  Prefs prefs, {
  DateTime? now,
}) {
  if (therapies.isEmpty) return null;
  final refNow = now ?? DateTime.now();

  final scheduled = therapies.where((t) => !t.asNeeded).toList();
  final upcoming = scheduled.isEmpty
      ? <Slot>[]
      : [
          for (final s in buildSlots(scheduled, logs, prefs, back: 0, ahead: 35))
            if (s.pending && s.at.isAfter(refNow)) s,
        ]
    ..sort((a, b) => a.at.compareTo(b.at));

  final sortedLabs = [...labs]..sort((a, b) => b.at.compareTo(a.at));
  final latestLab = sortedLabs.firstOrNull;
  if (latestLab == null) {
    return TroughLabReminder(
      nextTroughSlot: upcoming.firstOrNull,
      daysSinceLastLab: null,
      nextRoutineLabDate: null,
      isDue: true,
    );
  }

  final daysSince = math.max(0, daysBetween(latestLab.at, refNow));
  final nextRoutine = DateTime(
    latestLab.at.year,
    latestLab.at.month,
    latestLab.at.day + 90,
  );
  return TroughLabReminder(
    nextTroughSlot: upcoming.firstOrNull,
    daysSinceLastLab: daysSince,
    nextRoutineLabDate: nextRoutine,
    isDue: daysSince >= 90,
  );
}

/// Represents a specific trough bloodwork window for an upcoming cyclical or injection dose.
class TroughWindow {
  const TroughWindow({
    required this.slot,
    required this.targetDate,
    required this.therapy,
  });

  final Slot slot;
  final DateTime targetDate;
  final Therapy therapy;
}

/// Identifies whether a slot corresponds to a cyclical or injection therapy where
/// a trough blood-draw (prior to taking the next dose) is clinically recommended.
bool isTroughEligibleSlot(Slot s) {
  if (s.t.asNeeded) return false;
  return s.pending && (s.t.route == 'inj' || cycleOf(s.t) > 1);
}

/// Returns all trough windows within the given slots list.
List<TroughWindow> computeTroughWindows(List<Slot> slots) {
  final out = <TroughWindow>[];
  for (final s in slots) {
    if (isTroughEligibleSlot(s)) {
      out.add(TroughWindow(
        slot: s,
        targetDate: DateUtils.dateOnly(s.at),
        therapy: s.t,
      ));
    }
  }
  return out;
}

/// Returns the full list of grid days (including padded days) for a given month.
List<DateTime> buildMonthGridDays(DateTime monthDate) {
  final first = DateTime(monthDate.year, monthDate.month, 1);
  final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
  final startOffset = first.weekday - 1; // 1 = Monday
  final startDate = first.subtract(Duration(days: startOffset));

  final totalDays = startOffset + daysInMonth;
  final trailingPadding = (7 - (totalDays % 7)) % 7;
  final cellCount = totalDays + trailingPadding;

  return [
    for (int i = 0; i < cellCount; i++)
      DateTime(startDate.year, startDate.month, startDate.day + i),
  ];
}
