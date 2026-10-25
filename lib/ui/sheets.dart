import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../sim.dart';
import '../theme.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Log new dose or edit existing entry [edit].
class DoseSheet extends ConsumerStatefulWidget {
  const DoseSheet({super.key, required this.t, required this.supplies, required this.prefs, this.slot, this.edit, this.suggested = ''});
  final Therapy t;
  final List<Supply> supplies;
  final Prefs prefs;
  final Slot? slot;
  final DoseLog? edit;
  final String suggested;
  @override
  ConsumerState<DoseSheet> createState() => _DoseSheetState();
}

class _DoseSheetState extends ConsumerState<DoseSheet> {
  late final amount = TextEditingController(text: fmt(widget.edit?.dose ?? widget.t.dose));
  late final wasted = TextEditingController(text: widget.edit?.wasted == null ? '' : fmt(widget.edit!.wasted!));
  late final dead = TextEditingController(text: widget.edit?.dead == null ? '' : fmt(widget.edit!.dead!));
  late final note = TextEditingController(text: widget.edit?.note ?? '');
  late DateTime at = widget.edit?.at ?? DateTime.now();
  late List<String> places = [...(widget.edit?.places ?? (widget.suggested.isEmpty ? <String>[] : [widget.suggested]))];
  late String injType = widget.edit?.injType ?? widget.t.injType ?? 'im';
  late String? supplyId = widget.supplies.any((s) => s.id == widget.t.supplyId) ? widget.t.supplyId : null;
  final generics = <String>{};

