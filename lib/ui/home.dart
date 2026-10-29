import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../sim.dart';
import '../theme.dart';
import 'journal.dart';
import 'sheets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]..sort((a, b) => b.at.compareTo(a.at));
    final slots = buildSlots(ths, logs, prefs);
    final today = logicalToday(prefs);
    final overdue = [for (final s in slots) if (s.status == 'overdue') s];
    final todays = [for (final s in slots) if (sameDay(s.at, today)) s];
    final upcoming = [for (final s in slots) if (s.status == 'upcoming' && !sameDay(s.at, today) && daysBetween(today, s.at) <= 7) s];

    Widget section(String title, List<Slot> xs) => xs.isEmpty
        ? const SizedBox.shrink()
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            gap(10),
            Padding(padding: const EdgeInsets.only(left: 4), child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            gap(8),
            for (final s in xs) SlotTile(s: s, logs: logs, supplies: supplies, prefs: prefs),
          ]);

    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : null;
    final h = DateTime.now().hour;
    final greet = h < 11 ? 'Selamat pagi' : (h < 15 ? 'Selamat siang' : (h < 19 ? 'Selamat sore' : 'Selamat malam'));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greet,', style: Theme.of(context).textTheme.bodyLarge),
            gap(2),
            Text(name ?? appName, style: display(30)),
            gap(4),
            Text(DateFormat('EEEE, d MMMM y', 'id').format(DateTime.now()), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        IconButton.filledTonal(tooltip: 'Tambah terapi', onPressed: () => showSheet(context, TherapySheet(supplies: supplies)), icon: const Icon(Icons.add_rounded)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => ref.read(tabProvider.notifier).state = 4,
          child: CircleAvatar(radius: 22, backgroundColor: C.peony, child: Text((name ?? appName).substring(0, 1).toUpperCase(), style: display(18, color: Colors.white))),
        ),
      ]),
      gap(16),
      AlertsCard(supplies: supplies),
      const MoodQuickCard(),
      if (ths.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(children: [
            Text('Belum ada terapi', style: display(32)),
            gap(10),
            const Text('Tambahkan obat pertamamu untuk mulai menghitung jadwal.'),
            gap(20),
            pillButton('Tambah terapi', () => showSheet(context, TherapySheet(supplies: supplies)), icon: Icons.add_rounded),
          ]),
        )
      else ...[
        for (final t in ths) DoseCard(t: t, slots: slots, logs: logs, supplies: supplies, prefs: prefs),
        WeekCard(ths: ths, logs: logs),
        section('Terlewat', overdue),
        section('Hari ini', todays),
        section('7 hari ke depan', upcoming),
      ],
    ]);
  }
}

class DoseCard extends ConsumerWidget {
  const DoseCard({super.key, required this.t, required this.slots, required this.logs, required this.supplies, required this.prefs});
  final Therapy t;
  final List<Slot> slots;
  final List<DoseLog> logs; // terbaru di depan
  final List<Supply> supplies;
  final Prefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final today = logicalToday(prefs), now = DateTime.now();
    final mine = slots.where((s) => s.t.id == t.id).toList();
    final next = mine.where((s) => s.pending).firstOrNull;
    final last = logs.where((l) => l.therapyId == t.id).firstOrNull;
    final place = suggestPlace(prefs, logs, t.id);
    final idle = fg.withValues(alpha: .14);
    final hhmm = DateFormat('HH:mm');
    CustomPainter painter;
    List<Widget> center;

    if (t.asNeeded) {
      final since = last == null ? 0 : daysBetween(last.at, now);
      painter = DialPainter(14, since.clamp(0, 14), idle);
      center = [
        Text(last == null ? '-' : '$since', style: display(88)),
        gap(6),
        Text(last == null ? 'belum ada catatan' : 'hari sejak dosis terakhir'),
      ];
    } else if (t.daily) {
      final td = [for (final s in mine) if (sameDay(s.at, today)) s];
      final done = td.where((s) => !s.pending).length;
      final nextToday = td.where((s) => s.pending).firstOrNull;
      painter = HourDialPainter({for (final s in td) s.at.hour: s.status}, idle);
      center = td.isEmpty
          ? [Text('Libur', style: display(48))]
          : nextToday == null
              ? [Text('Selesai', style: display(48)), gap(6), Text('$done dari ${td.length} dosis hari ini')]
              : [
                  Text(hhmm.format(nextToday.at), style: display(64, color: nextToday.status == 'late' ? C.peony : null)),
                  gap(6),
                  Text('berikutnya, $done dari ${td.length} selesai'),
                ];
    } else {
      final cycle = cycleOf(t), n = cycle.clamp(4, 60);
      final left = next == null ? 0 : daysBetween(today, next.at);
      final late = left < 0;
      final elapsed = late ? n : (cycle - left).clamp(0, n);
      painter = DialPainter(n, elapsed, idle);
      center = left == 0
          ? [Text('Hari ini', style: display(48)), gap(6), Text(next == null ? '' : 'pukul ${hhmm.format(next.at)}')]
          : [
              Text('${left.abs()}', style: display(88, color: late ? C.peony : null)),
              gap(6),
              Text(late ? 'hari terlambat' : 'hari lagi'),
            ];
    }

