import 'package:flutter/material.dart';
import 'l10n.dart';
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

/// "Hari ini" menurut pengaturan awal hari (mis. 04:00: pukul 02:00 masih dihitung kemarin).
DateTime logicalToday(Prefs p) => DateUtils.dateOnly(DateTime.now().subtract(Duration(minutes: p.dayStart)));

const _dayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayNamesId = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String scheduleText(Therapy t) {
  final n = t.times.length;
  final isId = AppLocale.code == 'id';
  final dayNames = isId ? _dayNamesId : _dayNamesEn;
  switch (t.kind) {
    case 'weekly':
      final d = [...t.weekdays]..sort();
      final days = d.map((x) => dayNames[x - 1]).join(', ');
      return isId ? 'Tiap $days' : 'Every $days';
    case 'monthly':
      return isId ? 'Tiap tanggal ${t.monthDay}' : 'Every month day ${t.monthDay}';
    case 'asneeded':
      return isId ? 'Saat perlu' : 'As needed';
    default:
      if (t.everyDays == 1) {
        if (isId) {
          return n > 1 ? 'Setiap hari, $n kali' : 'Setiap hari';
        }
        return n > 1 ? 'Every day, $n times' : 'Every day';
      }
      return isId ? 'Tiap ${t.everyDays} hari' : 'Every ${t.everyDays} days';
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
  final isId = AppLocale.code == 'id';
  final yStr = isId ? '$y tahun' : (y == 1 ? '1 year' : '$y years');
  final mStr = isId ? '$m bulan' : (m == 1 ? '1 month' : '$m months');
  final dStr = isId ? '$d hari' : (d == 1 ? '1 day' : '$d days');
  final parts = [if (y > 0) yStr, if (m > 0) mStr, if (d > 0 || (y == 0 && m == 0)) dStr];
  return parts.join(' ');
}