  Future<void> _pick() async {
    final d = await showDatePicker(context: context, initialDate: at, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(at));
    if (t == null) return;
    setState(() => at = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  double _consume(Supply s, double amt, double? w) {
    final unit = widget.t.doseUnit.trim().toLowerCase();
    final mass = ['mg', 'mcg', 'µg', 'ug', 'g'].contains(unit);
    final dpu = s.dosePerUnit;
    if (dpu != null && dpu > 0 && mass) return mgOf(amt, widget.t.doseUnit) / dpu + (w ?? 0);
    return s.perDose;
  }

  void _save() {
    final amt = parseNum(amount.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid dose amount.')));
      return;
    }
    final w = parseNum(wasted.text), dd = parseNum(dead.text);
    final usage = <String, double>{};
    if (widget.edit == null) {
      final s = widget.supplies.where((x) => x.id == supplyId).firstOrNull;
      if (s != null) usage[s.id] = _consume(s, amt, w);
      for (final g in generics) {
        usage[g] = 1;
      }
    }
    final t = widget.t;
    final log = DoseLog(
      id: widget.edit?.id ?? '',
      therapyId: t.id,
      at: at,
      places: t.adm.places ? places : const [],
      dose: amt,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
      wasted: w,
      dead: dd,
      injType: t.route == 'inj' ? injType : null,
      slot: widget.edit?.slot ?? (widget.slot == null ? null : slotKey(widget.slot!.at)),
      used: widget.edit?.used ?? usage,
    );
    final repo = ref.read(repoProvider);
    if (widget.edit == null) {
      repo?.logDose(log);
    } else {
      repo?.updateLog(log);
    }
    Navigator.pop(context);
  }

  void _skip() {
    final t = widget.t;
    final log = DoseLog(
      id: widget.edit?.id ?? '',
      therapyId: t.id,
      at: at,
      places: const [],
      dose: 0,
      note: note.text.trim().isEmpty ? 'Skipped' : '[Skipped] ${note.text.trim()}',
      slot: widget.edit?.slot ?? (widget.slot == null ? null : slotKey(widget.slot!.at)),
      used: const {},
    );
    final repo = ref.read(repoProvider);
    if (widget.edit != null) {
      repo?.updateLog(log);
    } else {
      repo?.logDose(log);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dose marked as skipped.')));
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Delete this entry? Used supplies will be restored.', ok: 'Delete') || !mounted) return;
    ref.read(repoProvider)?.deleteLog(widget.edit!, {for (final s in widget.supplies) s.id});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t, editing = widget.edit != null;
    final meds = widget.supplies.where((s) => !s.generic).toList();
    final gens = widget.supplies.where((s) => s.generic).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? 'Edit Record' : (t.route == 'inj' ? 'Log Injection' : 'Log Dose'), style: display(28)),
      gap(4),
      Text(widget.slot == null ? t.name : '${t.name}, schedule ${DateFormat('HH:mm').format(widget.slot!.at)}'),
      gap(16),
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Dose Amount (${t.doseUnit})')),
      gap(10),
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: Text('Time: ${DateFormat('d MMM, HH:mm', 'en').format(at)}'),
      ),
      if (t.adm.places && widget.prefs.places.isNotEmpty) ...[
        gap(14),
        const Text('Injection/Patch Site'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final p in widget.prefs.places)
            FilterChip(
              label: Text(translatePlace(p)),
              selected: places.contains(p),
              onSelected: (v) => setState(() => v ? places.add(p) : places.remove(p)),
            ),
        ]),
      ],
      if (t.route == 'inj') ...[
        gap(8),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Intramuscular (IM)'), selected: injType == 'im', onSelected: (_) => setState(() => injType = 'im')),
          ChoiceChip(label: const Text('Subcutaneous (SC)'), selected: injType == 'sc', onSelected: (_) => setState(() => injType = 'sc')),
        ]),
      ],
      if (!editing && meds.isNotEmpty) ...[
        gap(14),
        const Text('Deduct from supply'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: const Text('None'), selected: supplyId == null, onSelected: (_) => setState(() => supplyId = null)),
          for (final s in meds) ChoiceChip(label: Text(s.name), selected: supplyId == s.id, onSelected: (_) => setState(() => supplyId = s.id)),
        ]),
      ],
      if (!editing && gens.isNotEmpty) ...[
        gap(8),
        const Text('Tools used (1 each)'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in gens)
            FilterChip(
              avatar: Icon(genericTypes[s.gtype]?.$2 ?? Icons.inventory_2_rounded, size: 16),
              label: Text(s.name),
              selected: generics.contains(s.id),
              onSelected: (v) => setState(() => v ? generics.add(s.id) : generics.remove(s.id)),
            ),
        ]),
      ],
      ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        title: const Text('Advanced Settings'),
        children: [
          if (t.route == 'inj') ...[
            TextField(controller: wasted, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Wasted (mL)')),
            gap(10),
            TextField(controller: dead, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Needle dead space (µL)')),
            gap(10),
          ],
          TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
          gap(8),
        ],
      ),
      gap(12),
      Row(children: [
        if (editing) TextButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Delete')),
        if (!editing) ...[
          OutlinedButton(onPressed: _skip, child: const Text('Skip')),
          const SizedBox(width: 8),
        ],
        Expanded(child: pillButton(editing ? 'Save Changes' : 'Log Dose', _save)),
      ]),
    ]);
  }
}

const _mols = [('estradiol', 'Estradiol'), ('testosterone', 'Testosterone'), ('progesterone', 'Progesterone'), ('other', 'Other Medication')];
const _kinds = [('interval', 'Every N Days'), ('weekly', 'Weekly'), ('monthly', 'Monthly'), ('asneeded', 'As Needed')];

/// New or Edit Therapy
class TherapySheet extends ConsumerStatefulWidget {
  const TherapySheet({super.key, required this.supplies, this.initial});
  final List<Supply> supplies;
  final Therapy? initial;
  @override
  ConsumerState<TherapySheet> createState() => _TherapySheetState();
}

