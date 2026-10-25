import 'package:flutter/material.dart';
import 'models.dart';

String two(int n) => n.toString().padLeft(2, '0');
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
String slotKey(DateTime at) => '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
(int, int) hm(String s) {
  final p = s.split(':');
  return (int.parse(p[0]), int.parse(p[1]));
}

/// Logical today starting at dayStart
DateTime logicalToday(Prefs p) => DateUtils.dateOnly(DateTime.now().subtract(Duration(minutes: p.dayStart)));

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return 'th';
  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

String scheduleText(Therapy t) {
  final n = t.times.length;
  switch (t.kind) {
    case 'weekly':
      final d = [...t.weekdays]..sort();
      return 'Every ${d.map((x) => _dayNames[x - 1]).join(', ')}';
    case 'monthly':
      return 'Every ${t.monthDay}${_ordinal(t.monthDay)} of month';
    case 'asneeded':
      return 'As needed';
    default:
      if (t.everyDays == 1) return n > 1 ? 'Daily, $n times' : 'Daily';
      return 'Every ${t.everyDays} days';
  }
}

int cycleOf(Therapy t) => switch (t.kind) {
      'weekly' => (7 / (t.weekdays.isEmpty ? 1 : t.weekdays.length)).round().clamp(1, 7),
      'monthly' => 30,
      'asneeded' => 14,
      _ => t.everyDays < 1 ? 1 : t.everyDays,
    };

/// Scheduled times for [t] between [from] and [to] (inclusive).
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

/// status: taken | overdue | late | today | upcoming
class Slot {
  const Slot(this.t, this.at, this.log, this.status);
  final Therapy t;
  final DateTime at;
  final DoseLog? log;
  final String status;
  bool get taken => log != null;
}

List<Slot> buildSlots(List<Therapy> ths, List<DoseLog> logs, Prefs p, {int back = 3, int ahead = 40}) {
  final now = DateTime.now(), today = logicalToday(p);
  final from = DateTime(today.year, today.month, today.day - back);
  final to = DateTime(today.year, today.month, today.day + ahead);
  final out = <Slot>[];
  for (final t in ths) {
    final tl = logs.where((l) => l.therapyId == t.id).toList();
    if (t.rolling && t.kind == 'interval' && t.everyDays > 1) {
      final last = tl.fold<DoseLog?>(null, (a, b) => a == null || b.at.isAfter(a.at) ? b : a);
      final first = last == null ? DateUtils.dateOnly(t.start) : DateTime(last.at.year, last.at.month, last.at.day + t.everyDays);
      if (last != null && sameDay(last.at, today)) out.add(Slot(t, last.at, last, 'taken'));
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
    final legacy = t.times.length <= 1 ? tl.where((l) => l.slot == null).toList() : <DoseLog>[];
    for (final at in occurrences(t, from, to)) {
      final log = byKey[slotKey(at)] ?? legacy.where((l) => sameDay(l.at, at)).firstOrNull;
      final d = DateUtils.dateOnly(at);
      final st = log != null
          ? 'taken'
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
  final parts = [
    if (y > 0) '$y ${y == 1 ? "year" : "years"}',
    if (m > 0) '$m ${m == 1 ? "month" : "months"}',
    if (d > 0 || (y == 0 && m == 0)) '$d ${d == 1 ? "day" : "days"}',
  ];
  return parts.join(' ');
}
