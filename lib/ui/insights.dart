import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'journal.dart';

/// Rata-rata skor suasana hati menurut hari sejak dosis terakhir: (hari, jumlah entri, rata-rata).
List<(int, int, double?)> moodByCycleDay(Therapy t, List<DoseLog> logs, List<JournalEntry> journal) {
  final cycle = cycleOf(t);
  final doses = [for (final l in logs) if (l.therapyId == t.id && !l.skipped) l.at]..sort();
  if (doses.isEmpty) return [];
  final sums = List<double>.filled(cycle, 0);
  final ns = List<int>.filled(cycle, 0);
  for (final e in journal) {
    final score = moodScore[e.mood];
    if (score == null) continue;
    DateTime? prev;
    for (final d in doses) {
      if (d.isAfter(e.at)) break;
      prev = d;
    }
    if (prev == null) continue;
    final k = daysBetween(prev, e.at);
    if (k < 0 || k >= cycle) continue; // lewat satu siklus penuh (dosis terlewat) diabaikan
    sums[k] += score;
    ns[k]++;
  }
  return [for (var k = 0; k < cycle; k++) (k, ns[k], ns[k] == 0 ? null : sums[k] / ns[k])];
}

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});
  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  String? therapyId;

  Widget _card(String title, List<Widget> kids) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: cardBox(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          gap(12),
          ...kids,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final logs = ref.watch(logsProvider).value ?? <DoseLog>[];
    final journal = ref.watch(journalProvider).value ?? <JournalEntry>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    final since = DateTime.now().subtract(const Duration(days: 30));

    // ---- 30 hari terakhir ----
    final scheduled = {for (final t in ths) if (!t.asNeeded) t.id};
    final taken = logs.where((l) => !l.skipped && l.at.isAfter(since) && scheduled.contains(l.therapyId)).length;
    final skipped = logs.where((l) => l.skipped && l.at.isAfter(since)).length;
    final missed = buildSlots(ths, logs, prefs, back: 30, ahead: 0).where((s) => s.status == 'overdue').length;
    final total = taken + skipped + missed;
    final moods30 = [for (final e in journal) if (e.mood != null && e.at.isAfter(since)) e.mood!];
    final maxMood = moods.keys.map((k) => moods30.where((m) => m == k).length).fold<int>(1, (a, b) => b > a ? b : a);

    // ---- pola sepanjang siklus ----
    final cyclic = [for (final t in ths) if (!t.asNeeded && cycleOf(t) >= 2 && cycleOf(t) <= 31) t];
    final sel = cyclic.where((t) => t.id == therapyId).firstOrNull ?? cyclic.firstOrNull;
    final buckets = sel == null ? <(int, int, double?)>[] : moodByCycleDay(sel, logs, journal);
    final used = buckets.fold<int>(0, (a, b) => a + b.$2);
    final solid = [for (final b in buckets) if (b.$2 >= 2 && b.$3 != null) b];

    String? insight;
    if (used >= 6 && solid.length >= 2) {
      final hi = solid.reduce((a, b) => b.$3! > a.$3! ? b : a), lo = solid.reduce((a, b) => b.$3! < a.$3! ? b : a);
      if (hi.$1 != lo.$1 && (hi.$3! - lo.$3!) >= .5) {
        insight = context.tr('Your mood tends to be highest on day {hi} after dosing (avg {hiAvg}) and lowest on day {lo} (avg {loAvg}).', {
          'hi': hi.$1,
          'hiAvg': hi.$3!.toStringAsFixed(1),
          'lo': lo.$1,
          'loAvg': lo.$3!.toStringAsFixed(1),
        });
      } else {
        insight = context.tr('Your mood is relatively stable across your cycle.');
      }
    }

    Widget chart(List<(int, int, double?)> bs) {
      final cycle = bs.length;
      return SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          minY: 0,
          maxY: 5.5,
          gridData: FlGridData(drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (_) => FlLine(color: fg.withValues(alpha: .08), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, m) => Text(v < 1 || v > 5 ? '' : '${v.toInt()}', style: const TextStyle(fontSize: 11)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: cycle > 14 ? 5 : 1,
                getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 6), child: Text('${v.toInt()}', style: const TextStyle(fontSize: 11))),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, gi, rod, ri) {
                final b = bs[g.x];
                return BarTooltipItem(
                  b.$3 == null ? context.tr('Day {day}: no data', {'day': b.$1}) : context.tr('Day {day}: {score} ({count} entries)', {'day': b.$1, 'score': b.$3!.toStringAsFixed(1), 'count': b.$2}),
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          barGroups: [
            for (final b in bs)
              BarChartGroupData(x: b.$1, barRods: [
                BarChartRodData(
                  toY: b.$3 ?? 0,
                  width: cycle > 14 ? 6 : 16,
                  borderRadius: BorderRadius.circular(6),
                  color: b.$3 == null ? Colors.transparent : (b.$3! >= 3.5 ? C.lagoon : (b.$3! >= 2.5 ? fg.withValues(alpha: .4) : C.amber)),
                ),
              ]),
          ],
        )),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text(context.tr('Insights'), style: display(32))),
          ]),
          gap(16),
          _card(context.tr('Last 30 days'), [
            if (total == 0)
              Text(context.tr('Not enough data yet. Log your doses and journal for a few days to see a summary.'))
            else ...[
              Text.rich(TextSpan(text: '${(taken / total * 100).round()}%', style: display(44), children: [
                TextSpan(text: ' ${context.tr('doses logged')}', style: theme.textTheme.bodyMedium),
              ])),
              gap(10),
              Wrap(spacing: 8, runSpacing: 4, children: [
                Chip(label: Text(context.tr('{n} taken', {'n': taken})), side: BorderSide.none, backgroundColor: C.lagoon.withValues(alpha: .16)),
                Chip(label: Text(context.tr('{n} skipped', {'n': skipped})), side: BorderSide.none, backgroundColor: fg.withValues(alpha: .07)),
                Chip(label: Text(context.tr('{n} missed', {'n': missed})), side: BorderSide.none, backgroundColor: C.amber.withValues(alpha: .18)),
              ]),
              gap(4),
              Text(context.tr('Estimated from fixed schedules. As-needed doses are not counted.'), style: theme.textTheme.bodySmall),
            ],
          ]),
          _card(context.tr('30-day mood'), [
            if (moods30.isEmpty)
              Text(context.tr('No mood entries yet. Log from the home card.'))
            else
              for (final m in moods.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(m.value.$2, size: 20, color: moodColor(m.key)),
                    const SizedBox(width: 10),
                    SizedBox(width: 56, child: Text(context.tr(m.value.$1), style: theme.textTheme.bodySmall)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: moods30.where((x) => x == m.key).length / maxMood,
                          minHeight: 10,
                          color: moodColor(m.key),
                          backgroundColor: fg.withValues(alpha: .07),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${moods30.where((x) => x == m.key).length}'),
                  ]),
                ),
          ]),
          _card(context.tr('Mood across cycle'), [
            if (sel == null)
              Text(context.tr('Requires a recurring schedule therapy (every 2+ days).'))
            else ...[
              if (cyclic.length > 1)
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final t in cyclic) ChoiceChip(label: Text(t.name), selected: t.id == sel.id, onSelected: (_) => setState(() => therapyId = t.id)),
                ]),
              if (cyclic.length > 1) gap(10),
              Text(context.tr('Average by days since last dose (day 0 = dose day).'), style: theme.textTheme.bodySmall),
              gap(8),
              if (buckets.isEmpty)
                Text(context.tr('No recorded doses for this therapy yet.'))
              else ...[
                chart(buckets),
                gap(6),
                Text(context.tr('Scale: 1 anxious, 2 low, 3 neutral, 4 calm, 5 happy.'), style: theme.textTheme.bodySmall),
                gap(10),
                Text(insight ?? context.tr('Requires at least 6 mood entries after doses, and 2 per compared day. Currently {used} entries.', {'used': used})),
                gap(8),
                Text(context.tr('This reflects your own recorded patterns, not causation. Many factors influence mood.'), style: theme.textTheme.bodySmall),
              ],
            ],
          ]),
        ]),
      ),
    );
  }
}
