import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import 'journal.dart';
import '../l10n.dart';

/// Tubuh & perubahan: ringkasan, garis waktu jurnal, dan kalkulator ukuran badan & pakaian.
class BodyPage extends ConsumerStatefulWidget {
  const BodyPage({super.key});
  @override
  ConsumerState<BodyPage> createState() => _BodyPageState();
}

// Bagian yang digambar pada siluet, urut dari atas, beserta posisi label (pecahan tinggi).
const _onBody = [('Hair', .06), ('Breasts', .22), ('Skin', .38), ('Body shape', .54)];

class _BodyPageState extends ConsumerState<BodyPage> {
  int tab = 0;
  String area = bodyAreas.first;

  @override
  Widget build(BuildContext context) {
    final entries = <JournalEntry>[...(ref.watch(journalProvider).value ?? <JournalEntry>[])]..sort((a, b) => b.at.compareTo(a.at));
    final withBody = entries.where((e) => e.hasBody).toList();
    final measurements = <BodyMeasurement>[...(ref.watch(measurementsProvider).value ?? <BodyMeasurement>[])]
      ..sort((a, b) => b.at.compareTo(a.at));

    final latestNotes = <String, (String, DateTime)>{};
    for (final e in withBody) {
      for (final b in e.body.entries) {
        latestNotes.putIfAbsent(b.key, () => (b.value, e.at));
      }
    }
    final fg = Theme.of(context).colorScheme.onSurface;
    final fmtDate = DateFormat('d MMM y', L10n.code);

    Widget callout(String name, double fy, double w, double h) {
      final l = latestNotes[name];
      return Positioned(
        left: w * .46,
        right: 0,
        top: fy * h - 24,
        child: GestureDetector(
          onTap: () => setState(() {
            area = name;
            tab = 1;
          }),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: C.peony.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(tr(name), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(l?.$1 ?? tr('No entries yet'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: .65))),
            ]),
          ),
        ),
      );
    }

    Widget otherRow(String name) {
      final l = latestNotes[name];
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: cardBox(context, radius: 20),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: () => setState(() {
            area = name;
            tab = 1;
          }),
          title: Text(tr(name), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(l == null ? tr('No entries yet') : '${l.$1}\n${fmtDate.format(l.$2)}'),
          isThreeLine: l != null,
          trailing: Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: .5)),
        ),
      );
    }

    final overview = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(context),
        child: LayoutBuilder(builder: (c, cons) {
          final maxW = cons.maxWidth;
          const h = 420.0;
          final diagramW = maxW > 460.0 ? 440.0 : maxW;
          return Center(
            child: SizedBox(
              width: diagramW,
              height: h,
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _BodyPainter(C.peony))),
                for (final a in _onBody) callout(a.$1, a.$2, diagramW, h),
              ]),
            ),
          );
        }),
      ),
      gap(12),
      otherRow('Energy'),
      otherRow('Sleep'),
      gap(4),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.peony.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)),
        child: Text(tr('Change takes time. Record things as they are, then compare again a few weeks later.')),
      ),
    ]);

    final items = [for (final e in withBody) if (e.body.containsKey(area)) (e.at, e.body[area]!)];
    final detail = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final a in bodyAreas) ChoiceChip(label: Text(tr(a)), selected: area == a, onSelected: (_) => setState(() => area = a)),
      ]),
      gap(14),
      if (items.isEmpty)
        Text(tr('No notes for {0} yet. Add one with the "Log a change" button.', [tr(area)]))
      else ...[
        Text(tr('{0} {0?note|notes}, first on {1}', [items.length, fmtDate.format(items.last.$1)]), style: Theme.of(context).textTheme.bodySmall),
        gap(10),
        for (final it in items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: cardBox(context, radius: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fmtDate.format(it.$1), style: Theme.of(context).textTheme.bodySmall),
              gap(4),
              Text(it.$2),
            ]),
          ),
      ],
    ]);

    final sizeTab = _SizeTab(measurements: measurements);

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text(tr('Body & changes'), style: display(28))),
          ]),
          gap(12),
          PillTabs<int>(
            items: [
              (0, tr('Overview')),
              (1, tr('Timeline')),
              (2, tr('Size & Measures')),
            ],
            value: tab,
            onChanged: (v) => setState(() => tab = v),
          ),
          gap(16),
          if (tab == 0)
            overview
          else if (tab == 1)
            detail
          else
            sizeTab,
          gap(16),
          if (tab == 2)
            pillButton(tr('Log Measurement'), () => showSheet(context, const MeasurementSheet()), icon: Icons.straighten_rounded)
          else
            pillButton(tr('Log a change'), () => showSheet(context, const JournalSheet()), icon: Icons.add_rounded),
        ]),
      ),
    );
  }
}