class _TherapySheetState extends ConsumerState<TherapySheet> {
  late String hormone = widget.initial?.hormoneId ?? 'estradiol';
  late String route = widget.initial?.route ?? 'inj';
  late String kind = widget.initial?.kind ?? 'interval';
  late String? pk = widget.initial == null ? 'e2_enanthate' : widget.initial!.pk;
  late String injType = widget.initial?.injType ?? 'im';
  late bool rolling = widget.initial?.rolling ?? true;
  late String? supplyId = widget.initial?.supplyId;
  late DateTime day = widget.initial?.start ?? DateUtils.dateOnly(DateTime.now());
  late List<int> weekdays = [...?widget.initial?.weekdays];
  late List<String> times = [...(widget.initial?.times ?? const ['09:00'])];
  late final name = TextEditingController(text: widget.initial?.name ?? '');
  late final dose = TextEditingController(text: widget.initial == null ? '' : fmt(widget.initial!.dose));
  late final unit = TextEditingController(text: widget.initial?.doseUnit ?? 'mg');
  late final every = TextEditingController(text: '${widget.initial?.everyDays ?? 7}');
  late final monthDay = TextEditingController(text: '${widget.initial?.monthDay ?? 1}');

  String? _defaultPk() => hormone == 'estradiol' ? (route == 'inj' ? 'e2_enanthate' : (route == 'oral' ? 'e2_oral' : null)) : null;

  void _setRoute(String r) => setState(() {
        route = r;
        pk = _defaultPk();
        if (widget.initial == null) {
          every.text = switch (r) { 'inj' => '7', 'patch' => '3', 'implant' => '90', _ => '1' };
        }
        if (r == 'patch' && unit.text.trim() == 'mg') unit.text = 'µg/day';
        if (r != 'patch' && unit.text.trim() == 'µg/day') unit.text = 'mg';
      });

