import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../sim.dart';
import '../theme.dart';
import 'insights.dart';
import 'journal.dart' show moodColor;

String _date(DateTime d) => DateFormat('d MMM y', AppLocale.code).format(d);

class LevelsPage extends ConsumerWidget {
  const LevelsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labs = <Lab>[...(ref.watch(labsProvider).value ?? <Lab>[])]..sort((a, b) => a.at.compareTo(b.at));
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    // Hormon yang punya terapi dengan profil simulasi (injeksi atau oral).
    final simIds = <String>{for (final t in ths) if (pkOf(t.pk) != null) t.hormoneId};
    final byH = <String, List<Lab>>{};
    for (final l in labs) {
      (byH[l.hormoneId] ??= []).add(l);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      Row(children: [
        Expanded(child: Text(context.tr('Levels'), style: display(40))),
        IconButton.filledTonal(
          tooltip: context.tr('Insights'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InsightsPage())),
          icon: const Icon(Icons.insights_rounded),
        ),
        const SizedBox(width: 8),
        pillButton(context.tr('Lab results'), () => showSheet(context, const LabSheet()), icon: Icons.add_rounded),
      ]),
      gap(18),
      for (final h in simIds) Padding(padding: const EdgeInsets.only(bottom: 14), child: LevelPanel(h, compact: true)),
      if (byH.isEmpty && simIds.isEmpty)
        Padding(padding: const EdgeInsets.only(top: 40), child: Text(context.tr('No data yet. Log doses or add your first blood test result.'))),
      for (final e in byH.entries) _LevelCard(hormoneId: e.key, labs: e.value),
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
    final band = ref.watch(targetsProvider).value?[hormoneId];
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget? status;
    if (band != null) {
      final inRange = last.base >= band[0] && last.base <= band[1];
      final color = inRange ? C.lagoon : C.amber;
      status = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(999)),
        child: Text(inRange ? context.tr('In range') : (last.base < band[0] ? context.tr('Below target') : context.tr('Above target')),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? color : Color.lerp(color, C.ink, .5))),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: cardBox(context),
      child: Material(
        color: Colors.transparent,
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
                  Text('${context.tr('Lab result')}, ${_date(last.at)}', style: Theme.of(context).textTheme.bodySmall),
                  gap(14),
                  Text.rich(TextSpan(text: fmt(last.base / f), style: display(44), children: [
                    TextSpan(text: ' $u', style: Theme.of(context).textTheme.bodyMedium),
                  ])),
                  if (delta != null) ...[
                    gap(6),
                    Text('${delta >= 0 ? '↑' : '↓'} ${delta.abs().toStringAsFixed(0)}% ${context.tr('from previous test')}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (status != null) status,
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
  bool showMood = true; // penanda suasana hati di bawah grafik

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
          decoration: cardBox(context),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: kids),
        );

    if (!hasSim && labs.isEmpty) {
      return box([
        Text(context.tr('Estimated {name}', {'name': p.name}), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        gap(8),
        Text(context.tr('Log your first dose on Home tab to see level estimates.')),
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
    final journal = ref.watch(journalProvider).value ?? <JournalEntry>[];
    final moodEntries = [for (final e in journal) if (e.mood != null && !e.at.isBefore(from) && !e.at.isAfter(to)) e]..sort((a, b) => a.at.compareTo(b.at));
    final moodSpots = [for (final e in moodEntries) FlSpot(e.at.difference(from).inMinutes / 1440, top * .05)];
    final drawMood = showMood && moodSpots.isNotEmpty;
    final moodBar = drawMood ? (sim.isNotEmpty ? 1 : 0) + (dots.isNotEmpty ? 1 : 0) : -1;

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
              child: Text(DateFormat('d MMM', AppLocale.code).format(from.add(Duration(minutes: (v * 1440).round()))), style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ),
      rangeAnnotations: bandD == null
          ? null
          : RangeAnnotations(horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: bandD[0],
                y2: bandD[1],
                color: Pastel.lilac.withValues(alpha: .12),
              ),
            ]),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) => [
            for (final s in touched)
              LineTooltipItem(
                s.barIndex == moodBar ? (moods[moodEntries[s.spotIndex].mood]?.$1 ?? '') : fmt(s.y),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
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
        if (drawMood)
          LineChartBarData(
            spots: moodSpots,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(getDotPainter: (s, pc, b, i) => FlDotCirclePainter(radius: 5, color: moodColor(moodEntries[i].mood), strokeWidth: 0)),
          ),
      ],
    ));

    final est = hasSim ? levelAt(intakes, now) * scale / f : null;
    return box([
      Row(children: [
        Expanded(child: Text(hasSim ? context.tr('Estimated {name}', {'name': p.name}) : p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        if (widget.compact)
          IconButton(
            tooltip: context.tr('Open details'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HormonePage(widget.hormoneId))),
            icon: const Icon(Icons.open_in_full_rounded, size: 20),
          ),
      ]),
      if (est != null) ...[
        Text.rich(TextSpan(text: fmt(est.roundToDouble()), style: display(44), children: [
          TextSpan(text: ' $u ${context.tr('current')}', style: theme.textTheme.bodyMedium),
        ])),
        gap(12),
      ],
      if (d != 0)
        Row(children: [
          IconButton(onPressed: () => setState(() => off++), icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Center(child: Text('${DateFormat('d MMM', AppLocale.code).format(from)} - ${_date(to)}', style: theme.textTheme.bodySmall)),
          ),
          IconButton(onPressed: off > 0 ? () => setState(() => off--) : null, icon: const Icon(Icons.chevron_right_rounded)),
        ]),
      SizedBox(height: widget.compact ? 200 : 300, child: chart),
      gap(12),
      PillTabs<int>(
        items: [
          for (final w in [7, 30, 90, 180, 365, if (!hasSim && labs.isNotEmpty) 0])
            (w, switch (w) { 0 => context.tr('All'), 7 => '1 ${context.tr('wk')}', 30 => '1 ${context.tr('mo')}', 90 => '3 ${context.tr('mo')}', 180 => '6 ${context.tr('mo')}', _ => '1 ${context.tr('yr')}' }),
        ],
        value: d,
        onChanged: (w) => setState(() {
          days = w;
          off = 0;
        }),
      ),
      if ((hasSim && nCal > 0) || moodEntries.isNotEmpty) ...[
        gap(8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          if (hasSim && nCal > 0)
            FilterChip(label: Text(context.tr('Adjust to lab results ({n})', {'n': nCal})), selected: cal, onSelected: (v) => setState(() => cal = v)),
          if (moodEntries.isNotEmpty)
            FilterChip(avatar: const Icon(Icons.mood_rounded, size: 16), label: Text(context.tr('Mood')), selected: showMood, onSelected: (v) => setState(() => showMood = v)),
        ]),
      ],
      if (hasSim) ...[
        gap(10),
        Row(children: [
          Icon(Icons.horizontal_rule_rounded, size: 18, color: C.lagoon),
          Text(' ${context.tr('estimated')}   '),
          Icon(Icons.circle_outlined, size: 12, color: C.peony),
          Text(' ${context.tr('lab result')}'),
        ]),
        gap(6),
        Text(context.tr('Estimates use an average population model, not lab results. Individual levels vary; always consult your physician for dosage decisions.'),
            style: theme.textTheme.bodySmall),
      ],
      if (drawMood) ...[
        gap(8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          for (final m in moods.entries)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 10, color: moodColor(m.key)),
              const SizedBox(width: 4),
              Text(m.value.$1, style: theme.textTheme.bodySmall),
            ]),
        ]),
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
            IconButton.filledTonal(tooltip: context.tr('Set target'), onPressed: () => _target(context, ref, p, u, band), icon: const Icon(Icons.flag_rounded)),
          ]),
          gap(8),
          Text(context.tr('Chart in {unit} (change in Settings). Shaded area is your custom target agreed with doctor.', {'unit': u}), style: Theme.of(context).textTheme.bodySmall),
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

  Future<void> _target(BuildContext c, WidgetRef ref, HormonePreset p, String u, List<double>? band) async {
    final f = p.units[u] ?? 1.0;
    final lo = TextEditingController(text: band == null ? '' : fmt(band[0] / f));
    final hi = TextEditingController(text: band == null ? '' : fmt(band[1] / f));
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: Text(c.tr('Target {name} ({unit})', {'name': p.name, 'unit': u})),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: lo, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: c.tr('Lower limit'))),
          gap(8),
          TextField(controller: hi, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: c.tr('Upper limit'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(c.tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(c.tr('Save target'))),
        ],
      ),
    );
    final a = parseNum(lo.text), b = parseNum(hi.text);
    if (ok == true && a != null && b != null) {
      ref.read(repoProvider)?.setTarget(p.id, math.min(a, b) * f, math.max(a, b) * f);
    }
  }
}

