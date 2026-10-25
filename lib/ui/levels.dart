import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../sim.dart';
import '../theme.dart';

String _date(DateTime d) => DateFormat('d MMM y', 'en').format(d);

class LevelsPage extends ConsumerStatefulWidget {
  const LevelsPage({super.key});
  @override
  ConsumerState<LevelsPage> createState() => _LevelsPageState();
}

class _LevelsPageState extends ConsumerState<LevelsPage> {
  int _tab = 0; // 0: Charts, 1: Lab Results, 2: Body Changes

  @override
  Widget build(BuildContext context) {
    final labs = <Lab>[...(ref.watch(labsProvider).value ?? <Lab>[])]..sort((a, b) => a.at.compareTo(b.at));
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final simIds = <String>{for (final t in ths) if (pkOf(t.pk) != null) t.hormoneId};
    final byH = <String, List<Lab>>{};
    for (final l in labs) {
      (byH[l.hormoneId] ??= []).add(l);
    }

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
      Row(children: [
        Expanded(child: Text('Insights', style: display(36))),
        pillButton('Lab Results', () => showSheet(context, const LabSheet()), icon: Icons.add_rounded),
      ]),
      gap(14),

      // Segmented Tabs
      Row(
        children: [
          for (final (idx, label) in const [
            (0, 'Hormones'),
            (1, 'Lab Results'),
            (2, 'Body Changes'),
          ]) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _tab == idx ? C.lavender : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _tab == idx ? C.midnight : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (idx < 2) const SizedBox(width: 6),
          ],
        ],
      ),
      gap(18),

      if (_tab == 0) ...[
        for (final h in simIds) Padding(padding: const EdgeInsets.only(bottom: 14), child: LevelPanel(h, compact: true)),
        if (simIds.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 30), child: Center(child: Text('No charts available yet. Log your first therapy to view simulations.'))),
      ] else if (_tab == 1) ...[
        if (byH.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 30), child: Center(child: Text('No lab data yet. Add your first blood test result.'))),
        for (final e in byH.entries) _LevelCard(hormoneId: e.key, labs: e.value),
      ] else ...[
        const _BodyChangesView(),
      ],
    ]);
  }
}

Widget _spark(List<double> ys) => LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
          isCurved: true,
          preventCurveOverShooting: true,
          color: C.peony,
          barWidth: 3,
        ),
      ],
    ));

class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.hormoneId, required this.labs});
  final String hormoneId;
  final List<Lab> labs;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = presetOf(hormoneId), last = labs.last;
    final u = (ref.watch(prefsProvider).value ?? const Prefs()).unitOf(hormoneId);
    final f = p.units[u] ?? 1.0;
    final prev = labs.length > 1 ? labs[labs.length - 2] : null;
    final delta = prev == null || prev.base == 0 ? null : (last.base - prev.base) / prev.base * 100;
    final recent = labs.length > 6 ? labs.sublist(labs.length - 6) : labs;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HormonePage(hormoneId))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Lab result, ${_date(last.at)}', style: Theme.of(context).textTheme.bodySmall),
                  gap(14),
                  Text.rich(TextSpan(text: fmt(last.base / f), style: display(44), children: [
                    TextSpan(text: ' $u', style: Theme.of(context).textTheme.bodyMedium),
                  ])),
                  if (delta != null) ...[
                    gap(6),
                    Text('${delta >= 0 ? '↑' : '↓'} ${delta.abs().toStringAsFixed(0)}% from previous test', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ]),
              ),
              SizedBox(width: 110, height: 60, child: _spark([for (final l in recent) l.base])),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Grafik satu hormon: kurva perkiraan dari catatan dosis (semua cara pakai yang punya profil)
/// ditambah titik hasil lab dan area target. Satuan mengikuti pengaturan.
class LevelPanel extends ConsumerStatefulWidget {
  const LevelPanel(this.hormoneId, {super.key, this.compact = false});
  final String hormoneId;
  final bool compact;
  @override
  ConsumerState<LevelPanel> createState() => _LevelPanelState();
}

class _LevelPanelState extends ConsumerState<LevelPanel> {
  int? days;
  int off = 0; // geser jendela ke belakang, kelipatan lebar jendela
  bool cal = false;