  Future<void> _addTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (t == null || !mounted) return;
    final s = '${two(t.hour)}:${two(t.minute)}';
    if (!times.contains(s)) setState(() => times = [...times, s]..sort());
  }

  void _err(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  void _save() {
    final d = parseNum(dose.text), e = int.tryParse(every.text) ?? 0, md = int.tryParse(monthDay.text) ?? 0;
    if (d == null || d <= 0) return _err('Please enter dose amount.');
    if (kind == 'interval' && e < 1) return _err('Repeat interval must be at least 1 day.');
    if (kind == 'weekly' && weekdays.isEmpty) return _err('Select at least one day.');
    if (kind == 'monthly' && (md < 1 || md > 31)) return _err('Date must be between 1 and 31.');
    if (kind != 'asneeded' && times.isEmpty) return _err('Add at least one time.');
    final fallback = hormone == 'other' ? 'Medication' : presetOf(hormone).name;
    final t = Therapy(
      id: widget.initial?.id ?? '',
      hormoneId: hormone,
      name: name.text.trim().isEmpty ? fallback : name.text.trim(),
      dose: d,
      doseUnit: unit.text.trim().isEmpty ? 'mg' : unit.text.trim(),
      start: day,
      everyDays: kind == 'interval' ? e : 1,
      rolling: kind == 'interval' && e > 1 && rolling,
      supplyId: supplyId,
      route: route,
      pk: hormone == 'estradiol' ? pk : null,
      kind: kind,
      weekdays: weekdays,
      monthDay: md < 1 ? 1 : md,
      times: kind == 'asneeded' ? const ['09:00'] : times,
      injType: route == 'inj' ? injType : null,
    );
    final repo = ref.read(repoProvider);
    if (widget.initial == null) {
      repo?.addTherapy(t);
    } else {
      repo?.updateTherapy(t);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Delete this therapy? Recorded dose logs will remain saved.') || !mounted) return;
    ref.read(repoProvider)?.deleteTherapy(widget.initial!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final meds = widget.supplies.where((s) => !s.generic).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? 'Edit Therapy' : 'New Therapy', style: display(28)),
      gap(16),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final m in _mols)
          ChoiceChip(
            label: Text(m.$2),
            selected: hormone == m.$1,
            onSelected: (_) => setState(() {
              hormone = m.$1;
              pk = _defaultPk();
            }),
          ),
      ]),
      gap(8),
      const Text('Route'),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final r in routes) ChoiceChip(avatar: Icon(r.icon, size: 16), label: Text(r.label), selected: route == r.id, onSelected: (_) => _setRoute(r.id)),
      ]),
      if (hormone == 'estradiol' && (route == 'inj' || route == 'oral')) ...[
        gap(8),
        Text(route == 'oral' ? 'Simulation Profile:' : 'Estradiol Ester (for level simulation):'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final p in pkProfiles.where((p) => p.oral == (route == 'oral')))
            ChoiceChip(label: Text(p.name), selected: pk == p.id, onSelected: (_) => setState(() => pk = p.id)),
          ChoiceChip(label: const Text('No simulation'), selected: pk == null, onSelected: (_) => setState(() => pk = null)),
        ]),
      ],
      if (route == 'inj') ...[
        gap(8),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Intramuscular (IM)'), selected: injType == 'im', onSelected: (_) => setState(() => injType = 'im')),
          ChoiceChip(label: const Text('Subcutaneous (SC)'), selected: injType == 'sc', onSelected: (_) => setState(() => injType = 'sc')),
        ]),
      ],
      gap(12),
      TextField(controller: name, decoration: InputDecoration(labelText: hormone == 'other' ? 'Medication name' : 'Medication name (e.g. ${presetOf(hormone).name} valerate)')),
      gap(10),
      Row(children: [
        Expanded(flex: 2, child: TextField(controller: dose, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Dose'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit'))),
      ]),
      if (route == 'patch') ...[
        gap(8),
        Wrap(spacing: 8, children: [
          for (final u in const ['mg', 'µg/day'])
            ChoiceChip(
              label: Text(u == 'mg' ? 'Mass Dose (mg)' : 'Release Rate (µg/day)'),
              selected: unit.text.trim() == u,
              onSelected: (_) => setState(() => unit.text = u),
            ),
        ]),
      ],
      gap(14),
      const Text('Schedule'),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final k in _kinds) ChoiceChip(label: Text(k.$2), selected: kind == k.$1, onSelected: (_) => setState(() {
              kind = k.$1;
              if (kind == 'weekly' && weekdays.isEmpty) weekdays = [DateTime.now().weekday];
            })),
      ]),
      if (kind == 'interval') ...[
        gap(8),
        TextField(
          controller: every,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Repeat interval (days), 1 = daily'),
        ),
        if ((int.tryParse(every.text) ?? 1) > 1)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Calculate from last dose'),
            subtitle: const Text('Next schedule follows when you last logged a dose, not the start date.'),
            value: rolling,
            onChanged: (v) => setState(() => rolling = v),
          ),
      ],
      if (kind == 'weekly') ...[
        gap(8),
        Wrap(spacing: 8, children: [
          for (var i = 1; i <= 7; i++)
            FilterChip(label: Text(_dayNames[i - 1]), selected: weekdays.contains(i), onSelected: (v) => setState(() => v ? weekdays.add(i) : weekdays.remove(i))),
        ]),
      ],
      if (kind == 'monthly') ...[
        gap(8),
        TextField(controller: monthDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Day of month (1 to 31)')),
      ],
      if (kind != 'asneeded') ...[
        gap(8),
        const Text('Time'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in times) InputChip(label: Text(s), onDeleted: times.length > 1 ? () => setState(() => times.remove(s)) : null),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 16), label: const Text('Add time'), onPressed: _addTime),
        ]),
        gap(10),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: day, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (d != null) setState(() => day = d);
          },
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text('Start date: ${DateFormat('d MMM y', 'en').format(day)}'),
        ),
      ],
      if (meds.isNotEmpty) ...[
        gap(12),
        const Text('Deduct supply from:'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: const Text('None'), selected: supplyId == null, onSelected: (_) => setState(() => supplyId = null)),
          for (final s in meds) ChoiceChip(label: Text(s.name), selected: supplyId == s.id, onSelected: (_) => setState(() => supplyId = s.id)),
        ]),
      ],
      gap(20),
      Row(children: [
        if (editing) TextButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Delete')),
        Expanded(child: pillButton(editing ? 'Save Changes' : 'Save Therapy', _save)),
      ]),
    ]);
  }
}