class _SizeTab extends ConsumerWidget {
  const _SizeTab({required this.measurements});
  final List<BodyMeasurement> measurements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (measurements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: cardBox(context),
        child: Column(
          children: [
            Icon(Icons.straighten_rounded, size: 54, color: C.peony.withValues(alpha: 0.8)),
            gap(14),
            Text(tr('Body Sizing & Measurements'), style: display(20), textAlign: TextAlign.center),
            gap(8),
            Text(
              tr('Track your bust, underbust, waist, and hips to accurately calculate your bra size, cup letter, clothing fit (tops & pants), and body proportions over time.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            gap(16),
            OutlinedButton.icon(
              onPressed: () => showSheet(context, const MeasurementSheet()),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('Log First Measurement')),
            ),
          ],
        ),
      );
    }

    final latest = measurements.first;
    final bra = latest.braSize;
    final top = latest.topSize;
    final bottom = latest.bottomSize;
    final whr = latest.waistToHipRatio;
    final fmtDate = DateFormat('d MMMM y', L10n.code);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Hero Card: Bra & Chest Fit
      if (bra != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                C.peony.withValues(alpha: 0.22),
                C.deepCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.peony.withValues(alpha: 0.35)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.female_rounded, color: Pastel.lilac, size: 22),
                  const SizedBox(width: 8),
                  Text(tr('Bra & Chest Size'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Pastel.lilac.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Cup ${bra.cup}',
                    style: const TextStyle(color: Pastel.lilac, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
            gap(14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(bra.usUk, style: display(38, color: Colors.white)),
                const SizedBox(width: 8),
                Text('/ ${bra.euId}', style: display(22, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(width: 10),
                Text(
                  '(US/UK • EU/ID)',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
            gap(6),
            Text(
              tr('Underbust {0} {1} • Full Bust {2} {1} (Diff: +{3} cm)', [
                fmt(latest.underbust!),
                latest.unit,
                fmt(latest.bust!),
                fmt(bra.diffCm),
              ]),
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
            ),
            if (bra.sisterTight != null || bra.sisterLoose != null) ...[
              gap(14),
              const Divider(color: Colors.white12, height: 1),
              gap(10),
              Text(tr('Sister Sizes (Equivalent Cup Volume):'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pastel.mist)),
              gap(6),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (bra.sisterTight != null)
                  Chip(
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    label: Text(
                      '${tr('Snug band')}: ${bra.sisterTight}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                if (bra.sisterLoose != null)
                  Chip(
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    label: Text(
                      '${tr('Comfort band')}: ${bra.sisterLoose}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ]),
            ],
          ]),
        ),
        gap(14),
      ],

      // Estimated Clothing Sizes Grid
      Container(
        padding: const EdgeInsets.all(18),
        decoration: cardBox(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.checkroom_rounded, color: Pastel.mint, size: 20),
            const SizedBox(width: 8),
            Text(tr('Estimated Clothing Fit'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          gap(14),
          Row(children: [
            Expanded(
              child: _MetricTile(
                title: tr('Top / Shirt'),
                value: top ?? '-',
                subtitle: latest.bust != null ? '${fmt(latest.bust!)} ${latest.unit}' : tr('Measure bust'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                title: tr('Bottom / Pants'),
                value: bottom ?? '-',
                subtitle: latest.waist != null ? '${fmt(latest.waist!)} ${latest.unit}' : tr('Measure waist'),
              ),
            ),
          ]),
          gap(10),
          Row(children: [
            Expanded(
              child: _MetricTile(
                title: tr('Shoes'),
                value: latest.displayShoeSize ?? '-',
                subtitle: latest.shoeSizeResult != null
                    ? 'UK ${latest.shoeSizeResult!.uk} • ${fmt(latest.shoeSizeResult!.footCm)} cm'
                    : (latest.footLength != null ? '${fmt(latest.footLength!)} ${latest.unit}' : tr('Measure foot')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                title: tr('WHR Ratio'),
                value: whr != null ? whr.toStringAsFixed(2) : '-',
                subtitle: whr != null ? (whr <= 0.8 ? tr('Hourglass/Pear') : tr('Athletic')) : tr('Waist/Hips'),
              ),
            ),
          ]),
        ]),
      ),
      gap(14),

      // Latest Measurements Detail Card
      Container(
        padding: const EdgeInsets.all(18),
        decoration: cardBox(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(tr('Latest Measurements'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(fmtDate.format(latest.at), style: Theme.of(context).textTheme.bodySmall),
          ]),
          gap(12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (latest.bust != null) _measureChip(tr('Full Bust'), latest.bust!, latest.unit),
              if (latest.underbust != null) _measureChip(tr('Underbust'), latest.underbust!, latest.unit),
              if (latest.waist != null) _measureChip(tr('Waist'), latest.waist!, latest.unit),
              if (latest.hips != null) _measureChip(tr('Hips'), latest.hips!, latest.unit),
              if (latest.thigh != null) _measureChip(tr('Thigh'), latest.thigh!, latest.unit),
              if (latest.calf != null) _measureChip(tr('Calf'), latest.calf!, latest.unit),
              if (latest.inseam != null) _measureChip(tr('Inseam'), latest.inseam!, latest.unit),
              if (latest.footLength != null) _measureChip(tr('Foot Length'), latest.footLength!, latest.unit),
              if (latest.displayShoeSize != null) _textChip(tr('Shoes'), latest.displayShoeSize!),
              if (latest.shoulder != null) _measureChip(tr('Shoulder'), latest.shoulder!, latest.unit),
              if (latest.weight != null) _measureChip(tr('Weight'), latest.weight!, 'kg'),
              if (latest.height != null) _measureChip(tr('Height'), latest.height!, 'cm'),
            ],
          ),
          if (latest.note != null && latest.note!.isNotEmpty) ...[
            gap(10),
            Text(latest.note!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
          ],
        ]),
      ),
      gap(14),

      // Trends & Progression Curves
      _MeasurementTrendsCard(measurements: measurements),
      gap(14),

      // Measurement History
      Text(tr('Measurement History'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      gap(8),
      for (final m in measurements)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: cardBox(context, radius: 18),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () => showSheet(context, MeasurementSheet(initial: m)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmtDate.format(m.at), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (m.braSize != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: C.peony.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(m.braSize!.usUk, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Pastel.lilac)),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (m.bust != null) '${tr('Bust')}: ${fmt(m.bust!)}${m.unit}',
                  if (m.waist != null) '${tr('Waist')}: ${fmt(m.waist!)}${m.unit}',
                  if (m.hips != null) '${tr('Hips')}: ${fmt(m.hips!)}${m.unit}',
                  if (m.thigh != null) '${tr('Thigh')}: ${fmt(m.thigh!)}${m.unit}',
                  if (m.inseam != null) '${tr('Inseam')}: ${fmt(m.inseam!)}${m.unit}',
                  if (m.displayShoeSize != null) '${tr('Shoes')}: ${m.displayShoeSize}',
                ].join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () async {
                if (!await confirm(context, tr('Delete this measurement entry?'))) return;
                ref.read(repoProvider)?.deleteMeasurement(m.id);
              },
            ),
          ),
        ),
    ]);
  }

  Widget _measureChip(String label, double val, String unit) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text('${fmt(val)} $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _textChip(String label, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value, required this.subtitle});
  final String title, value, subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        gap(4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        gap(2),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ]),
    );
  }
}

class _MeasurementTrendsCard extends StatefulWidget {
  const _MeasurementTrendsCard({required this.measurements});
  final List<BodyMeasurement> measurements;

  @override
  State<_MeasurementTrendsCard> createState() => _MeasurementTrendsCardState();
}

class _MeasurementTrendsCardState extends State<_MeasurementTrendsCard> {
  String _metric = 'whr'; // 'whr', 'bust', 'waist_hips', 'weight', 'legs'

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final chronological = [...widget.measurements]..sort((a, b) => a.at.compareTo(b.at));

    if (chronological.length < 2) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: cardBox(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Pastel.lilac.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up_rounded, color: Pastel.lilac, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Progression Curves'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    tr('Log at least 2 measurements to view your progression trends over time.'),
                    style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Determine data based on _metric
    List<BodyMeasurement> filtered;
    String primaryLabel;
    String? secondaryLabel;
    Color primaryColor;
    Color secondaryColor;
    String unitLabel;
    double Function(BodyMeasurement) getPrimary;
    double? Function(BodyMeasurement)? getSecondary;

    switch (_metric) {
      case 'bust':
        filtered = chronological.where((m) => m.bustCm != null).toList();
        primaryLabel = tr('Full Bust');
        secondaryLabel = tr('Underbust');
        primaryColor = Pastel.lilac;
        secondaryColor = C.lagoon;
        unitLabel = 'cm';
        getPrimary = (m) => m.bustCm!;
        getSecondary = (m) => m.underbustCm;
        break;
      case 'waist_hips':
        filtered = chronological.where((m) => m.waistCm != null && m.hipsCm != null).toList();
        primaryLabel = tr('Waist');
        secondaryLabel = tr('Hips');
        primaryColor = C.amber;
        secondaryColor = Pastel.lilac;
        unitLabel = 'cm';
        getPrimary = (m) => m.waistCm!;
        getSecondary = (m) => m.hipsCm;
        break;
      case 'weight':
        filtered = chronological.where((m) => m.weight != null).toList();
        primaryLabel = tr('Weight');
        secondaryLabel = null;
        primaryColor = Pastel.sky;
        secondaryColor = Colors.transparent;
        unitLabel = 'kg';
        getPrimary = (m) => m.weight!;
        getSecondary = null;
        break;
      case 'legs':
        filtered = chronological.where((m) => m.thighCm != null).toList();
        primaryLabel = tr('Thigh');
        secondaryLabel = tr('Calf');
        primaryColor = Pastel.mint;
        secondaryColor = Pastel.sky;
        unitLabel = 'cm';
        getPrimary = (m) => m.thighCm!;
        getSecondary = (m) => m.calfCm;
        break;
      case 'whr':
      default:
        filtered = chronological.where((m) => m.waistToHipRatio != null).toList();
        primaryLabel = tr('WHR Ratio');
        secondaryLabel = null;
        primaryColor = Pastel.lilac;
        secondaryColor = Colors.transparent;
        unitLabel = '';
        getPrimary = (m) => m.waistToHipRatio!;
        getSecondary = null;
        break;
    }

    Widget content;
    if (filtered.length < 2) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            tr('Not enough records with this measurement yet.'),
            style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 13),
          ),
        ),
      );
    } else {
      final firstVal = getPrimary(filtered.first);
      final lastVal = getPrimary(filtered.last);
      final diff = lastVal - firstVal;

      // Calculate Min & Max for Chart
      double minY = double.infinity;
      double maxY = -double.infinity;
      final primarySpots = <FlSpot>[];
      final secondarySpots = <FlSpot>[];

      for (var i = 0; i < filtered.length; i++) {
        final m = filtered[i];
        final pVal = getPrimary(m);
        primarySpots.add(FlSpot(i.toDouble(), pVal));
        if (pVal < minY) minY = pVal;
        if (pVal > maxY) maxY = pVal;

        if (getSecondary != null) {
          final sVal = getSecondary(m);
          if (sVal != null) {
            secondarySpots.add(FlSpot(i.toDouble(), sVal));
            if (sVal < minY) minY = sVal;
            if (sVal > maxY) maxY = sVal;
          }
        }
      }

      // Add breathing room padding
      final span = maxY - minY;
      final pad = span == 0 ? 1.0 : span * 0.18;
      minY = (minY - pad).clamp(0.0, double.infinity);
      maxY = maxY + pad;
      if (minY >= maxY) {
        minY = 0;
        maxY = 1;
      }

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baseline vs Current Comparison Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  label: tr('Baseline'),
                  value: '${fmt(firstVal)} $unitLabel'.trim(),
                  date: filtered.first.at,
                ),
                Container(width: 1, height: 32, color: Colors.white12),
                _StatColumn(
                  label: tr('Current'),
                  value: '${fmt(lastVal)} $unitLabel'.trim(),
                  date: filtered.last.at,
                ),
                Container(width: 1, height: 32, color: Colors.white12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Difference'), style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.6))),
                    const SizedBox(height: 2),
                    Text(
                      '${diff >= 0 ? '+' : ''}${fmt(diff)} $unitLabel'.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: diff == 0 ? fg : (primaryColor == C.amber ? (diff < 0 ? Pastel.mint : C.amber) : Pastel.lilac),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          gap(14),

          // Legend
          if (secondaryLabel != null && secondarySpots.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: primaryColor, label: primaryLabel),
                const SizedBox(width: 16),
                _LegendItem(color: secondaryColor, label: secondaryLabel),
              ],
            ),
            gap(10),
          ],

          // Interactive FlChart
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (filtered.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: fg.withValues(alpha: 0.08), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, m) => Text(
                        fmt(v),
                        style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= filtered.length) return const SizedBox.shrink();
                        if (filtered.length > 5 && idx != 0 && idx != filtered.length - 1 && idx != filtered.length ~/ 2) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d MMM', L10n.code).format(filtered[idx].at),
                            style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.55)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touched) => [
                      for (final s in touched)
                        LineTooltipItem(
                          '${s.barIndex == 0 ? primaryLabel : (secondaryLabel ?? '')}: ${fmt(s.y)} $unitLabel\n${DateFormat('d MMM y', L10n.code).format(filtered[s.spotIndex].at)}'.trim(),
                          TextStyle(color: s.bar.color, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: primarySpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: primaryColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  if (secondarySpots.isNotEmpty)
                    LineChartBarData(
                      spots: secondarySpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      color: secondaryColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3.5,
                          color: secondaryColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: secondaryColor.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardBox(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: Pastel.lilac, size: 22),
                  const SizedBox(width: 8),
                  Text(tr('Progression Trends'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Pastel.lilac.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('{0} {0?record|records}', [chronological.length]),
                  style: const TextStyle(fontSize: 11, color: Pastel.lilac, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          gap(12),

          // Metric Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MetricChip(label: tr('WHR Ratio'), selected: _metric == 'whr', onSelected: () => setState(() => _metric = 'whr')),
                const SizedBox(width: 8),
                _MetricChip(label: tr('Bust & Ribcage'), selected: _metric == 'bust', onSelected: () => setState(() => _metric = 'bust')),
                const SizedBox(width: 8),
                _MetricChip(label: tr('Waist & Hips'), selected: _metric == 'waist_hips', onSelected: () => setState(() => _metric = 'waist_hips')),
                const SizedBox(width: 8),
                _MetricChip(label: tr('Weight'), selected: _metric == 'weight', onSelected: () => setState(() => _metric = 'weight')),
                const SizedBox(width: 8),
                _MetricChip(label: tr('Thigh & Calf'), selected: _metric == 'legs', onSelected: () => setState(() => _metric = 'legs')),
              ],
            ),
          ),
          gap(14),

          content,
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value, required this.date});
  final String label, value;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(
          DateFormat('d MMM y', L10n.code).format(date),
          style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.45)),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }
}

