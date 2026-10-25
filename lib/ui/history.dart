import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'sheets.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _add(BuildContext c, List<Therapy> ths, List<Supply> supplies, Prefs prefs, List<DoseLog> logs) async {
    if (ths.isEmpty) return;
    final t = ths.length == 1 ? ths.first : await showSheet<Therapy>(c, _Pick(ths));
    if (t == null || !c.mounted) return;
    showSheet(c, DoseSheet(t: t, supplies: supplies, prefs: prefs, suggested: suggestPlace(prefs, logs, t.id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]..sort((a, b) => b.at.compareTo(a.at));
    final byId = {for (final t in ths) t.id: t};
    final starts = [...logs.map((l) => l.at), ...ths.map((t) => t.start)]..sort();
    final surface = Theme.of(context).colorScheme.surface;

    final rows = <Widget>[];
    DateTime? day;
    for (final l in logs) {
      if (day == null || !sameDay(day, l.at)) {
        day = l.at;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
          child: Text(DateFormat('EEEE, d MMMM y', 'en').format(l.at), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ));
      }
      final t = byId[l.therapyId];
      final detail = [
        DateFormat('HH:mm').format(l.at),
        '${fmt(l.dose ?? t?.dose ?? 0)} ${t?.doseUnit ?? ''}'.trim(),
        if (l.places.isNotEmpty) l.places.map(translatePlace).join(', '),
      ].join(', ');
      rows.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(22)),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          leading: Icon(t?.adm.icon ?? Icons.medication_rounded, color: C.lagoon),
          title: Text(t?.name ?? 'Therapy deleted', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(l.note == null ? detail : '$detail\n${l.note}'),
          isThreeLine: l.note != null,
          onTap: () async {
            if (t != null) {
              showSheet(context, DoseSheet(t: t, edit: l, supplies: supplies, prefs: prefs));
            } else if (await confirm(context, 'Therapy for this entry was deleted. Delete this log?') && context.mounted) {
              ref.read(repoProvider)?.deleteLog(l, {for (final s in supplies) s.id});
            }
          },
        ),
      ));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
      Row(children: [
        Expanded(child: Text('History', style: display(40))),
        pillButton('Log Dose', () => _add(context, ths, supplies, prefs, logs), icon: Icons.add_rounded),
      ]),
      gap(14),
      if (prefs.hrtCounter && starts.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(28)),
          child: Row(children: [
            Icon(Icons.timelapse_rounded, color: C.peony, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hrtDuration(starts.first, DateTime.now()), style: display(24)),
                gap(6),
                Text('${logs.length} doses logged'),
              ]),
            ),
          ]),
        ),
      if (logs.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Text('No records yet. Doses you log will appear here.')),
      ...rows,
    ]);
  }
}

class _Pick extends StatelessWidget {
  const _Pick(this.ths);
  final List<Therapy> ths;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Which therapy?', style: display(28)),
        gap(16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in ths) ActionChip(avatar: Icon(t.adm.icon, size: 16), label: Text(t.name), onPressed: () => Navigator.pop(context, t)),
        ]),
      ]);
}
