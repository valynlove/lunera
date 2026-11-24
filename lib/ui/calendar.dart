import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'history.dart';
import 'home.dart';
import 'journal.dart';
import 'sheets.dart';
import '../l10n.dart';

/// Tab Kalender: jadwal per hari (strip minggu) dan riwayat.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  int view = 0; // 0 jadwal, 1 riwayat, 2 jurnal
  DateTime sel = DateUtils.dateOnly(DateTime.now());
  bool isMonthView = false;

  @override
  Widget build(BuildContext context) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]..sort((a, b) => b.at.compareTo(a.at));
    final journal = ref.watch(journalProvider).value ?? <JournalEntry>[];
    final byId = {for (final t in ths) t.id: t};
    final fg = Theme.of(context).colorScheme.onSurface;

    final slots = buildSlots(ths, logs, prefs, back: 60, ahead: 60);
    final today = logicalToday(prefs);
    final monday = DateTime(sel.year, sel.month, sel.day - (sel.weekday - 1));

    final troughWindows = computeTroughWindows(slots);
    final supplyRunoutMap = <DateTime, List<Supply>>{};
    for (final s in supplies) {
      final f = estimateSupplyForecast(s, ths);
      if (f != null && f.daysLeft > 0) {
        final d = DateUtils.dateOnly(f.runOutDate);
        supplyRunoutMap.putIfAbsent(d, () => []).add(s);
      }
    }

    bool hasDose(DateTime d) => slots.any((s) => sameDay(s.at, d)) || logs.any((l) => sameDay(l.at, d));
    bool hasDoneDose(DateTime d) => logs.any((l) => sameDay(l.at, d) && !l.skipped);
    bool isTroughDate(DateTime d) => troughWindows.any((tw) => sameDay(tw.targetDate, d));
    bool hasJournalDate(DateTime d) => journal.any((j) => sameDay(j.at, d));
    bool hasSupplyRunout(DateTime d) => supplyRunoutMap.keys.any((sd) => sameDay(sd, d));

    final pending = [for (final s in slots) if (sameDay(s.at, sel) && s.pending) s];
    final done = logs.where((l) => sameDay(l.at, sel)).toList()..sort((a, b) => a.at.compareTo(b.at));
    final troughsOnSel = troughWindows.where((tw) => sameDay(tw.targetDate, sel)).toList();
    final suppliesOnSel = supplyRunoutMap[DateUtils.dateOnly(sel)] ?? const <Supply>[];

    Widget cellDot(Color color) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 0.8),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );

    Widget dayCell(DateTime d, {bool isCurrentMonth = true}) {
      final selected = sameDay(d, sel), isToday = sameDay(d, today);
      final dose = hasDose(d);
      final doneDose = hasDoneDose(d);
      final trough = isTroughDate(d);
      final jnl = hasJournalDate(d);
      final sup = hasSupplyRunout(d);

      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!selected) {
              HapticFeedback.selectionClick();
            }
            setState(() => sel = d);
          },
          child: Column(children: [
            if (!isMonthView) ...[
              Text(
                DateFormat('E', L10n.code).format(d),
                style: TextStyle(
                  fontSize: 11.5,
                  color: selected
                      ? Colors.white
                      : (isToday ? Pastel.mint : fg.withValues(alpha: .75)),
                  fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              gap(6),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? C.peony
                    : (isToday ? Pastel.mint.withValues(alpha: .15) : Colors.transparent),
                border: !selected && isToday
                    ? Border.all(color: Pastel.mint.withValues(alpha: .6), width: 1.5)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: C.peony.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${d.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: selected
                      ? Colors.white
                      : (!isCurrentMonth
                          ? fg.withValues(alpha: 0.35)
                          : (isToday ? Pastel.mint : fg)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dose) cellDot(doneDose ? Pastel.mint : C.lagoon),
                  if (trough) cellDot(Pastel.mint),
                  if (jnl) cellDot(Pastel.lilac),
                  if (sup) cellDot(C.coral),
                ],
              ),
            ),
          ]),
        ),
      );
    }

    Widget buildMonthMatrix() {
      final gridDays = buildMonthGridDays(sel);
      final rows = <Widget>[];
      final weekdays = [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (final wd in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('E', L10n.code).format(wd),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fg.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      for (var r = 0; r < gridDays.length; r += 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  dayCell(gridDays[r + c], isCurrentMonth: gridDays[r + c].month == sel.month),
              ],
            ),
          ),
        );
      }
      return Column(children: rows);
    }

    final agenda = ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        decoration: cardBox(context, radius: 24),
        child: Column(
          children: [
            Row(children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isMonthView) {
                      sel = DateTime(sel.year, sel.month - 1, sel.day > 28 ? 28 : sel.day);
                    } else {
                      sel = DateTime(sel.year, sel.month, sel.day - 7);
                    }
                  });
                },
                icon: const Icon(LucideIcons.chevronLeft, color: Pastel.lilac),
                tooltip: isMonthView ? tr('Previous month') : tr('Previous week'),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM y', L10n.code).format(sel),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              if (!sameDay(sel, today)) ...[
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => sel = today);
                  },
                  icon: const Icon(LucideIcons.calendarCheck, size: 14, color: Pastel.mint),
                  label: Text(
                    tr('Today'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Pastel.mint),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Pastel.mint.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: Icon(
                  isMonthView ? LucideIcons.calendarRange : LucideIcons.calendar,
                  color: Pastel.lilac,
                  size: 18,
                ),
                tooltip: isMonthView ? tr('Switch to week view') : tr('Switch to month view'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isMonthView = !isMonthView);
                },
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isMonthView) {
                      sel = DateTime(sel.year, sel.month + 1, sel.day > 28 ? 28 : sel.day);
                    } else {
                      sel = DateTime(sel.year, sel.month, sel.day + 7);
                    }
                  });
                },
                icon: const Icon(LucideIcons.chevronRight, color: Pastel.lilac),
                tooltip: isMonthView ? tr('Next month') : tr('Next week'),
              ),
            ]),
            gap(10),
            if (isMonthView)
              buildMonthMatrix()
            else
              Row(children: [for (var i = 0; i < 7; i++) dayCell(DateTime(monday.year, monday.month, monday.day + i))]),
          ],
        ),
      ),
      if (troughsOnSel.isNotEmpty) ...[
        gap(14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Pastel.mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Pastel.mint.withValues(alpha: 0.35),
              width: 1.1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Pastel.mint.withValues(alpha: 0.18),
                ),
                child: const Icon(LucideIcons.flaskConical, color: Pastel.mint, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Optimal Trough Lab Window'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr('Best window for routine hormone blood tests is right before taking your {0} dose to capture accurate baseline levels.',
                          [troughsOnSel.first.therapy.name]),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.90),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      if (suppliesOnSel.isNotEmpty) ...[
        gap(14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.coral.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: C.coral.withValues(alpha: 0.28),
              width: 1.1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.truck, color: C.coral, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Supply Horizon Alert'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr('{0} is projected to deplete today. Check supplies tab or order assistant.',
                          [suppliesOnSel.first.name]),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.90),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      gap(20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              sameDay(sel, today)
                  ? tr('Today, {0}', [DateFormat('d MMMM', L10n.code).format(sel)])
                  : DateFormat('EEEE, d MMMM', L10n.code).format(sel),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (pending.isNotEmpty || done.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
              decoration: BoxDecoration(
                color: (pending.isEmpty ? Pastel.mint : C.amber).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (pending.isEmpty ? Pastel.mint : C.amber).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                pending.isEmpty ? tr('Completed') : tr('{0} pending', [pending.length]),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pending.isEmpty ? Pastel.mint : C.amber,
                ),
              ),
            ),
        ],
      ),
      gap(12),
      for (final s in pending) SlotTile(s: s, logs: logs, supplies: supplies, prefs: prefs),
      for (final l in done) LogTile(l: l, t: byId[l.therapyId], supplies: supplies, prefs: prefs),
      if (pending.isEmpty && done.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: cardBox(context, radius: 20),
          child: Column(
            children: [
              iconBadge(LucideIcons.moon, Pastel.lilac, size: 48, iconSize: 24),
              const SizedBox(height: 12),
              Text(
                tr('No doses scheduled'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                tr('Enjoy your rest day or log a dose manually if needed.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Pastel.mist.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      gap(16),
      pillButton(
        tr('Add schedule'),
        () {
          HapticFeedback.lightImpact();
          showSheet(context, TherapySheet(supplies: supplies));
        },
        icon: LucideIcons.plus,
      ),
    ]);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Calendar'), style: display(40)),
          gap(14),
          PillTabs<int>(
            items: [(0, tr('Schedule')), (1, tr('History')), (2, tr('Journal'))],
            value: view,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => view = v);
            },
          ),
        ]),
      ),
      Expanded(child: view == 0 ? agenda : (view == 1 ? const HistoryPage(embedded: true) : const JournalView())),
    ]);
  }
}