/// Modal dialog untuk mencatat atau mengubah ukuran badan
class MeasurementSheet extends ConsumerStatefulWidget {
  const MeasurementSheet({super.key, this.initial});
  final BodyMeasurement? initial;

  @override
  ConsumerState<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<MeasurementSheet> {
  late DateTime at = widget.initial?.at ?? DateTime.now();
  late String unit = widget.initial?.unit ?? 'cm';
  late final bustCtl = TextEditingController(text: widget.initial?.bust == null ? '' : fmt(widget.initial!.bust!));
  late final underbustCtl = TextEditingController(text: widget.initial?.underbust == null ? '' : fmt(widget.initial!.underbust!));
  late final waistCtl = TextEditingController(text: widget.initial?.waist == null ? '' : fmt(widget.initial!.waist!));
  late final hipsCtl = TextEditingController(text: widget.initial?.hips == null ? '' : fmt(widget.initial!.hips!));
  late final thighCtl = TextEditingController(text: widget.initial?.thigh == null ? '' : fmt(widget.initial!.thigh!));
  late final calfCtl = TextEditingController(text: widget.initial?.calf == null ? '' : fmt(widget.initial!.calf!));
  late final inseamCtl = TextEditingController(text: widget.initial?.inseam == null ? '' : fmt(widget.initial!.inseam!));
  late final footLengthCtl = TextEditingController(text: widget.initial?.footLength == null ? '' : fmt(widget.initial!.footLength!));
  late final shoeSizeCtl = TextEditingController(text: widget.initial?.shoeSize ?? '');
  late final shoulderCtl = TextEditingController(text: widget.initial?.shoulder == null ? '' : fmt(widget.initial!.shoulder!));
  late final weightCtl = TextEditingController(text: widget.initial?.weight == null ? '' : fmt(widget.initial!.weight!));
  late final heightCtl = TextEditingController(text: widget.initial?.height == null ? '' : fmt(widget.initial!.height!));
  late final noteCtl = TextEditingController(text: widget.initial?.note ?? '');

  @override
  void initState() {
    super.initState();
    bustCtl.addListener(_onChanged);
    underbustCtl.addListener(_onChanged);
    waistCtl.addListener(_onChanged);
    footLengthCtl.addListener(_onChanged);
  }

  @override
  void dispose() {
    bustCtl.removeListener(_onChanged);
    underbustCtl.removeListener(_onChanged);
    waistCtl.removeListener(_onChanged);
    footLengthCtl.removeListener(_onChanged);
    bustCtl.dispose();
    underbustCtl.dispose();
    waistCtl.dispose();
    hipsCtl.dispose();
    thighCtl.dispose();
    calfCtl.dispose();
    inseamCtl.dispose();
    footLengthCtl.dispose();
    shoeSizeCtl.dispose();
    shoulderCtl.dispose();
    weightCtl.dispose();
    heightCtl.dispose();
    noteCtl.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: at,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null && mounted) {
      setState(() => at = DateTime(d.year, d.month, d.day, at.hour, at.minute));
    }
  }