    Widget chip(String s, IconData i) =>
        Chip(avatar: Icon(i, size: 16), label: Text(s), side: BorderSide.none, backgroundColor: fg.withValues(alpha: .07));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: cardBox(context, radius: 36),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 48),
          Expanded(child: Center(child: Text(t.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)))),
          IconButton(
            tooltip: 'Ubah terapi',
            onPressed: () => showSheet(context, TherapySheet(supplies: supplies, initial: t)),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ]),
        gap(12),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(260, 260), painter: painter),
            Column(mainAxisSize: MainAxisSize.min, children: center),
          ]),
        ),
        gap(20),
        Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.center, children: [
          chip('${fmt(t.dose)} ${t.doseUnit}', t.adm.icon),
          chip(scheduleText(t), Icons.event_repeat_rounded),
          if (t.adm.places && place.isNotEmpty) chip('berikutnya: $place', Icons.my_location_rounded),
        ]),
        gap(18),
        pillButton(
          t.route == 'inj' ? 'Catat suntikan' : 'Catat dosis',
          () => showSheet(context, DoseSheet(t: t, slot: next, supplies: supplies, prefs: prefs, suggested: place)),
          icon: Icons.check_rounded,
        ),
        if (next != null && !t.asNeeded) TextButton(onPressed: () => skipSlot(context, ref, next), child: const Text('Lewati dosis ini')),
      ]),
    );
  }
}

/// Tandai satu jadwal sebagai sengaja dilewati.
Future<void> skipSlot(BuildContext context, WidgetRef ref, Slot s) async {
  if (!await confirm(context, 'Lewati dosis ini? Dosis tidak dihitung sebagai sudah diminum dan pengingatnya berhenti.', ok: 'Lewati')) return;
  ref.read(repoProvider)?.logDose(DoseLog(id: '', therapyId: s.t.id, at: s.at, skipped: true, slot: slotKey(s.at)));
}

/// Satu tick per hari dalam siklus.
class DialPainter extends CustomPainter {
  DialPainter(this.n, this.elapsed, this.idle);
  final int n, elapsed;
  final Color idle;
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.width / 2;
    final cur = elapsed.clamp(0, n - 1);
    final w = math.min(8.0, 2 * math.pi * r / n * .5);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final len = i == cur ? 38.0 : 24.0;
      final p = Paint()
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = i == cur ? C.peony : (i < elapsed ? C.lagoon : idle);
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r - len), c + Offset(math.cos(a), math.sin(a)) * (r - 2), p);
    }
  }

  @override
  bool shouldRepaint(DialPainter o) => o.n != n || o.elapsed != elapsed || o.idle != idle;
}

/// 24 tick = 24 jam. Jam yang punya jadwal ditandai: selesai (teal), terlambat (peony), menunggu (teal pudar).
class HourDialPainter extends CustomPainter {
  HourDialPainter(this.marks, this.idle);
  final Map<int, String> marks;
  final Color idle;
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.width / 2;
    for (var i = 0; i < 24; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / 24;
      final st = marks[i];
      final color = st == null
          ? idle
          : st == 'taken'
              ? C.lagoon
              : (st == 'late' || st == 'overdue')
                  ? C.peony
                  : C.lagoon.withValues(alpha: .45);
      final p = Paint()
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = color;
      final len = st == null ? 18.0 : 36.0;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r - len), c + Offset(math.cos(a), math.sin(a)) * (r - 2), p);
    }
  }

  @override
  bool shouldRepaint(HourDialPainter o) => true;
}

