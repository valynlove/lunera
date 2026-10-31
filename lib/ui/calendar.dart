import 'package:flutter/material.dart';
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
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => sel = d),
          child: Column(children: [
            Text(DateFormat('E', L10n.code).format(d), style: TextStyle(fontSize: 12, color: fg.withValues(alpha: .6))),
            gap(6),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? C.peony : null,
                border: !selected && isToday ? Border.all(color: C.peony, width: 1.5) : null,
              ),
              child: Text('${d.day}', style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : fg)),
            ),
            gap(4),
            Icon(Icons.circle, size: 6, color: has(d) ? C.lagoon : Colors.transparent),
          ]),
        ),
      );
    }

    final agenda = ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => sel = DateTime(sel.year, sel.month, sel.day - 7)), icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(child: Center(child: Text(DateFormat('MMMM y', L10n.code).format(sel), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)))),
        IconButton(onPressed: () => setState(() => sel = DateTime(sel.year, sel.month, sel.day + 7)), icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      gap(4),
      Row(children: [for (var i = 0; i < 7; i++) dayCell(DateTime(monday.year, monday.month, monday.day + i))]),
      gap(18),
      Text(DateFormat('EEEE, d MMMM', L10n.code).format(sel), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      gap(10),
      for (final s in pending) SlotTile(s: s, logs: logs, supplies: supplies, prefs: prefs),
      for (final l in done) LogTile(l: l, t: byId[l.therapyId], supplies: supplies, prefs: prefs),
      if (pending.isEmpty && done.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(tr('Nothing scheduled for this day.')))),
      gap(10),
      pillButton(tr('Add schedule'), () => showSheet(context, TherapySheet(supplies: supplies)), icon: Icons.add_rounded),
    ]);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Calendar'), style: display(36)),
          gap(14),
          PillTabs<int>(items: [(0, tr('Schedule')), (1, tr('History')), (2, tr('Journal'))], value: view, onChanged: (v) => setState(() => view = v)),
        ]),
      ),
      Expanded(child: view == 0 ? agenda : (view == 1 ? const HistoryPage(embedded: true) : const JournalView())),
    ]);
  }
}