  void _save() {
    final b = parseNum(bustCtl.text);
    final u = parseNum(underbustCtl.text);
    final w = parseNum(waistCtl.text);
    final h = parseNum(hipsCtl.text);
    final th = parseNum(thighCtl.text);
    final cf = parseNum(calfCtl.text);
    final ins = parseNum(inseamCtl.text);
    final ft = parseNum(footLengthCtl.text);
    final sh = shoeSizeCtl.text.trim().isEmpty ? null : shoeSizeCtl.text.trim();
    final s = parseNum(shoulderCtl.text);
    final wt = parseNum(weightCtl.text);
    final ht = parseNum(heightCtl.text);

    if (b == null && u == null && w == null && h == null && th == null && cf == null && ins == null && s == null && wt == null && ht == null && ft == null && sh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Please enter at least one measurement.'))),
      );
      return;
    }

    final repo = ref.read(repoProvider);
    final entry = BodyMeasurement(
      id: widget.initial?.id ?? '',
      at: at,
      unit: unit,
      bust: b,
      underbust: u,
      waist: w,
      hips: h,
      shoulder: s,
      thigh: th,
      calf: cf,
      inseam: ins,
      footLength: ft,
      shoeSize: sh,
      weight: wt,
      height: ht,
      note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
    );

    if (widget.initial == null) {
      repo?.addMeasurement(entry);
    } else {
      repo?.updateMeasurement(entry);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('EEEE, d MMMM y', L10n.code);
    final b = parseNum(bustCtl.text);
    final u = parseNum(underbustCtl.text);
    final ft = parseNum(footLengthCtl.text);
    BraSizeResult? liveBra;
    if (b != null && u != null && b > u) {
      final bCm = unit == 'in' ? b * 2.54 : b;
      final uCm = unit == 'in' ? u * 2.54 : u;
      liveBra = calculateBraSize(bustCm: bCm, underbustCm: uCm);
    }
    ShoeSizeResult? liveShoe;
    if (ft != null && ft > 0) {
      final ftCm = unit == 'in' ? ft * 2.54 : ft;
      liveShoe = calculateShoeSize(ftCm);
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(widget.initial == null ? tr('Log Measurements') : tr('Edit Measurements'), style: display(22)),
        PillTabs<String>(
          items: const [('cm', 'cm'), ('in', 'inches')],
          value: unit,
          onChanged: (v) => setState(() => unit = v),
        ),
      ]),
      gap(12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_rounded),
        title: Text(fmtDate.format(at)),
        trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
        onTap: _pickDate,
      ),
      gap(8),

      // Live Bra Size Preview Banner
      if (liveBra != null)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: C.peony.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.peony.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.checkroom_rounded, color: Pastel.lilac),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${tr('Estimated Bra Size')}: ${liveBra.usUk} (${liveBra.euId})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    'Cup ${liveBra.cup} • ${tr('Diff')} +${fmt(liveBra.diffCm)} cm',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ]),
              ),
            ],
          ),
        ),

      // Live Shoe Size Preview Banner
      if (liveShoe != null)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Pastel.mint.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Pastel.mint.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.snowshoeing_rounded, color: Pastel.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${tr('Estimated Shoe Size')}: EU ${liveShoe.eu} (US W ${liveShoe.usWomen})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    'US Men ${liveShoe.usMen} • UK ${liveShoe.uk} • ${fmt(liveShoe.footCm)} cm',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ]),
              ),
            ],
          ),
        ),

      // Primary Chest Fields
      Row(children: [
        Expanded(
          child: TextField(
            controller: bustCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Full Bust ({0})', [unit]),
              hintText: unit == 'cm' ? '88' : '34.5',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: underbustCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Underbust ({0})', [unit]),
              hintText: unit == 'cm' ? '74' : '29',
            ),
          ),
        ),
      ]),
      gap(10),

      // Waist & Hips
      Row(children: [
        Expanded(
          child: TextField(
            controller: waistCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Waist ({0})', [unit]),
              hintText: unit == 'cm' ? '68' : '26.8',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: hipsCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Hips ({0})', [unit]),
              hintText: unit == 'cm' ? '92' : '36.2',
            ),
          ),
        ),
      ]),
      gap(10),

      // Lower Body: Thigh & Calf
      Row(children: [
        Expanded(
          child: TextField(
            controller: thighCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Thigh ({0})', [unit]),
              hintText: unit == 'cm' ? '54' : '21.2',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: calfCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Calf ({0})', [unit]),
              hintText: unit == 'cm' ? '36' : '14.2',
            ),
          ),
        ),
      ]),
      gap(10),

      // Inseam & Shoulder
      Row(children: [
        Expanded(
          child: TextField(
            controller: inseamCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Inseam ({0})', [unit]),
              hintText: unit == 'cm' ? '76' : '30',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: shoulderCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Shoulder ({0})', [unit]),
              hintText: unit == 'cm' ? '40' : '15.7',
            ),
          ),
        ),
      ]),
      gap(10),

      // Feet & Shoes
      Row(children: [
        Expanded(
          child: TextField(
            controller: footLengthCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Foot Length ({0})', [unit]),
              hintText: unit == 'cm' ? '24.5' : '9.6',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: shoeSizeCtl,
            decoration: InputDecoration(
              labelText: tr('Shoe Size (optional)'),
              hintText: tr('e.g. EU 39 / 40'),
            ),
          ),
        ),
      ]),
      gap(10),

      // Weight & Height
      Row(children: [
        Expanded(
          child: TextField(
            controller: weightCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Weight (kg)'),
              hintText: '55',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: heightCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('Height (cm)'),
              hintText: '165',
            ),
          ),
        ),
      ]),
      gap(10),
      TextField(
        controller: noteCtl,
        decoration: InputDecoration(
          labelText: tr('Notes (optional)'),
          hintText: tr('E.g. measured morning before breakfast'),
        ),
      ),
      gap(16),
      SizedBox(
        width: double.infinity,
        child: pillButton(tr('Save Measurements'), _save),
      ),
    ]);
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final sw = (w * .3).clamp(80.0, h * 0.25);
    final cx = (w * .2).clamp(55.0, sw * 0.75);
    final fill = Paint()..color = color.withValues(alpha: .26);
    final stroke = Paint()
      ..color = color.withValues(alpha: .26)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, h * .065), h * .05, fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * .12), width: sw * .16, height: h * .05), const Radius.circular(6)), fill);
    final torso = Path()
      ..moveTo(cx - .55 * sw, h * .15)
      ..quadraticBezierTo(cx, h * .12, cx + .55 * sw, h * .15)
      ..cubicTo(cx + .5 * sw, h * .24, cx + .3 * sw, h * .30, cx + .3 * sw, h * .36)
      ..cubicTo(cx + .3 * sw, h * .40, cx + .55 * sw, h * .43, cx + .6 * sw, h * .50)
      ..lineTo(cx - .6 * sw, h * .50)
      ..cubicTo(cx - .55 * sw, h * .43, cx - .3 * sw, h * .40, cx - .3 * sw, h * .36)
      ..cubicTo(cx - .3 * sw, h * .30, cx - .5 * sw, h * .24, cx - .55 * sw, h * .15)
      ..close();
    canvas.drawPath(torso, fill);
    stroke.strokeWidth = sw * .1;
    canvas.drawLine(Offset(cx - .62 * sw, h * .17), Offset(cx - .82 * sw, h * .40), stroke);
    canvas.drawLine(Offset(cx + .62 * sw, h * .17), Offset(cx + .82 * sw, h * .40), stroke);
    stroke.strokeWidth = sw * .24;
    canvas.drawLine(Offset(cx - .27 * sw, h * .52), Offset(cx - .24 * sw, h * .93), stroke);
    canvas.drawLine(Offset(cx + .27 * sw, h * .52), Offset(cx + .24 * sw, h * .93), stroke);

    // titik di tubuh dan garis ke label (urut sama dengan _onBody)
    final labelX = w * .46 - 6;
    final marks = [
      (Offset(cx + h * .05, h * .065), _onBody[0].$2 * h),
      (Offset(cx + .22 * sw, h * .22), _onBody[1].$2 * h),
      (Offset(cx + .82 * sw, h * .33), _onBody[2].$2 * h),
      (Offset(cx + .52 * sw, h * .46), _onBody[3].$2 * h),
    ];
    final line = Paint()
      ..color = color.withValues(alpha: .55)
      ..strokeWidth = 1.5;
    final dot = Paint()..color = color;
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in marks) {
      canvas.drawLine(m.$1, Offset(labelX, m.$2), line);
      canvas.drawCircle(m.$1, 5, dot);
      canvas.drawCircle(m.$1, 5, ring);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter o) => o.color != color;
}
