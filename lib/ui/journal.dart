import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'body.dart';
import '../l10n.dart';

Color moodColor(String? k) => switch (k) {
      'happy' => C.lagoon,
      'calm' => Color.lerp(C.lagoon, Colors.white, .45)!,
      'low' => C.amber,
      'anxious' => const Color(0xFFE5675A),
      _ => const Color(0xFF9A98B8),
    };

/// Daftar jurnal dengan penyaring, dipakai di tab Kalender.
class JournalView extends ConsumerStatefulWidget {
  const JournalView({super.key});
  @override
  ConsumerState<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends ConsumerState<JournalView> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final all = <JournalEntry>[...(ref.watch(journalProvider).value ?? <JournalEntry>[])]..sort((a, b) => b.at.compareTo(a.at));
    final shown = all.where((e) => switch (filter) { 'mood' => e.hasMood, 'body' => e.hasBody, 'text' => e.hasText, _ => true }).toList();

    final rows = <Widget>[];
    DateTime? day;
    for (final e in shown) {
      if (day == null || !sameDay(day, e.at)) {
        day = e.at;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
          child: Text(DateFormat('EEEE, d MMMM y', L10n.code).format(e.at), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ));
      }
      rows.add(JournalTile(e: e));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      Align(alignment: Alignment.centerRight, child: pillButton(tr('Write'), () => showSheet(context, const JournalSheet()), icon: Icons.edit_outlined)),
      gap(12),
      Container(
        decoration: cardBox(context, radius: 22),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BodyPage())),
          leading: Icon(Icons.accessibility_new_rounded, color: C.peony),
          title: Text(tr('Body & changes'), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(tr('Timeline by body area')),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
      gap(12),
      PillTabs<String>(
        items: [('all', tr('All')), ('mood', tr('Mood')), ('body', tr('Body')), ('text', tr('Notes'))],
        value: filter,
        onChanged: (v) => setState(() => filter = v),
      ),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(tr('No entries yet. Log your mood, body changes, or anything you want to remember.')),
        ),
      ...rows,
    ]);
  }
}

class JournalTile extends StatelessWidget {
  const JournalTile({super.key, required this.e});
  final JournalEntry e;

  @override
  Widget build(BuildContext context) {
    final m = e.mood == null ? null : moods[e.mood];
    final title = (m == null ? null : tr(m.$1)) ?? (e.hasBody ? tr('Body changes') : tr('Notes'));
    final lines = [
      DateFormat('HH:mm').format(e.at),
      if (e.hasText) e.text!,
      for (final b in e.body.entries) '${tr(b.key)}: ${b.value}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: cardBox(context, radius: 22),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onTap: () => showSheet(context, JournalSheet(initial: e)),
        leading: CircleAvatar(
          backgroundColor: C.peony.withValues(alpha: .14),
          child: Icon(m?.$2 ?? (e.hasBody ? Icons.accessibility_new_rounded : Icons.edit_note_rounded), color: C.peony),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(lines.join('\n'), maxLines: 6, overflow: TextOverflow.ellipsis),
        isThreeLine: lines.length > 1,
      ),
    );
  }
}

/// Entri baru, atau ubah [initial]. [presetMood] mengisi suasana hati dari kartu di beranda.
class JournalSheet extends ConsumerStatefulWidget {
  const JournalSheet({super.key, this.initial, this.presetMood});
  final JournalEntry? initial;
  final String? presetMood;
  @override
  ConsumerState<JournalSheet> createState() => _JournalSheetState();
}

class _JournalSheetState extends ConsumerState<JournalSheet> {
  late String? mood = widget.initial?.mood ?? widget.presetMood;
  late DateTime at = widget.initial?.at ?? DateTime.now();
  late final text = TextEditingController(text: widget.initial?.text ?? '');
  late final Map<String, TextEditingController> ctrls = {
    for (final b in (widget.initial?.body ?? const <String, String>{}).entries) b.key: TextEditingController(text: b.value),
  };

