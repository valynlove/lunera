import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../profile.dart';
import '../repo.dart';
import '../schedule.dart';
import '../sim.dart';
import '../theme.dart';
import 'journal.dart';
import 'guided_injection.dart';
import 'profile_page.dart';
import 'sheets.dart';
import '../l10n.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]
      ..sort((a, b) => b.at.compareTo(a.at));
    final slots = buildSlots(ths, logs, prefs);
    final overdue = [
      for (final s in slots)
        if (s.status == 'overdue') s
    ];

    final displayName = ref.watch(displayNameProvider);
    final greet = greeting();

    final fg = Theme.of(context).colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // 1. Header (Airy, welcoming, high contrast)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greet,',
                    style: TextStyle(
                      fontSize: 14,
                      color: fg.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName ?? appName,
                          style: display(24, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: C.peony.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: C.peony.withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: Text(
                            'DEV',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: C.peony,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEEE, d MMMM y', L10n.code)
                        .format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Pastel.cream.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: tr('Add therapy'),
              onPressed: () {
                HapticFeedback.lightImpact();
                showSheet(context, TherapySheet(supplies: supplies));
              },
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 10),
            UserAvatar(
              size: 44,
              heroTag: 'profile_photo_hero',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. High-priority Banners (Overdue doses & Low supply alerts)
        if (overdue.isNotEmpty)
          _OverdueAlertBanner(
            overdue: overdue,
            onReview: () =>
                _showOverdueSheet(context, overdue, logs, supplies, prefs),
          ),
        AlertsCard(supplies: supplies),

        // 3. Main content
        if (ths.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(children: [
              Text(tr('No therapies yet'), style: display(32)),
              gap(10),
              Text(
                tr('Add your first medication to start tracking your schedule.'),
                style: TextStyle(color: Pastel.mist.withValues(alpha: 0.85)),
              ),
              gap(20),
              pillButton(
                tr('Add therapy'),
                () {
                  HapticFeedback.lightImpact();
                  showSheet(context, TherapySheet(supplies: supplies));
                },
                icon: Icons.add_rounded,
              ),
            ]),
          )
        else ...[
          // Hero Dose Cards
          for (final t in ths)
            DoseCard(
                t: t,
                slots: slots,
                logs: logs,
                supplies: supplies,
                prefs: prefs),

          // 7-day Hormone Trend Curve
          WeekCard(ths: ths, logs: logs),

          // Quick Mood Check-in
          const MoodQuickCard(),

          // Seamless bridge to Calendar tab
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(tabProvider.notifier).state = 1;
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        size: 16, color: Pastel.lilac),
                    const SizedBox(width: 8),
                    Text(
                      tr('View full schedule in Calendar'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Pastel.lilac,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: Pastel.lilac),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class DoseCard extends ConsumerWidget {
  const DoseCard(
      {super.key,
      required this.t,
      required this.slots,
      required this.logs,
      required this.supplies,
      required this.prefs});
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
        Text(last == null ? '-' : '$since',
            style: display(32, color: Colors.white)),
        Text(last == null ? tr('no entries') : tr('{0?day|days} ago', [since]),
            style: TextStyle(
                fontSize: 10,
                color: Pastel.cream.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600)),
      ];
    } else if (t.daily) {
      final td = [
        for (final s in mine)
          if (sameDay(s.at, today)) s
      ];
      final done = td.where((s) => !s.pending).length;
      final nextToday = td.where((s) => s.pending).firstOrNull;
      painter =
          HourDialPainter({for (final s in td) s.at.hour: s.status}, idle);
      center = td.isEmpty
          ? [Text(tr('Day off'), style: display(18, color: Colors.white))]
          : nextToday == null
              ? [
                  const Icon(Icons.check_circle_rounded,
                      color: Pastel.mint, size: 26),
                  const SizedBox(height: 2),
                  Text(tr('{0}/{1}', [done, td.length]),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]
              : [
                  Text(hhmm.format(nextToday.at),
                      style: display(20,
                          color: nextToday.status == 'late'
                              ? C.peony
                              : Colors.white)),
                  const SizedBox(height: 2),
                  Text(tr('{0}/{1}', [done, td.length]),
                      style: TextStyle(
                          fontSize: 10,
                          color: Pastel.cream.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600)),
                ];
    } else {
      final cycle = cycleOf(t), n = cycle.clamp(4, 60);
      final left = next == null ? 0 : daysBetween(today, next.at);
      final late = left < 0;
      final elapsed = late ? n : (cycle - left).clamp(0, n);
      painter = DialPainter(n, elapsed, idle);
      center = left == 0
          ? [
              Text(tr('Today'), style: display(20, color: C.amber)),
              if (next != null)
                Text(hhmm.format(next.at),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
            ]
          : [
              Text('${left.abs()}',
                  style: display(32, color: late ? C.peony : Colors.white)),
              Text(
                late
                    ? tr('{0?day|days} late', [left.abs()])
                    : tr('{0?day|days} left', [left.abs()]),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: late ? C.peony : Pastel.cream.withValues(alpha: 0.85),
                ),
              ),
            ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardBox(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dial miniatur presisi (100x100) dengan interaksi haptic
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showSheet(
                        context,
                        DoseSheet(
                            t: t,
                            slot: next,
                            supplies: supplies,
                            prefs: prefs,
                            suggested: place));
                  },
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                            size: const Size(100, 100), painter: painter),
                        Column(
                            mainAxisSize: MainAxisSize.min, children: center),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Detail terapi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            showSheet(context,
                                TherapySheet(supplies: supplies, initial: t));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_outlined,
                                size: 16,
                                color: Pastel.mist.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: C.peony.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: C.peony.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.adm.icon, size: 12, color: Pastel.lilac),
                              const SizedBox(width: 4),
                              Text(
                                '${fmt(t.dose)} ${t.doseUnit}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_repeat_rounded,
                                  size: 12,
                                  color: Pastel.cream.withValues(alpha: 0.85)),
                              const SizedBox(width: 4),
                              Text(
                                scheduleText(t),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Pastel.mist.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (t.adm.places && place.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded,
                              size: 13, color: Pastel.mint),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tr('next: {0}', [tr(place)]),
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Pastel.mint),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showSheet(
                        context,
                        DoseSheet(
                            t: t,
                            slot: next,
                            supplies: supplies,
                            prefs: prefs,
                            suggested: place));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: C.peony,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    elevation: 2,
                    shadowColor: C.peony.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    t.route == 'inj' ? tr('Log injection') : tr('Log dose'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (t.route == 'inj') ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: tr('Guided Calm Injection'),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: C.peony.withValues(alpha: 0.5)),
                    backgroundColor: C.peony.withValues(alpha: 0.12),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CalmInjectionSheet(
                        t: t,
                        slot: next,
                        supplies: supplies,
                        prefs: prefs,
                        suggestedPlace: place,
                      ),
                    );
                  },
                  icon: const Icon(Icons.self_improvement_rounded,
                      size: 20, color: Pastel.lilac),
                ),
              ],
              if (next != null && !t.asNeeded) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    skipSlot(context, ref, next);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: Text(
                    tr('Skip'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Pastel.mist.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Tandai satu jadwal sebagai sengaja dilewati.
Future<void> skipSlot(BuildContext context, WidgetRef ref, Slot s) async {
  if (!await confirm(context,
      tr('Skip this dose? It won\'t count as taken and its reminder will stop.'),
      ok: tr('Skip'))) {
    return;
  }
  ref.read(repoProvider)?.logDose(DoseLog(
      id: '', therapyId: s.t.id, at: s.at, skipped: true, slot: slotKey(s.at)));
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
    final scale = (r / 130.0).clamp(0.4, 1.0);
    final w = math.min(6.0 * scale, 2 * math.pi * r / n * .5);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final len = (i == cur ? 30.0 : 18.0) * scale;
      final p = Paint()
        ..strokeWidth = math.max(2.0, w)
        ..strokeCap = StrokeCap.round
        ..color = i == cur ? C.peony : (i < elapsed ? Pastel.mint : idle);
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r - len),
          c + Offset(math.cos(a), math.sin(a)) * (r - 2), p);
    }
  }

  @override
  bool shouldRepaint(DialPainter o) =>
      o.n != n || o.elapsed != elapsed || o.idle != idle;
}