/// Hasil lab baru, atau ubah [initial]. "Simpan dan tambah" menyimpan lalu lanjut ke hormon berikutnya
/// dengan tanggal dan catatan yang sama, supaya satu tes darah bisa diisi berurutan.
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('{saved} saved. Enter next hormone.', {'saved': saved}))));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = unit ?? h.base;
    final editing = widget.initial != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? context.tr('Edit lab result') : context.tr('New lab result'), style: display(28)),
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
      TextField(controller: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Value'))),
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
        label: Text('${context.tr('Test date')}: ${_date(at)}'),
      ),
      gap(10),
      TextField(controller: note, decoration: InputDecoration(labelText: context.tr('Notes (optional)'))),
      gap(20),
      Row(children: [
        if (editing)
          TextButton.icon(
            onPressed: () async {
              if (!await confirm(context, context.tr('Delete this lab result?')) || !context.mounted) return;
              ref.read(repoProvider)?.deleteLab(widget.initial!.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(context.tr('Delete')),
          ),
        Expanded(child: pillButton(editing ? context.tr('Save changes') : context.tr('Save'), () => _save())),
      ]),
      if (!editing) Center(child: TextButton(onPressed: () => _save(again: true), child: Text(context.tr('Save and add another hormone')))),
    ]);
  }
}
