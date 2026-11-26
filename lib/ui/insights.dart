import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../consultation_prep.dart';
import '../cycle_insights.dart';
import '../l10n.dart';
import '../milestones.dart';
import '../models.dart';
import '../moments.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import '../workout_coach.dart';
import 'journal.dart';
import 'responsive.dart';

/// Rata-rata skor suasana hati menurut hari sejak dosis terakhir: (hari, jumlah entri, rata-rata).
List<(int, int, double?)> moodByCycleDay(
    Therapy t, List<DoseLog> logs, List<JournalEntry> journal) {
  final cycle = cycleOf(t);
  final doses = [
    for (final l in logs)
      if (l.therapyId == t.id && !l.skipped) l.at
  ]..sort();
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
    if (k < 0 || k >= cycle)
      continue; // lewat satu siklus penuh (dosis terlewat) diabaikan
    sums[k] += score;
    ns[k]++;
  }
  return [
    for (var k = 0; k < cycle; k++)
      (k, ns[k], ns[k] == 0 ? null : sums[k] / ns[k])
  ];
}

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});
  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  String? therapyId;
  DateTime _recapMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<TransitionMilestone> _milestones = const [];

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      final list = await MilestoneStore.loadMilestones();
      if (mounted) {
        setState(() => _milestones = list);
      }
    } catch (_) {}
  }

  Widget _card(String title, List<Widget> kids) => Container(
        padding: const EdgeInsets.all(20),
        decoration: cardBox(context, radius: R.card),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          gap(12),
          ...kids,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final ths = ref.watch(therapiesProvider).valueOrNull ?? <Therapy>[];
    final logs = ref.watch(logsProvider).valueOrNull ?? <DoseLog>[];
    final journal = ref.watch(journalProvider).valueOrNull ?? <JournalEntry>[];
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final moments = ref.watch(momentsProvider);
    final workout = ref.watch(workoutProvider);
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));

    // ---- 30 hari terakhir ----
    final scheduled = {
      for (final t in ths)
        if (!t.asNeeded) t.id
    };
    final taken = logs
        .where((l) =>
            !l.skipped &&
            l.at.isAfter(since) &&
            scheduled.contains(l.therapyId))
        .length;
    final skipped = logs.where((l) => l.skipped && l.at.isAfter(since)).length;
    final missed = buildSlots(ths, logs, prefs, back: 30, ahead: 0)
        .where((s) => s.status == 'overdue')
        .length;
    final total = taken + skipped + missed;
    final moods30 = [
      for (final e in journal)
        if (e.mood != null && e.at.isAfter(since)) e.mood!
    ];
    final maxMood = moods.keys
        .map((k) => moods30.where((m) => m == k).length)
        .fold<int>(1, (a, b) => b > a ? b : a);

    // ---- pola sepanjang siklus ----
    final cyclic = [
      for (final t in ths)
        if (!t.asNeeded && cycleOf(t) >= 2 && cycleOf(t) <= 31) t
    ];
    final sel = cyclic.where((t) => t.id == therapyId).firstOrNull ??
        cyclic.firstOrNull;
    final buckets = sel == null
        ? <(int, int, double?)>[]
        : moodByCycleDay(sel, logs, journal);
    final used = buckets.fold<int>(0, (a, b) => a + b.$2);
    final solid = [
      for (final b in buckets)
        if (b.$2 >= 2 && b.$3 != null) b
    ];

    String? insight;
    if (used >= 6 && solid.length >= 2) {
      final hi = solid.reduce((a, b) => b.$3! > a.$3! ? b : a),
          lo = solid.reduce((a, b) => b.$3! < a.$3! ? b : a);
      if (hi.$1 != lo.$1 && (hi.$3! - lo.$3!) >= .5) {
        insight =
            tr('Your mood tends to be best on day {0} after your dose (average {1}) ',
                    [hi.$1, hi.$3!.toStringAsFixed(1)]) +
                tr('and lowest on day {0} ({1}).',
                    [lo.$1, lo.$3!.toStringAsFixed(1)]);
      } else {
        insight = tr('Your mood stays fairly steady throughout the cycle.');
      }
    }

    Widget chart(List<(int, int, double?)> bs) {
      final cycle = bs.length;
      return SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          minY: 0,
          maxY: 5.5,
          gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: fg.withValues(alpha: .08), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, m) => Text(
                    v < 1 || v > 5 ? '' : '${v.toInt()}',
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: cycle > 14 ? 5 : 1,
                getTitlesWidget: (v, m) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 11))),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, gi, rod, ri) {
                final b = bs[g.x];
                return BarTooltipItem(
                  b.$3 == null
                      ? tr('Day {0}: no data yet', [b.$1])
                      : tr('Day {0}: {1} ({2} {2?entry|entries})',
                          [b.$1, b.$3!.toStringAsFixed(1), b.$2]),
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
                  color: b.$3 == null
                      ? Colors.transparent
                      : (b.$3! >= 3.5
                          ? Pastel.mint
                          : (b.$3! >= 2.5
                              ? fg.withValues(alpha: .4)
                              : C.amber)),
                ),
              ]),
          ],
        )),
      );
    }

    final last30Card = _card(tr('Last 30 days'), [
      if (total == 0)
        Text(tr(
            'Not enough data yet. Log your doses and journal for a few days to see a summary.'))
      else ...[
        Text.rich(TextSpan(
            text: '${(taken / total * 100).round()}%',
            style: tabular(display(44)),
            children: [
              TextSpan(
                  text: tr(' of doses logged'),
                  style: theme.textTheme.bodyMedium),
            ])),
        gap(10),
        Wrap(spacing: 8, runSpacing: 4, children: [
          Chip(
              label: Text(tr('{0} taken', [taken]),
                  style: tabular(const TextStyle())),
              side: BorderSide.none,
              backgroundColor: Pastel.mint.withValues(alpha: .18)),
          Chip(
              label: Text(tr('{0} skipped', [skipped]),
                  style: tabular(const TextStyle())),
              side: BorderSide.none,
              backgroundColor: fg.withValues(alpha: .07)),
          Chip(
              label: Text(tr('{0} missed', [missed]),
                  style: tabular(const TextStyle())),
              side: BorderSide.none,
              backgroundColor: C.amber.withValues(alpha: .18)),
        ]),
        gap(4),
        Text(
            tr('Estimated from fixed schedules. "As needed" doses aren\'t counted.'),
            style: theme.textTheme.bodySmall),
      ],
    ]);

    final mood30Card = _card(tr('Mood, last 30 days'), [
      if (moods30.isEmpty)
        Text(tr(
            'No mood entries yet. Log one from the card on the home screen.'))
      else
        for (final m in moods.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(m.value.$2, size: 20, color: moodColor(m.key)),
              const SizedBox(width: 10),
              SizedBox(
                  width: 56,
                  child:
                      Text(tr(m.value.$1), style: theme.textTheme.bodySmall)),
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
              Text('${moods30.where((x) => x == m.key).length}',
                  style: tabular(const TextStyle())),
            ]),
          ),
    ]);

    final cycleCard = _card(tr('Mood across your cycle'), [
      if (sel == null)
        Text(tr(
            'Needs a therapy with a repeating schedule (every 2 days or more).'))
      else ...[
        if (cyclic.length > 1)
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final t in cyclic)
              ChoiceChip(
                  label: Text(t.name),
                  selected: t.id == sel.id,
                  onSelected: (_) => setState(() => therapyId = t.id)),
          ]),
        if (cyclic.length > 1) gap(10),
        Text(tr('Average by days since your last dose (day 0 = dose day).'),
            style: theme.textTheme.bodySmall),
        gap(8),
        if (buckets.isEmpty)
          Text(tr('No doses logged for this therapy yet.'))
        else ...[
          chart(buckets),
          gap(6),
          Text(tr('Scale: 1 anxious, 2 low, 3 neutral, 4 calm, 5 happy.'),
              style: theme.textTheme.bodySmall),
          gap(10),
          Text(insight ??
              tr('Needs at least 6 mood entries after logged doses, and 2 entries on each day being compared. Currently {0} {0?entry|entries}.',
                  [used])),
          gap(8),
          Text(
              tr('This is a pattern from your own notes, not cause and effect. Many other things affect mood.'),
              style: theme.textTheme.bodySmall),
        ],
      ],
    ]);

    final phaseReport = analyzeCyclePhaseInsights(
      therapies: ths,
      logs: logs,
      journal: journal,
      now: now,
    );

    Widget phaseTile(PhaseInsightBucket b) {
      final (accent, icon) = switch (b.phase) {
        HormoneCyclePhase.peak => (C.rose, LucideIcons.sun),
        HormoneCyclePhase.mid => (C.lavender, LucideIcons.sparkles),
        HormoneCyclePhase.trough => (Pastel.mint, LucideIcons.moon),
      };
      final symLabel =
          b.topSymptomKey != null && symptomPresets.containsKey(b.topSymptomKey)
              ? tr(symptomPresets[b.topSymptomKey!]!.$1)
              : null;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.midnight.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    b.phase.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            gap(8),
            Text(
              b.avgMood != null ? '${b.avgMood!.toStringAsFixed(1)} / 5' : '—',
              style: tabular(display(24, color: Colors.white)),
            ),
            Text(
              tr('{0} {0?check-in|check-ins}', [b.entryCount]),
              style: tabular(theme.textTheme.bodySmall ?? const TextStyle()),
            ),
            if (symLabel != null) ...[
              gap(4),
              Text(
                '$symLabel (${b.topSymptomCount}x)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tabular(TextStyle(
                  fontSize: 11.5,
                  color: Pastel.mist.withValues(alpha: 0.85),
                )),
              ),
            ],
          ],
        ),
      );
    }

    final cyclePhaseCard = _card(tr('Hormone Phase & Mood Correlation'), [
      if (phaseReport == null || !phaseReport.hasEnoughData) ...[
        Text(
          tr('Log at least 3 mood or symptom check-ins alongside an active hormone curve to map Peak, Mid-cycle, and Trough patterns.'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Pastel.mist.withValues(alpha: 0.85),
          ),
        ),
        gap(12),
        OutlinedButton.icon(
          onPressed: () => showSheet(context, const JournalSheet()),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: Text(tr('Log today\'s mood')),
        ),
      ] else ...[
        Text(
          tr('Mapped from your simulated {0} curve over the last 90 days.', [
            phaseReport.hormoneName,
          ]),
          style: theme.textTheme.bodySmall,
        ),
        gap(12),
        AdaptiveGrid(
          compactColumns: 1,
          mediumColumns: 3,
          expandedColumns: 3,
          minColumnWidth: 180,
          spacing: 10,
          runSpacing: 10,
          children: [
            phaseTile(phaseReport.buckets[HormoneCyclePhase.peak]!),
            phaseTile(phaseReport.buckets[HormoneCyclePhase.mid]!),
            phaseTile(phaseReport.buckets[HormoneCyclePhase.trough]!),
          ],
        ),
        if (phaseReport.summaryHeadline != null) ...[
          gap(12),
          Text(
            phaseReport.summaryHeadline!,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
        if (phaseReport.clinicianNote != null) ...[
          gap(10),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(consultationProvider.notifier)
                  .addQuestion(phaseReport.clinicianNote!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(tr('Added phase observation to Consultation Prep.')),
                ),
              );
            },
            icon: const Icon(LucideIcons.stethoscope, size: 16),
            label: Text(tr('Add to Consultation Prep')),
          ),
        ],
      ],
    ]);

    final recap = computeMonthlyCalmRecap(
      year: _recapMonth.year,
      month: _recapMonth.month,
      logs: logs,
      journal: journal,
      workoutLogs: workout.logs,
      milestones: _milestones,
      moments: moments,
    );
    final isCurrentMonth =
        _recapMonth.year == now.year && _recapMonth.month == now.month;
    final monthLabel = DateFormat('MMMM y', L10n.code).format(_recapMonth);

    Widget recapStat(String value, String label, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.midnight.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: tabular(display(22, color: Colors.white))),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final monthlyRecapCard = _card(tr('Lunera Monthly Reflection'), [
      Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _recapMonth = DateTime(_recapMonth.year, _recapMonth.month - 1);
              });
            },
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
            tooltip: tr('Previous month'),
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: C.lavender,
              ),
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _recapMonth =
                          DateTime(_recapMonth.year, _recapMonth.month + 1);
                    });
                  },
            icon: const Icon(LucideIcons.chevronRight, size: 18),
            tooltip: tr('Next month'),
          ),
        ],
      ),
      gap(10),
      AdaptiveGrid(
        compactColumns: 1,
        mediumColumns: 2,
        expandedColumns: 4,
        minColumnWidth: 160,
        spacing: 10,
        runSpacing: 10,
        children: [
          recapStat('${recap.dosesLogged}', tr('Doses logged'),
              LucideIcons.pill, Pastel.mint),
          recapStat('${recap.journalCheckIns}', tr('Journal check-ins'),
              LucideIcons.heartHandshake, C.rose),
          recapStat(
              '${recap.movementSessions}',
              tr('Movement ({0}m)', [recap.movementMinutes]),
              LucideIcons.activity,
              C.violet),
          recapStat('${recap.milestonesAndMoments}', tr('Milestones & moments'),
              LucideIcons.sparkles, C.coral),
        ],
      ),
      if (recap.topMoodKey != null &&
          moodTypes.containsKey(recap.topMoodKey)) ...[
        gap(10),
        Text(
          tr('Most frequent mood: {0}', [tr(moodTypes[recap.topMoodKey!]!.$1)]),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: C.lavender,
          ),
        ),
      ],
      gap(8),
      Text(
        recap.closingAffirmation,
        style: TextStyle(
          fontSize: 12.5,
          color: Pastel.mist.withValues(alpha: 0.85),
          height: 1.4,
        ),
      ),
      gap(10),
      OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          final text = [
            'Lunera — $monthLabel',
            '• ${tr('Doses logged')}: ${recap.dosesLogged}',
            '• ${tr('Journal check-ins')}: ${recap.journalCheckIns}',
            '• ${tr('Movement')}: ${recap.movementSessions} (${recap.movementMinutes}m)',
            '• ${tr('Milestones & moments')}: ${recap.milestonesAndMoments}',
            if (recap.topMoodKey != null &&
                moodTypes.containsKey(recap.topMoodKey))
              '• ${tr('Most frequent mood: {0}', [
                    tr(moodTypes[recap.topMoodKey!]!.$1)
                  ])}',
            '',
            recap.closingAffirmation,
          ].join('\n');
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(tr('Monthly reflection copied to clipboard.'))),
          );
        },
        icon: const Icon(LucideIcons.copy, size: 15),
        label: Text(tr('Copy Reflection')),
      ),
    ]);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: context.pagePadding(top: 12, bottom: 32),
          children: [
            AdaptivePageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdaptivePageHeader(
                    title: tr('Insights'),
                    onBack: () => Navigator.pop(context),
                  ),
                  gap(16),
                  AdaptiveGrid(
                    compactColumns: 1,
                    mediumColumns: 2,
                    expandedColumns: 2,
                    minColumnWidth: 320,
                    children: [last30Card, mood30Card],
                  ),
                  gap(14),
                  cyclePhaseCard,
                  gap(14),
                  cycleCard,
                  gap(14),
                  monthlyRecapCard,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