/// 24 tick = 24 jam. Jam yang punya jadwal ditandai: selesai (mint), terlambat (peony), menunggu (amber pudar).
class HourDialPainter extends CustomPainter {
  HourDialPainter(this.marks, this.idle);
  final Map<int, String> marks;
  final Color idle;
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.width / 2;
    final scale = (r / 130.0).clamp(0.4, 1.0);
    for (var i = 0; i < 24; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / 24;
      final st = marks[i];
      final color = st == null
          ? idle
          : st == 'taken'
              ? Pastel.mint
              : (st == 'late' || st == 'overdue')
                  ? C.peony
                  : C.amber.withValues(alpha: .55);
      final p = Paint()
        ..strokeWidth = (5 * scale).clamp(2.5, 6.0)
        ..strokeCap = StrokeCap.round
        ..color = color;
      final len = (st == null ? 14.0 : 26.0) * scale;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r - len),
          c + Offset(math.cos(a), math.sin(a)) * (r - 2), p);
    }
  }

  @override
  bool shouldRepaint(HourDialPainter o) => true;
}

class SlotTile extends ConsumerWidget {
  const SlotTile(
      {super.key,
      required this.s,
      required this.logs,
      required this.supplies,
      required this.prefs});
  final Slot s;
  final List<DoseLog> logs;
  final List<Supply> supplies;
  final Prefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = s.t, fg = Theme.of(context).colorScheme.onSurface;
    final late = s.status == 'overdue' || s.status == 'late';
    final label = sameDay(s.at, logicalToday(prefs))
        ? DateFormat('HH:mm').format(s.at)
        : DateFormat('EEE d MMM, HH:mm', L10n.code).format(s.at);
    void open() {
      HapticFeedback.lightImpact();
      showSheet(
        context,
        DoseSheet(
          t: t,
          slot: s.taken ? null : s,
          edit: s.taken ? s.log : null,
          supplies: supplies,
          prefs: prefs,
          suggested: suggestPlace(prefs, logs, t.id),
        ),
      );
    }

