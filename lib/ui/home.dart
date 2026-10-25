import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'settings_page.dart';
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
    final nickname = prefs.nickname.trim();
    final userName = nickname.isNotEmpty
        ? nickname
        : ((user?.displayName?.isNotEmpty ?? false)
            ? user!.displayName!
            : ((user?.email?.isNotEmpty ?? false) ? user!.email!.split('@').first : 'Lunera Friend'));
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 18 ? 'Good Afternoon' : 'Good Evening');
    final nextSlot = slots.where((s) => !s.taken).firstOrNull;
    final place = nextSlot == null ? '' : suggestPlace(prefs, logs, nextSlot.t.id);

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting,', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
                Text(userName, style: display(26)),
                gap(2),
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 14, color: C.lavender),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, d MMM yyyy', 'en').format(DateTime.now()),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => showSheet(context, TherapySheet(supplies: supplies)),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 10),
          buildAvatar(
            prefs,
            radius: 20,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      gap(16),

      if (nextSlot != null) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: C.lavender.withValues(alpha: .25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEXT SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: C.lavender)),
                    gap(6),
                    Text(nextSlot.t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    gap(4),
                    Text(
                      '${sameDay(nextSlot.at, today) ? "Today" : DateFormat("EEE, d MMM", "en").format(nextSlot.at)}, ${DateFormat("HH:mm").format(nextSlot.at)}',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: C.lavender, foregroundColor: C.midnight),
                icon: const Icon(Icons.check_rounded, size: 24),
                onPressed: () => showSheet(
                  context,
                  DoseSheet(
                    t: nextSlot.t,
                    slot: nextSlot,
                    supplies: supplies,
                    prefs: prefs,
                    suggested: place,
                  ),
                ),
              ),
            ],
          ),
        ),
        gap(16),
      ],
      if (ths.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(children: [
            Text('No therapy added', style: display(32)),
            gap(10),
            const Text('Add your first medication to start calculating your schedule.'),
            gap(20),
            pillButton('Add Therapy', () => showSheet(context, TherapySheet(supplies: supplies)), icon: Icons.add_rounded),
          ]),
        )
      else ...[
        for (final t in ths) DoseCard(t: t, slots: slots, logs: logs, supplies: supplies, prefs: prefs),
        section('Overdue', overdue),
        section('Today', todays),
        section('Next 7 days', upcoming),
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
    final next = mine.where((s) => !s.taken).firstOrNull;
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
        Text(last == null ? 'no records' : 'days since last dose'),
      ];
    } else if (t.daily) {
      final td = [for (final s in mine) if (sameDay(s.at, today)) s];
      final done = td.where((s) => s.taken).length;
      final nextToday = td.where((s) => !s.taken).firstOrNull;
      painter = HourDialPainter({for (final s in td) s.at.hour: s.status}, idle);
      center = td.isEmpty
          ? [Text('Rest day', style: display(48))]
          : nextToday == null
              ? [Text('Completed', style: display(48)), gap(6), Text('$done of ${td.length} doses today')]
              : [
                  Text(hhmm.format(nextToday.at), style: display(64, color: nextToday.status == 'late' ? C.peony : null)),
                  gap(6),
                  Text('next, $done of ${td.length} completed'),
                ];
    } else {
      final cycle = cycleOf(t), n = cycle.clamp(4, 60);
      final left = next == null ? 0 : daysBetween(today, next.at);
      final late = left < 0;
      final elapsed = late ? n : (cycle - left).clamp(0, n);
      painter = DialPainter(n, elapsed, idle);
      center = left == 0
          ? [Text('Today', style: display(48)), gap(6), Text(next == null ? '' : 'at ${hhmm.format(next.at)}')]
          : [
              Text('${left.abs()}', style: display(88, color: late ? C.peony : null)),
              gap(6),
              Text(late ? 'days overdue' : 'days left'),
            ];
    }

    Widget chip(String s, IconData i) =>
        Chip(avatar: Icon(i, size: 16), label: Text(s), side: BorderSide.none, backgroundColor: fg.withValues(alpha: .07));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(40)),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 48),
          Expanded(child: Center(child: Text(t.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)))),
          IconButton(
            tooltip: 'Edit therapy',
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
          if (t.adm.places && place.isNotEmpty) chip('next: ${translatePlace(place)}', Icons.my_location_rounded),
        ]),
        gap(18),
        pillButton(
          t.route == 'inj' ? 'Log Injection' : 'Log Dose',
          () => showSheet(context, DoseSheet(t: t, slot: next, supplies: supplies, prefs: prefs, suggested: place)),
          icon: Icons.check_rounded,
        ),
      ]),
    );
  }
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
    final label = sameDay(s.at, logicalToday(prefs)) ? DateFormat('HH:mm').format(s.at) : DateFormat('EEE d MMM, HH:mm', 'en').format(s.at);
    void open() => showSheet(
        context,
        DoseSheet(
          t: t,
          slot: s.taken ? null : s,
          edit: s.log,
          supplies: supplies,
          prefs: prefs,
          suggested: suggestPlace(prefs, logs, t.id),
        ));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: late && !s.taken ? Border.all(color: C.peony.withValues(alpha: .5), width: 1.5) : null,
      ),
      child: ListTile(
        onTap: open,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        leading: Icon(t.adm.icon, color: s.taken ? C.lagoon : (late ? C.peony : fg)),
        title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$label, ${fmt(t.dose)} ${t.doseUnit}'),
        trailing: s.taken
            ? Icon(Icons.check_circle_rounded, color: C.lagoon)
            : FilledButton.tonal(onPressed: open, child: const Text('Log')),
      ),
    );
  }
}