  @override
  Widget build(BuildContext context) {
    final p = presetOf(widget.hormoneId);
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface, surface = theme.colorScheme.surface;
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final logs = ref.watch(logsProvider).value ?? <DoseLog>[];
    final labs = (ref.watch(labsProvider).value ?? <Lab>[]).where((l) => l.hormoneId == widget.hormoneId).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final band = ref.watch(targetsProvider).value?[widget.hormoneId];
    final u = (ref.watch(prefsProvider).value ?? const Prefs()).unitOf(widget.hormoneId);
    final f = p.units[u] ?? 1.0; // nilai tampil = nilai dasar / f
    final intakes = intakesFor(widget.hormoneId, ths, logs);
    final hasSim = intakes.isNotEmpty;

    Widget box(List<Widget> kids) => Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(28)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: kids),
        );

    if (!hasSim && labs.isEmpty) {
      return box([
        Text('Estimated ${p.name}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        gap(8),
        const Text('Record your first dose to view level estimates.'),
      ]);
    }

    final (k, nCal) = calibration(intakes, labs);
    final scale = cal && nCal > 0 ? k : 1.0;
    final now = DateTime.now();
    var d = days ?? (hasSim ? (widget.compact ? 30 : 90) : 0);
    if (d == 0 && labs.isEmpty) d = 30;
    final DateTime from, to;
    if (d == 0) {
      from = labs.first.at.subtract(const Duration(days: 1));
      to = (labs.last.at.isAfter(now) ? labs.last.at : now).add(const Duration(days: 1));
    } else {
      final end = now.subtract(Duration(days: off * d));
      from = end.subtract(Duration(days: d));
      to = end.add(Duration(days: off == 0 ? (hasSim ? 14 : 1) : 1));
    }
    final total = to.difference(from).inMinutes / 1440;
    final sim = simSpots(intakes, from, to, scale: scale / f, n: math.max(40, math.min(1200, (total * 8).round())));
    final dots = [
      for (final l in labs)
        if (!l.at.isBefore(from) && !l.at.isAfter(to)) FlSpot(l.at.difference(from).inMinutes / 1440, l.base / f),
    ];
    final bandD = band == null ? null : [band[0] / f, band[1] / f];
    final ys = <double>[...sim.map((s) => s.y), ...dots.map((s) => s.y), ...?bandD];
    final top = (ys.isEmpty ? 10.0 : ys.reduce(math.max)) * 1.15 + 1;
    final nowX = (now.difference(from).inMinutes / 1440).clamp(0.0, total).toDouble();

    final chart = LineChart(LineChartData(
      minX: 0,
      maxX: total,
      minY: 0,
      maxY: top,
      gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: fg.withValues(alpha: .08), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: math.max(total / 4, 1),
            getTitlesWidget: (v, m) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(DateFormat('d MMM', 'id').format(from.add(Duration(minutes: (v * 1440).round()))), style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ),
      rangeAnnotations: bandD == null
          ? null
          : RangeAnnotations(horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: bandD[0], y2: bandD[1], color: C.lagoon.withValues(alpha: .14))]),
      extraLinesData: ExtraLinesData(verticalLines: [
        VerticalLine(x: nowX, color: fg.withValues(alpha: .35), strokeWidth: 2, dashArray: [4, 4]),
      ]),
      lineBarsData: [
        if (sim.isNotEmpty)
          LineChartBarData(
            spots: sim,
            color: C.lagoon,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: C.lagoon.withValues(alpha: .10)),
          ),
        if (dots.isNotEmpty)
          LineChartBarData(
            spots: dots,
            isCurved: !hasSim,
            preventCurveOverShooting: true,
            color: C.peony,
            barWidth: hasSim ? 0 : 4,
            dotData: FlDotData(getDotPainter: (s, pc, b, i) => FlDotCirclePainter(radius: 6, color: surface, strokeWidth: 4, strokeColor: C.peony)),
          ),
      ],
    ));

    final est = hasSim ? levelAt(intakes, now) * scale / f : null;
    return box([
      Row(children: [
        Expanded(child: Text(hasSim ? 'Estimated ${p.name}' : p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        if (widget.compact)
          IconButton(
            tooltip: 'Open details',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HormonePage(widget.hormoneId))),
            icon: const Icon(Icons.open_in_full_rounded, size: 20),
          ),
      ]),
      if (est != null) ...[
        Text.rich(TextSpan(text: fmt(est.roundToDouble()), style: display(44), children: [
          TextSpan(text: ' $u currently', style: theme.textTheme.bodyMedium),
        ])),
        gap(12),
      ],
      if (d != 0)
        Row(children: [
          IconButton(onPressed: () => setState(() => off++), icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Center(child: Text('${DateFormat('d MMM', 'en').format(from)} to ${_date(to)}', style: theme.textTheme.bodySmall)),
          ),
          IconButton(onPressed: off > 0 ? () => setState(() => off--) : null, icon: const Icon(Icons.chevron_right_rounded)),
        ]),
      SizedBox(height: widget.compact ? 200 : 300, child: chart),
      gap(12),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final w in [7, 14, 30, 90, 180, 365, if (!hasSim && labs.isNotEmpty) 0])
          ChoiceChip(
            label: Text(w == 0 ? 'All' : (w >= 365 ? '1 year' : '$w days')),
            selected: w == d,
            onSelected: (_) => setState(() {
              days = w;
              off = 0;
            }),
          ),
        if (hasSim && nCal > 0)
          FilterChip(label: Text('Adjust to lab results ($nCal)'), selected: cal, onSelected: (v) => setState(() => cal = v)),
      ]),
      if (hasSim) ...[
        gap(10),
        Row(children: [
          Icon(Icons.horizontal_rule_rounded, size: 18, color: C.lagoon),
          Text(' estimate   '),
          Icon(Icons.circle_outlined, size: 12, color: C.peony),
          Text(' lab result'),
        ]),
        gap(6),
        Text('Estimates use average model, not lab results. Individual levels vary, and dosage decisions remain with your doctor.',
            style: theme.textTheme.bodySmall),
      ],
    ]);
  }
}