  Future<void> _pick() async {
    final d = await showDatePicker(context: context, initialDate: at, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(at));
    if (t == null) return;
    setState(() => at = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _save() {
    final body = {
      for (final c in ctrls.entries)
        if (c.value.text.trim().isNotEmpty) c.key: c.value.text.trim(),
    };
    final note = text.text.trim();
    if (mood == null && body.isEmpty && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Fill in at least one: mood, body changes, or a note.'))));
      return;
    }
    final entry = JournalEntry(id: widget.initial?.id ?? '', at: at, mood: mood, body: body, text: note.isEmpty ? null : note);
    final repo = ref.read(repoProvider);
    if (widget.initial == null) {
      repo?.addJournal(entry);
    } else {
      repo?.updateJournal(entry);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Delete this journal entry?')) || !mounted) return;
    ref.read(repoProvider)?.deleteJournal(widget.initial!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? tr('Edit journal entry') : tr('New journal entry'), style: display(28)),
      gap(16),
      Text(tr('Mood')),
      gap(4),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final m in moods.entries)
          ChoiceChip(
            avatar: Icon(m.value.$2, size: 18),
            label: Text(tr(m.value.$1)),
            selected: mood == m.key,
            onSelected: (v) => setState(() => mood = v ? m.key : null),
          ),
      ]),
      gap(10),
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: Text(DateFormat('d MMM y, HH:mm', L10n.code).format(at)),
      ),
      gap(14),
      Text(tr('Body changes')),
      gap(4),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final a in bodyAreas)
          FilterChip(
            label: Text(tr(a)),
            selected: ctrls.containsKey(a),
            onSelected: (v) => setState(() {
              if (v) {
                ctrls[a] = TextEditingController();
              } else {
                ctrls.remove(a)?.dispose();
              }
            }),
          ),
      ]),
      for (final c in ctrls.entries) ...[
        gap(10),
        TextField(controller: c.value, decoration: InputDecoration(labelText: tr(c.key), hintText: tr('What do you feel or notice?'))),
      ],
      gap(14),
      TextField(controller: text, maxLines: 4, minLines: 2, decoration: InputDecoration(labelText: tr('Notes'))),
      gap(18),
      Row(children: [
        if (editing) TextButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded), label: Text(tr('Delete'))),
        Expanded(child: pillButton(editing ? tr('Save changes') : tr('Save'), _save)),
      ]),
    ]);
  }
}

/// Di beranda: satu ketukan untuk mencatat suasana hati hari ini.
class MoodQuickCard extends ConsumerWidget {
  const MoodQuickCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider).value ?? <JournalEntry>[];
    final now = DateTime.now();
    final today = entries.where((e) => e.hasMood && sameDay(e.at, now)).toList()..sort((a, b) => b.at.compareTo(a.at));
    final fg = Theme.of(context).colorScheme.onSurface;

    Widget card(Widget child) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: cardBox(context, radius: 24),
          child: child,
        );

    if (today.isNotEmpty) {
      final e = today.first, m = moods[e.mood]!;
      return card(InkWell(
        onTap: () => showSheet(context, JournalSheet(initial: e)),
        child: Row(children: [
          Icon(m.$2, color: C.peony, size: 30),
          const SizedBox(width: 14),
          Expanded(child: Text(tr('Today you feel {0}', [tr(m.$1).toLowerCase()]), style: const TextStyle(fontWeight: FontWeight.w600))),
          Icon(Icons.edit_outlined, size: 18, color: fg.withValues(alpha: .5)),
        ]),
      ));
    }
    return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('How are you feeling today?'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      gap(6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final m in moods.entries)
          Tooltip(
            message: tr(m.value.$1),
            child: IconButton(
              iconSize: 30,
              onPressed: () => showSheet(context, JournalSheet(presetMood: m.key)),
              icon: Icon(m.value.$2, color: fg.withValues(alpha: .7)),
            ),
          ),
      ]),
    ]));
  }
}
