import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../sim.dart';
import '../theme.dart';
import '../l10n.dart';
import 'guided_injection.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _mols = [
  ('estradiol', 'Estradiol'),
  ('testosterone', 'Testosterone'),
  ('progesterone', 'Progesterone'),
  ('blocker', 'Anti-androgen (Blocker)'),
  ('other', 'Other medication'),
];

/// Catat dosis baru (dari jadwal [slot] atau tambahan) atau ubah catatan [edit].
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
  late final secondaryAmount = TextEditingController(
    text: fmt(widget.edit?.secondaryDose ?? widget.t.secondaryDose ?? 0),
  );
  late final secondaryUnit = TextEditingController(text: widget.t.secondaryDoseUnit ?? 'mg');
  late final wasted = TextEditingController(text: widget.edit?.wasted == null ? '' : fmt(widget.edit!.wasted!));
  late final dead = TextEditingController(text: widget.edit?.dead == null ? '' : fmt(widget.edit!.dead!));
  late final note = TextEditingController(text: widget.edit?.note ?? '');
  late DateTime at = widget.edit?.at ?? DateTime.now();
  late List<String> places = [...(widget.edit?.places ?? (widget.suggested.isEmpty ? <String>[] : [widget.suggested]))];
  late String injType = widget.edit?.injType ?? widget.t.injType ?? 'im';
  late String? supplyId = widget.supplies.any((s) => s.id == widget.t.supplyId) ? widget.t.supplyId : null;
  final generics = <String>{};

  late bool isCombination = widget.t.secondaryHormoneId != null || widget.edit?.secondaryDose != null;
  late String secondaryHormone = widget.t.secondaryHormoneId ?? (widget.t.hormoneId == 'estradiol' ? 'progesterone' : 'estradiol');
  late String? secondaryCompound = widget.t.secondaryCompound;
  late String? secondaryPk = widget.t.secondaryPk ?? (widget.t.secondaryHormoneId != null ? null : _defaultPk(secondaryHormone));
  bool saveToTherapy = true;

  String? _defaultPk([String? h]) {
    final targetH = h ?? secondaryHormone;
    return switch (targetH) {
      'estradiol' => widget.t.route == 'inj' ? 'e2_enanthate' : (widget.t.route == 'oral' ? 'e2_oral' : null),
      'testosterone' => widget.t.route == 'inj' ? 't_enanthate' : (widget.t.route == 'gel' ? 't_gel' : null),
      'progesterone' => widget.t.route == 'inj' ? 'mpa_susp' : (widget.t.route == 'oral' ? 'p4_oral' : (widget.t.route == 'supp' ? 'p4_rectal' : null)),
      _ => null,
    };
  }

  void _selectSecondaryCompound(CompoundPreset c) {
    setState(() {
      secondaryCompound = c.id;
      secondaryPk = c.pk ?? _defaultPk(secondaryHormone);
      if (secondaryAmount.text.trim().isEmpty || secondaryAmount.text.trim() == '0') {
        if (c.defaultDose != null) secondaryAmount.text = fmt(c.defaultDose!);
      }
      if (c.defaultUnit.isNotEmpty) secondaryUnit.text = c.defaultUnit;
    });
  }

  @override
  void dispose() {
    amount.dispose();
    secondaryAmount.dispose();
    secondaryUnit.dispose();
    wasted.dispose();
    dead.dispose();
    note.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Enter the dose amount.'))));
      return;
    }
    double? secAmt;
    if (isCombination) {
      secAmt = parseNum(secondaryAmount.text);
      if (secAmt == null || secAmt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Enter a dose for the second active ingredient.'))),
        );
        return;
      }
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
      secondaryDose: isCombination ? secAmt : null,
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

    if (isCombination && (t.secondaryHormoneId == null || t.secondaryHormoneId != secondaryHormone)) {
      if (saveToTherapy) {
        final secUnitStr = secondaryUnit.text.trim().isEmpty ? 'mg' : secondaryUnit.text.trim();
        final updatedTherapy = t.copy(
          secondaryHormoneId: secondaryHormone,
          secondaryDose: secAmt,
          secondaryDoseUnit: secUnitStr,
          secondaryPk: secondaryPk,
          secondaryCompound: secondaryCompound,
        );
        repo?.updateTherapy(updatedTherapy);
      }
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Delete this entry? Supplies used will be returned to stock.')) || !mounted) return;
    ref.read(repoProvider)?.deleteLog(widget.edit!, {for (final s in widget.supplies) s.id});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t, editing = widget.edit != null;
    final fg = Theme.of(context).colorScheme.onSurface;
    final meds = widget.supplies.where((s) => !s.generic).toList();
    final gens = widget.supplies.where((s) => s.generic).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(editing ? tr('Edit entry') : (t.route == 'inj' ? tr('Log injection') : tr('Log dose')), style: display(28)),
                gap(4),
                Text(widget.slot == null ? t.name : tr('{0}, scheduled {1}', [t.name, DateFormat('HH:mm').format(widget.slot!.at)])),
              ],
            ),
          ),
          if (!editing)
            IconButton(
              tooltip: tr('Edit therapy settings'),
              icon: const Icon(Icons.tune_rounded, color: C.lavender, size: 22),
              onPressed: () {
                Navigator.pop(context);
                showSheet(context, TherapySheet(supplies: widget.supplies, initial: widget.t));
              },
            ),
        ],
      ),
      gap(16),
      TextField(
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: isCombination
              ? tr('{0} dose ({1})', [presetOf(t.hormoneId).name, t.doseUnit])
              : tr('Dose ({0})', [t.doseUnit]),
          prefixIcon: const Icon(Icons.medication_rounded, size: 20, color: C.lavender),
          helperText: t.compound != null ? compoundPresets.where((p) => p.id == t.compound).firstOrNull?.name : null,
        ),
      ),
      if (isCombination) ...[
        gap(10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.deepCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.lavender.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.biotech_outlined, size: 18, color: C.lavender),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Combination medication'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                  ),
                  if (t.secondaryHormoneId == null)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => isCombination = false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          tr('Remove'),
                          style: TextStyle(fontSize: 12, color: Pastel.rose.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
              if (t.secondaryHormoneId == null) ...[
                gap(8),
                DropdownButtonFormField<String>(
                  key: ValueKey('doseSheetSecHormone-$secondaryHormone'),
                  initialValue: secondaryHormone,
                  dropdownColor: C.deepCard,
                  borderRadius: BorderRadius.circular(16),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
                  decoration: InputDecoration(
                    labelText: tr('Second active category'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    for (final m in _mols.where((m) => m.$1 != t.hormoneId && m.$1 != 'other'))
                      DropdownMenuItem<String>(
                        value: m.$1,
                        child: Text(tr(m.$2), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null && val != secondaryHormone) {
                      setState(() {
                        secondaryHormone = val;
                        secondaryCompound = null;
                        secondaryPk = _defaultPk(secondaryHormone);
                      });
                    }
                  },
                ),
                Builder(builder: (context) {
                  final secAvailable = compoundsFor(secondaryHormone);
                  if (secAvailable.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey('doseSheetSecCompound-$secondaryHormone-$secondaryCompound'),
                      initialValue: secondaryCompound ?? 'custom',
                      dropdownColor: C.deepCard,
                      borderRadius: BorderRadius.circular(16),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
                      decoration: InputDecoration(
                        labelText: tr('Second active compound:'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        for (final c in secAvailable)
                          DropdownMenuItem<String?>(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 14))),
                        DropdownMenuItem<String?>(value: 'custom', child: Text(tr('Custom / Other'), style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))),
                      ],
                      onChanged: (val) {
                        if (val == null || val == 'custom') {
                          setState(() => secondaryCompound = 'custom');
                        } else {
                          final c = secAvailable.firstWhere((item) => item.id == val);
                          _selectSecondaryCompound(c);
                        }
                      },
                    ),
                  );
                }),
              ],
              gap(8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: secondaryAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr('{0} dose', [presetOf(secondaryHormone).name]),
                        helperText: secondaryCompound != null && secondaryCompound != 'custom'
                            ? compoundPresets.where((p) => p.id == secondaryCompound).firstOrNull?.name
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: secondaryUnit,
                      decoration: InputDecoration(
                        labelText: tr('Unit'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (t.secondaryHormoneId == null) ...[
                gap(6),
                InkWell(
                  onTap: () => setState(() => saveToTherapy = !saveToTherapy),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: saveToTherapy,
                          activeColor: C.lavender,
                          onChanged: (v) => setState(() => saveToTherapy = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('Save combination settings to therapy'),
                          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.85)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ] else if (!editing) ...[
        gap(8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            isCombination = true;
            secondaryPk ??= _defaultPk(secondaryHormone);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: C.lavender.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.lavender.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 16, color: C.lavender),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tr('Add combination medication (second active ingredient)'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.lavender),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      gap(10),
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: Text(tr('Time: {0}', [DateFormat('d MMM, HH:mm', L10n.code).format(at)])),
      ),
      if (t.adm.places && widget.prefs.places.isNotEmpty) ...[
        gap(14),
        Text(tr('Site'), style: const TextStyle(fontWeight: FontWeight.w700)),
        gap(6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final p in widget.prefs.places)
            FilterChip(
              label: Text(tr(p)),
              selected: places.contains(p),
              onSelected: (v) => setState(() => v ? places.add(p) : places.remove(p)),
            ),
        ]),
      ],
      if (t.route == 'inj') ...[
        gap(8),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: Text(tr('Intramuscular (IM)')), selected: injType == 'im', onSelected: (_) => setState(() => injType = 'im')),
          ChoiceChip(label: Text(tr('Subcutaneous (SC)')), selected: injType == 'sc', onSelected: (_) => setState(() => injType = 'sc')),
        ]),
        if (!editing) ...[
          gap(10),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CalmInjectionSheet(
                  t: t,
                  slot: widget.slot,
                  supplies: widget.supplies,
                  prefs: widget.prefs,
                  suggestedPlace: widget.suggested,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: C.peony.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.peony.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement_rounded, color: C.peony, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Need guidance? Try Guided Calm Injection'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(tr('Interactive step-by-step breathing, prep, and slow injection guide.'), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: C.peony.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ],
      if (!editing && meds.isNotEmpty) ...[
        gap(14),
        Text(tr('Deduct from medication supply')),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: Text(tr('No supply')), selected: supplyId == null, onSelected: (_) => setState(() => supplyId = null)),
          for (final s in meds) ChoiceChip(label: Text(s.name), selected: supplyId == s.id, onSelected: (_) => setState(() => supplyId = s.id)),
        ]),
      ],
      if (!editing && gens.isNotEmpty) ...[
        gap(8),
        Text(tr('Supplies used (1 each)')),
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
      if (editing) ...[
        gap(10),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: tr('Note (optional)'),
            prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: C.lavender),
          ),
        ),
      ] else ...[
        ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: EdgeInsets.zero,
          title: Text(tr('Advanced')),
          children: [
            if (t.route == 'inj') ...[
              TextField(controller: wasted, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr('Wasted (mL)'))),
              gap(10),
              TextField(controller: dead, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr('Needle dead space (µL)'))),
              gap(10),
            ],
            TextField(controller: note, maxLines: 2, decoration: InputDecoration(labelText: tr('Notes'))),
            gap(8),
          ],
        ),
      ],
      gap(14),
      Row(children: [
        if (editing)
          TextButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: Text(tr('Delete')),
            style: TextButton.styleFrom(foregroundColor: Pastel.rose),
          ),
        if (editing) const SizedBox(width: 8),
        Expanded(child: pillButton(editing ? tr('Save changes') : tr('Save'), _save)),
      ]),
    ]);
  }
}