    Future<void> undoSkip() async {
      HapticFeedback.mediumImpact();
      if (await confirm(context, tr('Undo "skip" for this dose?'),
          ok: tr('Undo'))) {
        ref.read(repoProvider)?.deleteLog(s.log!, {});
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardBox(context, radius: 22).copyWith(
        border: late && s.pending
            ? Border.all(color: C.peony.withValues(alpha: .5), width: 1.5)
            : null,
      ),
      child: ListTile(
        onTap: s.skipped ? undoSkip : open,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        leading: Icon(s.skipped ? Icons.skip_next_rounded : t.adm.icon,
            color: s.taken
                ? C.lagoon
                : (s.skipped
                    ? fg.withValues(alpha: .45)
                    : (late ? C.peony : fg))),
        title: Text(t.name,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: s.skipped ? fg.withValues(alpha: .7) : Colors.white)),
        subtitle: Text(
          s.skipped
              ? tr('Skipped, scheduled {0}', [label])
              : '$label, ${fmt(t.dose)} ${t.doseUnit}',
          style: TextStyle(
              color: Pastel.mist.withValues(alpha: 0.85), fontSize: 12),
        ),
        trailing: s.taken
            ? Icon(Icons.check_circle_rounded, color: C.lagoon)
            : s.skipped
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: tr('Skip'),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        skipSlot(context, ref, s);
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    FilledButton.tonal(
                      onPressed: open,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(tr('Log')),
                    ),
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
        alerts.add(
            (Icons.error_outline_rounded, tr('{0} has expired', [s.name])));
        continue;
      }
      if (s.low) {
        alerts.add((
          Icons.inventory_2_outlined,
          s.generic
              ? tr('{0} has {1} left', [s.name, fmt(s.qty)])
              : tr('{0} has {1} {1?dose|doses} left', [s.name, s.doses])
        ));
      }
      final d = s.daysToExpiry;
      if (d != null && d <= 30) {
        alerts.add((
          Icons.event_busy_outlined,
          tr('{0} expires in {1} {1?day|days}', [s.name, d])
        ));
      }
    }
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(tabProvider.notifier).state = 3;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: cardBox(context, radius: 20).copyWith(
              border:
                  Border.all(color: C.amber.withValues(alpha: .65), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconBadge(Icons.inventory_2_rounded, C.amber,
                    size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerts.length == 1
                            ? tr('Supply alert ({0})', [alerts.length])
                            : tr('Supply alerts ({0})', [alerts.length]),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Pastel.butter),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alerts.first.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: Pastel.mist.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: C.amber.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner peringatan ringkas untuk dosis yang terlewat.
class _OverdueAlertBanner extends StatelessWidget {
  const _OverdueAlertBanner({required this.overdue, required this.onReview});

  final List<Slot> overdue;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E193C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: C.peony.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: C.peony.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                iconBadge(Icons.warning_amber_rounded, C.peony,
                    size: 36, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('{0} missed {0?dose|doses}', [overdue.length]),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('Tap to review and log or skip'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Pastel.mist.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onReview();
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(tr('Review'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menampilkan modal bottom sheet untuk meninjau dan menyelesaikan seluruh dosis terlewat.
void _showOverdueSheet(
  BuildContext context,
  List<Slot> overdue,
  List<DoseLog> logs,
  List<Supply> supplies,
  Prefs prefs,
) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: C.deepCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: const Color(0xFFE8D3A5).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ListView(
          controller: scroll,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                iconBadge(Icons.warning_amber_rounded, C.peony,
                    size: 36, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Missed Doses'),
                        style: display(22, weight: FontWeight.w700),
                      ),
                      Text(
                        tr('Review and catch up on pending doses'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Pastel.mist.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final s in overdue)
              SlotTile(s: s, logs: logs, supplies: supplies, prefs: prefs),
          ],
        ),
      ),
    ),
  );
}

/// Perkiraan level hormon 3 hari lalu sampai 4 hari ke depan (jika ada terapi yang bisa disimulasikan).
class WeekCard extends ConsumerWidget {
  const WeekCard({super.key, required this.ths, required this.logs});
  final List<Therapy> ths;
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeHormones = <String>[];
    final hormoneIntakes = <String, List<Intake>>{};
    for (final h in ['estradiol', 'progesterone', 'testosterone']) {
      final xs = intakesFor(h, ths, logs);
      if (xs.isNotEmpty) {
        activeHormones.add(h);
        hormoneIntakes[h] = xs;
      }
    }
    if (activeHormones.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now(),
        from = now.subtract(const Duration(days: 3)),
        to = now.add(const Duration(days: 4));

    final lines = <LineChartBarData>[];
    double maxTop = 1.0;
    final summaryTexts = <String>[];

    for (final h in activeHormones) {
      final intakes = hormoneIntakes[h]!;
      final spots = simSpots(intakes, from, to, n: 56);
      final top = spots.map((e) => e.y).fold<double>(1, math.max);
      if (top > maxTop) maxTop = top;

      final color = hormoneColor(h);
      final p = presetOf(h);
      final nowVal = levelAt(intakes, now);
      final valStr = h == 'progesterone'
          ? (nowVal < 1 ? nowVal.toStringAsFixed(2) : nowVal.toStringAsFixed(1))
          : (nowVal >= 20 ? '${nowVal.round()}' : fmt(nowVal));
      summaryTexts.add('${p.name}: $valStr ${p.base}');

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .22),
                color.withValues(alpha: .01),
              ],
            ),
          ),
        ),
      );
    }

    final top = maxTop * 1.2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: cardBox(context, radius: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  iconBadge(Icons.auto_graph_rounded, C.peony,
                      size: 28, iconSize: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Hormone Trend'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(tabProvider.notifier).state = 0;
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr('See Detail'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Pastel.lilac),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: Pastel.lilac),
                  ],
                ),
              ),
            ),
          ],
        ),
        gap(6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final h in activeHormones)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hormoneColor(h),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    h == 'estradiol'
                        ? 'Estradiol (E2)'
                        : (h == 'progesterone'
                            ? 'Progesterone (P4)'
                            : presetOf(h).name),
                    style: TextStyle(
                      fontSize: 11,
                      color: Pastel.mist.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        gap(8),
        SizedBox(
          height: 100,
          child: LineChart(LineChartData(
            minX: 0,
            maxX: 7,
            minY: 0,
            maxY: top,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            extraLinesData: ExtraLinesData(verticalLines: [
              VerticalLine(
                  x: 3,
                  color: Pastel.lilac.withValues(alpha: .40),
                  strokeWidth: 1.5,
                  dashArray: [4, 4]),
            ]),
            lineBarsData: lines,
          )),
        ),
        gap(4),
        Text(
          summaryTexts.join('  •  '),
          style: TextStyle(
              fontSize: 11,
              color: Pastel.mist.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}
