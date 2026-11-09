import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  int view = 0; // 0 jadwal, 1 riwayat
  DateTime sel = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]..sort((a, b) => b.at.compareTo(a.at));
    final byId = {for (final t in ths) t.id: t};
    final fg = Theme.of(context).colorScheme.onSurface;

    final slots = buildSlots(ths, logs, prefs, back: 60, ahead: 60);
    final today = logicalToday(prefs);
    final monday = DateTime(sel.year, sel.month, sel.day - (sel.weekday - 1));
    bool has(DateTime d) => slots.any((s) => sameDay(s.at, d)) || logs.any((l) => sameDay(l.at, d));
    final pending = [for (final s in slots) if (sameDay(s.at, sel) && s.pending) s];
    final done = logs.where((l) => sameDay(l.at, sel)).toList()..sort((a, b) => a.at.compareTo(b.at));

    Widget dayCell(DateTime d) {
      final selected = sameDay(d, sel), isToday = sameDay(d, today);
      final hasEvent = has(d);
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
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
                  fontSize: 14,
                  color: selected
                      ? Colors.white
                      : (isToday ? Pastel.mint : fg),
                ),
              ),
            ),
            gap(5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasEvent
                    ? (selected ? Pastel.mint : C.lagoon)
                    : Colors.transparent,
              ),
            ),
          ]),
        ),
      );
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
                  setState(() => sel = DateTime(sel.year, sel.month, sel.day - 7));
                },
                icon: const Icon(Icons.chevron_left_rounded, color: Pastel.lilac),
                tooltip: tr('Previous week'),
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
                  ),
                ),
              ),
              if (!sameDay(sel, today)) ...[
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => sel = today);
                  },
                  icon: const Icon(Icons.today_rounded, size: 14, color: Pastel.mint),
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
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => sel = DateTime(sel.year, sel.month, sel.day + 7));
                },
                icon: const Icon(Icons.chevron_right_rounded, color: Pastel.lilac),
                tooltip: tr('Next week'),
              ),
            ]),
            gap(10),
            Row(children: [for (var i = 0; i < 7; i++) dayCell(DateTime(monday.year, monday.month, monday.day + i))]),
          ],
        ),
      ),
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
              iconBadge(Icons.nightlight_round, Pastel.lilac, size: 48, iconSize: 24),
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
        icon: Icons.add_rounded,
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