class SlotTile extends ConsumerWidget {
  const SlotTile({super.key, required this.s, required this.logs, required this.supplies, required this.prefs});
  final Slot s;
  final List<DoseLog> logs;
  final List<Supply> supplies;
  final Prefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = s.t, fg = Theme.of(context).colorScheme.onSurface;
    final late = s.status == 'overdue' || s.status == 'late';
    final label = sameDay(s.at, logicalToday(prefs)) ? DateFormat('HH:mm').format(s.at) : DateFormat('EEE d MMM, HH:mm', 'id').format(s.at);
    void open() => showSheet(
        context,
        DoseSheet(
          t: t,
          slot: s.taken ? null : s,
          edit: s.taken ? s.log : null,
          supplies: supplies,
          prefs: prefs,
          suggested: suggestPlace(prefs, logs, t.id),
        ));
    Future<void> undoSkip() async {
      if (await confirm(context, 'Batalkan "lewati" untuk dosis ini?', ok: 'Batalkan')) ref.read(repoProvider)?.deleteLog(s.log!, {});
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardBox(context, radius: 22).copyWith(
        border: late && s.pending ? Border.all(color: C.peony.withValues(alpha: .5), width: 1.5) : null,
      ),
      child: ListTile(
        onTap: s.skipped ? undoSkip : open,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        leading: Icon(s.skipped ? Icons.skip_next_rounded : t.adm.icon, color: s.taken ? C.lagoon : (s.skipped ? fg.withValues(alpha: .45) : (late ? C.peony : fg))),
        title: Text(t.name, style: TextStyle(fontWeight: FontWeight.w700, color: s.skipped ? fg.withValues(alpha: .55) : null)),
        subtitle: Text(s.skipped ? 'Dilewati, jadwal $label' : '$label, ${fmt(t.dose)} ${t.doseUnit}'),
        trailing: s.taken
            ? Icon(Icons.check_circle_rounded, color: C.lagoon)
            : s.skipped
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Lewati', onPressed: () => skipSlot(context, ref, s), icon: const Icon(Icons.skip_next_rounded)),
                    FilledButton.tonal(onPressed: open, child: const Text('Catat')),
                  ]),
      ),
    );
  }
}

/// Stok yang hampir habis atau kedaluwarsa, supaya tidak baru ketahuan saat jadwal tiba.
class AlertsCard extends ConsumerWidget {
  const AlertsCard({super.key, required this.supplies});
  final List<Supply> supplies;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = <(IconData, String)>[];
    for (final s in supplies) {
      if (s.expired) {
        alerts.add((Icons.error_outline_rounded, '${s.name} sudah kedaluwarsa'));
        continue;
      }
      if (s.low) alerts.add((Icons.inventory_2_outlined, s.generic ? '${s.name} tinggal ${fmt(s.qty)}' : '${s.name} tinggal ${s.doses} dosis'));
      final d = s.daysToExpiry;
      if (d != null && d <= 30) alerts.add((Icons.event_busy_outlined, '${s.name} kedaluwarsa dalam $d hari'));
    }
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => ref.read(tabProvider.notifier).state = 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: cardBox(context, radius: 24).copyWith(border: Border.all(color: C.amber.withValues(alpha: .6))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Perlu perhatian', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              gap(8),
              for (final a in alerts.take(4))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [Icon(a.$1, size: 18, color: C.amber), const SizedBox(width: 10), Expanded(child: Text(a.$2))]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Perkiraan level estradiol 3 hari lalu sampai 4 hari ke depan (jika ada terapi yang bisa disimulasikan).
class WeekCard extends StatelessWidget {
  const WeekCard({super.key, required this.ths, required this.logs});
  final List<Therapy> ths;
  final List<DoseLog> logs;
  @override
  Widget build(BuildContext context) {
    final intakes = intakesFor('estradiol', ths, logs);
    if (intakes.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now(), from = now.subtract(const Duration(days: 3)), to = now.add(const Duration(days: 4));
    final spots = simSpots(intakes, from, to, n: 56);
    final top = spots.map((e) => e.y).fold<double>(1, math.max) * 1.2;
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: cardBox(context, radius: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Minggu ini', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text('Perkiraan estradiol, ${fmt(levelAt(intakes, now).roundToDouble())} pg/mL sekarang', style: Theme.of(context).textTheme.bodySmall),
        gap(8),
        SizedBox(
          height: 90,
          child: LineChart(LineChartData(
            minX: 0,
            maxX: 7,
            minY: 0,
            maxY: top,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            extraLinesData: ExtraLinesData(verticalLines: [VerticalLine(x: 3, color: fg.withValues(alpha: .3), strokeWidth: 2, dashArray: [4, 4])]),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: C.peony,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: C.peony.withValues(alpha: .10)),
              ),
            ],
          )),
        ),
      ]),
    );
  }
}