const _kinds = [('interval', 'Every N days'), ('weekly', 'Weekly'), ('monthly', 'Monthly'), ('asneeded', 'As needed')];

/// Terapi baru, atau ubah [initial].
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
  late String? compound = widget.initial == null ? null : (widget.initial!.compound ?? 'custom');
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

  late bool isCombination = widget.initial?.secondaryHormoneId != null;
  late String secondaryHormone = widget.initial?.secondaryHormoneId ?? (hormone == 'estradiol' ? 'progesterone' : 'estradiol');
  late String? secondaryCompound = widget.initial?.secondaryHormoneId == null ? null : (widget.initial!.secondaryCompound ?? 'custom');
  late final secondaryDose = TextEditingController(text: widget.initial?.secondaryDose == null ? '' : fmt(widget.initial!.secondaryDose!));
  late final secondaryUnit = TextEditingController(text: widget.initial?.secondaryDoseUnit ?? 'mg');
  late String? secondaryPk = widget.initial?.secondaryPk ?? (widget.initial?.secondaryHormoneId != null ? null : _defaultPk(widget.initial?.secondaryHormoneId ?? 'progesterone'));

  String? _defaultPk([String? h]) {
    final targetH = h ?? hormone;
    return switch (targetH) {
      'estradiol' => route == 'inj' ? 'e2_enanthate' : (route == 'oral' ? 'e2_oral' : null),
      'testosterone' => route == 'inj' ? 't_enanthate' : (route == 'gel' ? 't_gel' : null),
      'progesterone' => route == 'inj' ? 'mpa_susp' : (route == 'oral' ? 'p4_oral' : (route == 'supp' ? 'p4_rectal' : null)),
      _ => null,
    };
  }

  void _selectCompound(CompoundPreset c) {
    setState(() {
      compound = c.id;
      route = c.defaultRoute;
      pk = c.pk ?? _defaultPk();
      if (name.text.trim().isEmpty || compoundPresets.any((p) => p.name == name.text.trim() || p.en == name.text.trim())) {
        name.text = c.name;
      }
      if (dose.text.trim().isEmpty && c.defaultDose != null) {
        dose.text = fmt(c.defaultDose!);
        unit.text = c.defaultUnit;
      }
    });
  }

  void _selectSecondaryCompound(CompoundPreset c) {
    setState(() {
      secondaryCompound = c.id;
      secondaryPk = c.pk ?? _defaultPk(secondaryHormone);
      if (secondaryDose.text.trim().isEmpty && c.defaultDose != null) {
        secondaryDose.text = fmt(c.defaultDose!);
        secondaryUnit.text = c.defaultUnit;
      }
    });
  }

  void _setRoute(String r) => setState(() {
        route = r;
        pk = _defaultPk();
        if (isCombination) secondaryPk = _defaultPk(secondaryHormone);
        if (widget.initial == null) {
          every.text = switch (r) { 'inj' => '7', 'patch' => '3', 'implant' => '90', _ => '1' };
        }
        if (r == 'patch' && unit.text.trim() == 'mg') unit.text = tr('µg/day');
        if (r != 'patch' && unit.text.trim() == tr('µg/day')) unit.text = 'mg';
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
    if (d == null || d <= 0) return _err(tr('Enter a dose.'));
    final secD = isCombination ? parseNum(secondaryDose.text) : null;
    if (isCombination && (secD == null || secD <= 0)) {
      return _err(tr('Enter a dose for the second active ingredient.'));
    }
    if (kind == 'interval' && e < 1) return _err(tr('Repeat interval must be at least 1 day.'));
    if (kind == 'weekly' && weekdays.isEmpty) return _err(tr('Pick at least one day.'));
    if (kind == 'monthly' && (md < 1 || md > 31)) return _err(tr('Day must be 1 to 31.'));
    if (kind != 'asneeded' && times.isEmpty) return _err(tr('Add at least one time.'));
    final fallback = hormone == 'other' ? tr('Medication') : presetOf(hormone).name;
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
      pk: pk,
      kind: kind,
      weekdays: weekdays,
      monthDay: md < 1 ? 1 : md,
      times: kind == 'asneeded' ? const ['09:00'] : times,
      injType: route == 'inj' ? injType : null,
      secondaryHormoneId: isCombination ? secondaryHormone : null,
      secondaryDose: isCombination ? secD : null,
      secondaryDoseUnit: isCombination ? (secondaryUnit.text.trim().isEmpty ? 'mg' : secondaryUnit.text.trim()) : null,
      secondaryPk: isCombination ? secondaryPk : null,
      compound: (compound == null || compound == 'custom') ? null : compound,
      secondaryCompound: isCombination ? ((secondaryCompound == null || secondaryCompound == 'custom') ? null : secondaryCompound) : null,
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
    if (!await confirm(context, tr('Delete this therapy? Its dose history is kept.')) || !mounted) return;
    ref.read(repoProvider)?.deleteTherapy(widget.initial!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final meds = widget.supplies.where((s) => !s.generic).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? tr('Edit therapy') : tr('New therapy'), style: display(28)),
      gap(16),
      DropdownButtonFormField<String>(
        key: ValueKey('hormone-$hormone'),
        initialValue: hormone,
        dropdownColor: C.deepCard,
        borderRadius: BorderRadius.circular(16),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
        decoration: InputDecoration(
          labelText: tr('Therapy category'),
          prefixIcon: const Icon(Icons.category_outlined, size: 20, color: C.lavender),
        ),
        items: [
          for (final m in _mols)
            DropdownMenuItem<String>(
              value: m.$1,
              child: Text(
                tr(m.$2),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
        onChanged: (val) {
          if (val != null && val != hormone) {
            setState(() {
              hormone = val;
              compound = null;
              pk = _defaultPk();
              if (secondaryHormone == hormone) {
                secondaryHormone = hormone == 'estradiol' ? 'progesterone' : 'estradiol';
                secondaryCompound = null;
                secondaryPk = _defaultPk(secondaryHormone);
              }
            });
          }
        },
      ),
      Builder(builder: (context) {
        final available = compoundsFor(hormone);
        if (available.isEmpty) return const SizedBox.shrink();
        final selectedVal = (compound != null && (compound == 'custom' || available.any((c) => c.id == compound))) ? compound : null;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            key: ValueKey('$hormone-$compound'),
            initialValue: selectedVal,
            dropdownColor: C.deepCard,
            borderRadius: BorderRadius.circular(16),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
            hint: Text(tr('Select active compound'), style: const TextStyle(fontSize: 14)),
            decoration: InputDecoration(
              labelText: tr('Active compound'),
              prefixIcon: const Icon(Icons.science_outlined, size: 20, color: C.lavender),
            ),
            items: [
              for (final c in available)
                DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              DropdownMenuItem<String>(
                value: 'custom',
                child: Text(
                  tr('Custom / Other'),
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            onChanged: (val) {
              if (val == null || val == 'custom') {
                setState(() => compound = 'custom');
              } else {
                final c = available.firstWhere((item) => item.id == val);
                _selectCompound(c);
              }
            },
          ),
        );
      }),
      gap(12),
      TextField(
        controller: name,
        decoration: InputDecoration(
          labelText: tr('Product / medication name'),
          hintText: tr('e.g. brand on packaging (Progynova, Cyclofem, Androcur)'),
          helperText: tr('You can enter your packaging brand or keep the compound name.'),
        ),
      ),
      gap(12),
      DropdownButtonFormField<String>(
        key: ValueKey('route-$route'),
        initialValue: route,
        dropdownColor: C.deepCard,
        borderRadius: BorderRadius.circular(16),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
        decoration: InputDecoration(
          labelText: tr('How it\'s taken'),
          prefixIcon: Icon(routeOf(route).icon, size: 20, color: C.lavender),
        ),
        items: [
          for (final r in routes)
            DropdownMenuItem<String>(
              value: r.id,
              child: Row(
                children: [
                  Icon(r.icon, size: 18, color: C.lavender),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr(r.label), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
        ],
        onChanged: (val) {
          if (val != null) _setRoute(val);
        },
      ),
      Builder(builder: (_) {
        if (compound != null && compound != 'custom') return const SizedBox.shrink();
        final matchingPk = pkProfilesFor(hormone, route);
        if (matchingPk.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: DropdownButtonFormField<String?>(
            key: ValueKey('pk-$hormone-$route-$pk'),
            initialValue: pk,
            dropdownColor: C.deepCard,
            borderRadius: BorderRadius.circular(16),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
            decoration: InputDecoration(
              labelText: route == 'inj' ? tr('Ester / simulation profile ({0}):', [presetOf(hormone).name]) : tr('Simulation profile ({0}):', [presetOf(hormone).name]),
              prefixIcon: const Icon(Icons.auto_graph_rounded, size: 20, color: C.lavender),
            ),
            items: [
              for (final p in matchingPk)
                DropdownMenuItem<String?>(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 14))),
              DropdownMenuItem<String?>(value: null, child: Text(tr('No simulation'), style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))),
            ],
            onChanged: (val) => setState(() => pk = val),
          ),
        );
      }),
      if (route == 'inj') ...[
        gap(10),
        DropdownButtonFormField<String>(
          key: ValueKey('inj-$injType'),
          initialValue: injType,
          dropdownColor: C.deepCard,
          borderRadius: BorderRadius.circular(16),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
          decoration: InputDecoration(
            labelText: tr('Injection method'),
            prefixIcon: const Icon(Icons.vaccines_rounded, size: 20, color: C.lavender),
          ),
          items: [
            DropdownMenuItem(value: 'im', child: Text(tr('Intramuscular (IM)'), style: const TextStyle(fontSize: 14))),
            DropdownMenuItem(value: 'sc', child: Text(tr('Subcutaneous (SC)'), style: const TextStyle(fontSize: 14))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => injType = val);
          },
        ),
      ],
      gap(10),
      Row(children: [
        Expanded(flex: 2, child: TextField(controller: dose, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr('Dose')))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: unit, decoration: InputDecoration(labelText: tr('Unit')))),
      ]),
      if (route == 'patch') ...[
        gap(10),
        DropdownButtonFormField<String>(
          key: ValueKey('patchUnit-${unit.text.trim()}'),
          initialValue: unit.text.trim() == 'mg' ? 'mg' : tr('µg/day'),
          dropdownColor: C.deepCard,
          borderRadius: BorderRadius.circular(16),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
          decoration: InputDecoration(
            labelText: tr('Dose unit type'),
            prefixIcon: const Icon(Icons.layers_rounded, size: 20, color: C.lavender),
          ),
          items: [
            DropdownMenuItem(value: 'mg', child: Text(tr('Mass dose (mg)'), style: const TextStyle(fontSize: 14))),
            DropdownMenuItem(value: tr('µg/day'), child: Text(tr('Release rate (µg/day)'), style: const TextStyle(fontSize: 14))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => unit.text = val);
          },
        ),
      ],
      gap(8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr('Combination medication')),
        subtitle: Text(tr('Contains a 2nd active ingredient (e.g. Cyclofem with Estradiol + Progestin)')),
        value: isCombination,
        onChanged: (v) => setState(() {
          isCombination = v;
          if (v && secondaryPk == null) {
            secondaryPk = _defaultPk(secondaryHormone);
          }
        }),
      ),
      if (isCombination) ...[
        gap(8),
        DropdownButtonFormField<String>(
          key: ValueKey('secHormone-$secondaryHormone'),
          initialValue: secondaryHormone,
          dropdownColor: C.deepCard,
          borderRadius: BorderRadius.circular(16),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
          decoration: InputDecoration(
            labelText: tr('Second active category'),
            prefixIcon: const Icon(Icons.biotech_outlined, size: 20, color: C.lavender),
          ),
          items: [
            for (final m in _mols.where((m) => m.$1 != hormone && m.$1 != 'other'))
              DropdownMenuItem<String>(
                value: m.$1,
                child: Text(
                  tr(m.$2),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
          onChanged: (val) {
            if (val != null && val != secondaryHormone) {
              setState(() {
                secondaryHormone = val;
                secondaryCompound = null;
                secondaryPk = _defaultPk(secondaryHormone);
              });
            }
          },
        ),
        Builder(builder: (context) {
          final secAvailable = compoundsFor(secondaryHormone);
          if (secAvailable.isEmpty) return const SizedBox.shrink();
          final secSelectedVal = (secondaryCompound != null && (secondaryCompound == 'custom' || secAvailable.any((c) => c.id == secondaryCompound))) ? secondaryCompound : null;
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DropdownButtonFormField<String>(
              key: ValueKey('$secondaryHormone-$secondaryCompound'),
              initialValue: secSelectedVal,
              dropdownColor: C.deepCard,
              borderRadius: BorderRadius.circular(16),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
              hint: Text(tr('Select active compound'), style: const TextStyle(fontSize: 14)),
              decoration: InputDecoration(
                labelText: tr('Second active compound'),
                prefixIcon: const Icon(Icons.biotech_outlined, size: 20, color: C.lavender),
              ),
              items: [
                for (final c in secAvailable)
                  DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      c.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                DropdownMenuItem<String>(
                  value: 'custom',
                  child: Text(
                    tr('Custom / Other'),
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == null || val == 'custom') {
                  setState(() => secondaryCompound = 'custom');
                } else {
                  final c = secAvailable.firstWhere((item) => item.id == val);
                  _selectSecondaryCompound(c);
                }
              },
            ),
          );
        }),
        gap(10),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: secondaryDose,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: tr('{0} dose', [presetOf(secondaryHormone).name])),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: secondaryUnit, decoration: InputDecoration(labelText: tr('Unit')))),
        ]),
        Builder(builder: (_) {
          if (secondaryCompound != null && secondaryCompound != 'custom') return const SizedBox.shrink();
          final matchingSecPk = pkProfilesFor(secondaryHormone, route);
          if (matchingSecPk.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DropdownButtonFormField<String?>(
              key: ValueKey('secPk-$secondaryHormone-$route-$secondaryPk'),
              initialValue: secondaryPk,
              dropdownColor: C.deepCard,
              borderRadius: BorderRadius.circular(16),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
              decoration: InputDecoration(
                labelText: route == 'inj' ? tr('Ester / simulation profile ({0}):', [presetOf(secondaryHormone).name]) : tr('Simulation profile ({0}):', [presetOf(secondaryHormone).name]),
                prefixIcon: const Icon(Icons.auto_graph_rounded, size: 20, color: C.lavender),
              ),
              items: [
                for (final p in matchingSecPk)
                  DropdownMenuItem<String?>(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 14))),
                DropdownMenuItem<String?>(value: null, child: Text(tr('No simulation'), style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))),
              ],
              onChanged: (val) => setState(() => secondaryPk = val),
            ),
          );
        }),
      ],
      gap(14),
      DropdownButtonFormField<String>(
        key: ValueKey('kind-$kind'),
        initialValue: kind,
        dropdownColor: C.deepCard,
        borderRadius: BorderRadius.circular(16),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.lavender),
        decoration: InputDecoration(
          labelText: tr('Schedule repeat'),
          prefixIcon: const Icon(Icons.event_repeat_rounded, size: 20, color: C.lavender),
        ),
        items: [
          for (final k in _kinds)
            DropdownMenuItem<String>(
              value: k.$1,
              child: Text(
                tr(k.$2),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              kind = val;
              if (kind == 'weekly' && weekdays.isEmpty) weekdays = [DateTime.now().weekday];
            });
          }
        },
      ),
      if (kind == 'interval') ...[
        gap(8),
        TextField(
          controller: every,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: tr('Repeat every (days), 1 = every day')),
        ),
        if ((int.tryParse(every.text) ?? 1) > 1)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Count from last dose')),
            subtitle: Text(tr('The next dose follows when you last logged a dose, not the start date.')),
            value: rolling,
            onChanged: (v) => setState(() => rolling = v),
          ),
      ],
      if (kind == 'weekly') ...[
        gap(8),
        Wrap(spacing: 8, children: [
          for (var i = 1; i <= 7; i++)
            FilterChip(label: Text(tr(_dayNames[i - 1])), selected: weekdays.contains(i), onSelected: (v) => setState(() => v ? weekdays.add(i) : weekdays.remove(i))),
        ]),
      ],
      if (kind == 'monthly') ...[
        gap(8),
        TextField(controller: monthDay, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('Day of month (1 to 31)'))),
      ],
      if (kind != 'asneeded') ...[
        gap(8),
        Text(tr('Times')),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in times) InputChip(label: Text(s), onDeleted: times.length > 1 ? () => setState(() => times.remove(s)) : null),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 16), label: Text(tr('Add time')), onPressed: _addTime),
        ]),
        gap(10),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: day, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (d != null) setState(() => day = d);
          },
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(tr('Start: {0}', [DateFormat('d MMM y', L10n.code).format(day)])),
        ),
      ],
      if (meds.isNotEmpty) ...[
        gap(12),
        Text(tr('Deduct from supply:')),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: Text(tr('No supply')), selected: supplyId == null, onSelected: (_) => setState(() => supplyId = null)),
          for (final s in meds) ChoiceChip(label: Text(s.name), selected: supplyId == s.id, onSelected: (_) => setState(() => supplyId = s.id)),
        ]),
      ],
      gap(20),
      Row(children: [
        if (editing) TextButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded), label: Text(tr('Delete'))),
        Expanded(child: pillButton(editing ? tr('Save changes') : tr('Save therapy'), _save)),
      ]),
    ]);
  }
}
