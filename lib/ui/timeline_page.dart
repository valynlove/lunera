import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'home.dart';
import 'sheets.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});
  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  DateTime _selectedDate = DateTime.now();
  int _viewMode = 0; // 0: Daily View, 1: Full History

  @override
  Widget build(BuildContext context) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]..sort((a, b) => b.at.compareTo(a.at));
    final journals = ref.watch(journalsProvider).value ?? <JournalEntry>[];
    final byId = {for (final t in ths) t.id: t};

    final slots = buildSlots(ths, logs, prefs, back: 30, ahead: 30);
    final daySlots = [for (final s in slots) if (sameDay(s.at, _selectedDate)) s];
    final dayJournals = [for (final j in journals) if (sameDay(j.at, _selectedDate)) j];
    final starts = [...logs.map((l) => l.at), ...ths.map((t) => t.start)]..sort();

    final now = DateTime.now();
    final daysList = [for (var i = -7; i <= 7; i++) DateTime(now.year, now.month, now.day + i)];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calendar & Timeline', style: display(28)),
                      gap(4),
                      Text(
                        DateFormat('MMMM yyyy', 'en').format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
                            ),
                      ),
                    ],
                  ),
                ),
                // Calendar Date Picker Button
                IconButton.filledTonal(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null && mounted) {
                      setState(() => _selectedDate = d);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  tooltip: 'Pick Date',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _selectedDate = DateTime.now()),
                  icon: const Icon(Icons.today_rounded),
                  tooltip: 'Today',
                ),
              ],
            ),
            gap(16),

            // HRT Counter & Stats Banner
            if (prefs.hrtCounter && starts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timelapse_rounded, color: C.lavender, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hrtDuration(starts.first, DateTime.now()), style: display(22)),
                          gap(4),
                          Text('${logs.length} total doses logged', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              gap(16),
            ],

            // Segment View Switcher
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewMode == 0 ? C.lavender : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'Schedule View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _viewMode == 0 ? C.midnight : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewMode == 1 ? C.lavender : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'Full History (${logs.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _viewMode == 1 ? C.midnight : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            gap(18),

            if (_viewMode == 0) ...[
              // Date Strip
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: daysList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final d = daysList[index];
                    final isSelected = sameDay(d, _selectedDate);
                    final isToday = sameDay(d, now);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? C.lavender
                              : isToday
                                  ? C.lavender.withValues(alpha: .2)
                                  : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: C.lavender, width: 2)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE', 'en').format(d).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? C.midnight
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                              ),
                            ),
                            gap(4),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? C.midnight : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              gap(20),

              // Dose / Slot Cards for Selected Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Therapy Schedule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () {
                      if (ths.isNotEmpty) {
                        showSheet(context, DoseSheet(t: ths.first, supplies: supplies, prefs: prefs));
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Log Dose'),
                  ),
                ],
              ),
              gap(8),

              if (daySlots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'No schedule or recorded doses on this date.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                for (final s in daySlots)
                  SlotTile(s: s, logs: logs, supplies: supplies, prefs: prefs),
              ],

              gap(20),
              // Notes & Observations
              Text("Today's Notes & Observations", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              gap(8),
              if (dayJournals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.note_alt_outlined, color: C.lavender),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('No journal or physical notes for this date.'),
                      ),
                    ],
                  ),
                )
              else
                for (final j in dayJournals)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(j.moodEmoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(j.title.isEmpty ? 'Journal' : j.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (j.note.isNotEmpty) ...[
                                gap(2),
                                Text(j.note, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .8))),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ] else ...[
              // Full History View
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Recorded Doses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () {
                      if (ths.isNotEmpty) {
                        showSheet(context, DoseSheet(t: ths.first, supplies: supplies, prefs: prefs));
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Log Dose'),
                  ),
                ],
              ),
              gap(10),

              if (logs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('No dose records yet. Doses you log will appear here.'),
                  ),
                )
              else ...[
                for (final l in logs) ...[
                  Builder(
                    builder: (context) {
                      final t = byId[l.therapyId];
                      final detail = [
                        DateFormat('HH:mm').format(l.at),
                        '${fmt(l.dose ?? t?.dose ?? 0)} ${t?.doseUnit ?? ''}'.trim(),
                        if (l.places.isNotEmpty) l.places.map(translatePlace).join(', '),
                      ].join(', ');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          leading: Icon(t?.adm.icon ?? Icons.medication_rounded, color: C.lavender),
                          title: Text(t?.name ?? 'Therapy deleted', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(l.note == null ? '${DateFormat('EEE, d MMM yyyy', 'en').format(l.at)} · $detail' : '${DateFormat('EEE, d MMM yyyy', 'en').format(l.at)} · $detail\n${l.note}'),
                          isThreeLine: l.note != null,
                          onTap: () async {
                            if (t != null) {
                              showSheet(context, DoseSheet(t: t, edit: l, supplies: supplies, prefs: prefs));
                            } else if (await confirm(context, 'Therapy for this entry was deleted. Delete this log?') && context.mounted) {
                              ref.read(repoProvider)?.deleteLog(l, {for (final s in supplies) s.id});
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
