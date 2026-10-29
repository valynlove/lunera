import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'sheets.dart';

/// Satu catatan dosis (diminum atau dilewati). Ketuk untuk mengubah atau menghapus.
class LogTile extends ConsumerWidget {
  const LogTile({super.key, required this.l, required this.t, required this.supplies, required this.prefs});
  final DoseLog l;
  final Therapy? t;
  final List<Supply> supplies;
  final Prefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hhmm = DateFormat('HH:mm').format(l.at);
    final detail = l.skipped
        ? 'Dilewati, jadwal $hhmm'
        : [
            hhmm,
            '${fmt(l.dose ?? t?.dose ?? 0)} ${t?.doseUnit ?? ''}'.trim(),
            if (l.places.isNotEmpty) l.places.join(', '),
          ].join(', ');
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: cardBox(context, radius: 22),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        leading: Icon(l.skipped ? Icons.skip_next_rounded : (t?.adm.icon ?? Icons.medication_rounded), color: l.skipped ? fg.withValues(alpha: .45) : C.lagoon),
        title: Text(t?.name ?? 'Terapi dihapus', style: TextStyle(fontWeight: FontWeight.w700, color: l.skipped ? fg.withValues(alpha: .55) : null)),
        subtitle: Text(l.note == null ? detail : '$detail\n${l.note}'),
        isThreeLine: l.note != null,
        onTap: () async {
          final ids = {for (final s in supplies) s.id};
          if (l.skipped) {
            if (await confirm(context, 'Batalkan "lewati" untuk dosis ini?', ok: 'Batalkan') && context.mounted) ref.read(repoProvider)?.deleteLog(l, ids);
          } else if (t != null) {
            showSheet(context, DoseSheet(t: t!, edit: l, supplies: supplies, prefs: prefs));
          } else if (await confirm(context, 'Terapi untuk catatan ini sudah dihapus. Hapus catatannya?') && context.mounted) {
            ref.read(repoProvider)?.deleteLog(l, ids);
          }
        },
      ),
    );
  }
}

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key, this.embedded = false});
  final bool embedded; // di dalam tab Kalender: tanpa judul sendiri

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
    final taken = logs.where((l) => !l.skipped).toList();
    final starts = [...taken.map((l) => l.at), ...ths.map((t) => t.start)]..sort();

    final rows = <Widget>[];
    DateTime? day;
    for (final l in logs) {
      if (day == null || !sameDay(day, l.at)) {
        day = l.at;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
          child: Text(DateFormat('EEEE, d MMMM y', 'id').format(l.at), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ));
      }
      rows.add(LogTile(l: l, t: byId[l.therapyId], supplies: supplies, prefs: prefs));
    }

    final add = pillButton('Catat', () => _add(context, ths, supplies, prefs, logs), icon: Icons.add_rounded);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      if (embedded)
        Align(alignment: Alignment.centerRight, child: add)
      else
        Row(children: [Expanded(child: Text('Riwayat', style: display(40))), add]),
      gap(14),
      if (prefs.hrtCounter && starts.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: cardBox(context),
          child: Row(children: [
            Icon(Icons.timelapse_rounded, color: C.peony, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hrtDuration(starts.first, DateTime.now()), style: display(24)),
                gap(6),
                Text('${taken.length} dosis tercatat'),
              ]),
            ),
          ]),
        ),
      if (logs.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Text('Belum ada catatan. Dosis yang kamu catat muncul di sini.')),
      ...rows,
    ]);
  }
}

class _Pick extends StatelessWidget {
  const _Pick(this.ths);
  final List<Therapy> ths;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Terapi mana?', style: display(28)),
        gap(16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in ths) ActionChip(avatar: Icon(t.adm.icon, size: 16), label: Text(t.name), onPressed: () => Navigator.pop(context, t)),
        ]),
      ]);
}
