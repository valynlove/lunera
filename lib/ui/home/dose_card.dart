import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../schedule.dart';
import '../../theme.dart';
import '../guided_injection.dart';
import '../sheets.dart';

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
                  const Icon(LucideIcons.circleCheckBig,
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
                            child: Icon(LucideIcons.pencil,
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
                              Icon(LucideIcons.repeat,
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
                    if (!t.asNeeded && next != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.calendarClock,
                              size: 13, color: Pastel.lilac),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tr('Next: {0}', [
                                DateFormat('EEEE, d MMM • HH:mm', L10n.code)
                                    .format(next.at),
                              ]),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Pastel.lilac,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (t.adm.places && place.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.locateFixed,
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
                  icon: const Icon(LucideIcons.check, size: 18),
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
                  icon: const Icon(LucideIcons.heartPulse,
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