class HormonePage extends ConsumerWidget {
  const HormonePage(this.hormoneId, {super.key});
  final String hormoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = presetOf(hormoneId);
    final labs = (ref.watch(labsProvider).value ?? <Lab>[]).where((l) => l.hormoneId == hormoneId).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final band = ref.watch(targetsProvider).value?[hormoneId];
    final u = (ref.watch(prefsProvider).value ?? const Prefs()).unitOf(hormoneId);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text(p.name, style: display(32))),
            IconButton.filledTonal(tooltip: 'Set target', onPressed: () => _target(context, ref, p, u, band), icon: const Icon(Icons.flag_rounded)),
          ]),
          gap(8),
          Text('Chart in $u (change in Settings). Green area is target set with your doctor.', style: Theme.of(context).textTheme.bodySmall),
          gap(16),
          LevelPanel(hormoneId),
          gap(16),
          for (final l in labs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => showSheet(context, LabSheet(initial: l)),
              title: Text('${fmt(l.value)} ${l.unit}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_date(l.at) + (l.note == null || l.note!.isEmpty ? '' : '\n${l.note}')),
              trailing: const Icon(Icons.edit_outlined, size: 18),
            ),
        ]),
      ),
    );
  }
}

class _BodyChangesView extends StatelessWidget {
  const _BodyChangesView();

  @override
  Widget build(BuildContext context) {
    final changes = const [
      ('🌸', 'Skin & Face', 'Softer, refined pores, & naturally hydrated.', 'Usually noticed in 1–3 months.'),
      ('💖', 'Breast Development', 'Initial sensitivity & natural tissue growth.', 'Usually noticed in 3–6 months.'),
      ('⌛', 'Body Shape & Curves', 'Subtle fat redistribution to hips & body curves.', 'Develops gradually over 6–12 months.'),
      ('🧘', 'Mood & Balance', 'Softer, calmer, & more balanced mood.', 'Felt as hormones balance.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                C.lavender.withValues(alpha: .15),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              const LuneraLogo(size: 72),
              gap(14),
              Text('Body Development Map', style: display(22)),
              gap(6),
              Text(
                'Estimated physical development & natural body changes.',
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        gap(18),

        for (final c in changes)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.lavender.withValues(alpha: .2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(c.$1, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: C.lavender.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Normal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.lavender)),
                          ),
                        ],
                      ),
                      gap(4),
                      Text(c.$3, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .85))),
                      gap(2),
                      Text(c.$4, style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
                    ],
                  ),
                ),
              ],
            ),
          ),

        gap(10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: C.indigo.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.lavender.withValues(alpha: .3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: C.lavender, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Changes take time, but you\'re making progress. ♡',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

  Future<void> _target(BuildContext c, WidgetRef ref, HormonePreset p, String u, List<double>? band) async {
    final f = p.units[u] ?? 1.0;
    final lo = TextEditingController(text: band == null ? '' : fmt(band[0] / f));
    final hi = TextEditingController(text: band == null ? '' : fmt(band[1] / f));
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: Text('Target ${p.name} ($u)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: lo, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Lower bound')),
          gap(8),
          TextField(controller: hi, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Upper bound')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save Target')),
        ],
      ),
    );
    final a = parseNum(lo.text), b = parseNum(hi.text);
    if (ok == true && a != null && b != null) {
      ref.read(repoProvider)?.setTarget(p.id, math.min(a, b) * f, math.max(a, b) * f);
    }
  }

class LabSheet extends ConsumerStatefulWidget {
  const LabSheet({super.key, this.initial});
  final Lab? initial;
  @override
  ConsumerState<LabSheet> createState() => _LabSheetState();
}

class _LabSheetState extends ConsumerState<LabSheet> {
  late var h = presetOf(widget.initial?.hormoneId ?? 'estradiol');
  late String? unit = widget.initial?.unit;
  late final value = TextEditingController(text: widget.initial == null ? '' : fmt(widget.initial!.value));
  late final note = TextEditingController(text: widget.initial?.note ?? '');
  late DateTime at = widget.initial?.at ?? DateTime.now();

  void _save({bool again = false}) {
    final v = parseNum(value.text);
    if (v == null) return;
    final lab = Lab(id: widget.initial?.id ?? '', hormoneId: h.id, at: at, value: v, unit: unit ?? h.base, note: note.text.trim());
    final repo = ref.read(repoProvider);
    if (widget.initial != null) {
      repo?.updateLab(lab);
    } else {
      repo?.addLab(lab);
    }
    if (again && widget.initial == null) {
      final saved = h.name, i = presets.indexOf(h);
      setState(() {
        h = presets[(i + 1) % presets.length];
        unit = null;
        value.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$saved saved. Fill next hormone.')));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = unit ?? h.base;
    final editing = widget.initial != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? 'Edit Lab Result' : 'New Lab Result', style: display(28)),
      gap(16),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final p in presets)
          ChoiceChip(
            label: Text(p.name),
            selected: h == p,
            onSelected: editing
                ? null
                : (_) => setState(() {
                      h = p;
                      unit = null;
                    }),
          ),
      ]),
      gap(12),
      TextField(controller: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Value')),
      gap(8),
      Wrap(spacing: 8, children: [
        for (final k in h.units.keys) ChoiceChip(label: Text(k), selected: u == k, onSelected: (_) => setState(() => unit = k)),
      ]),
      gap(10),
      OutlinedButton.icon(
        onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: at, firstDate: DateTime(2000), lastDate: DateTime.now());
          if (d != null) setState(() => at = d);
        },
        icon: const Icon(Icons.calendar_today_rounded, size: 18),
        label: Text('Test Date: ${_date(at)}'),
      ),
      gap(10),
      TextField(controller: note, decoration: const InputDecoration(labelText: 'Notes (optional)')),
      gap(20),
      Row(children: [
        if (editing)
          TextButton.icon(
            onPressed: () async {
              if (!await confirm(context, 'Delete this lab result?') || !context.mounted) return;
              ref.read(repoProvider)?.deleteLab(widget.initial!.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        Expanded(child: pillButton(editing ? 'Save Changes' : 'Save', () => _save())),
      ]),
      if (!editing) Center(child: TextButton(onPressed: () => _save(again: true), child: const Text('Save & Add Another'))),
    ]);
  }
}
