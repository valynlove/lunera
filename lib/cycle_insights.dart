import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'l10n.dart';
import 'milestones.dart';
import 'models.dart';
import 'moments.dart';
import 'schedule.dart';
import 'sim.dart';

/// Broad pharmacokinetic phase across a hormone dosing cycle.
enum HormoneCyclePhase { peak, mid, trough }

extension HormoneCyclePhaseMeta on HormoneCyclePhase {
  String get label => switch (this) {
        HormoneCyclePhase.peak => tr('Peak window'),
        HormoneCyclePhase.mid => tr('Mid-cycle'),
        HormoneCyclePhase.trough => tr('Trough window'),
      };

  String get shortLabel => switch (this) {
        HormoneCyclePhase.peak => tr('Peak'),
        HormoneCyclePhase.mid => tr('Mid'),
        HormoneCyclePhase.trough => tr('Trough'),
      };
}

/// Aggregated mood and symptom summary for a single [HormoneCyclePhase].
class PhaseInsightBucket {
  const PhaseInsightBucket({
    required this.phase,
    required this.entryCount,
    required this.moodCount,
    this.avgMood,
    this.topSymptomKey,
    this.topSymptomCount = 0,
  });

  final HormoneCyclePhase phase;
  final int entryCount;
  final int moodCount;
  final double? avgMood;
  final String? topSymptomKey;
  final int topSymptomCount;
}

/// Non-diagnostic correlation summary between simulated hormone phases and journal check-ins.
class CyclePhaseReport {
  const CyclePhaseReport({
    required this.hormoneId,
    required this.hormoneName,
    required this.totalEntries,
    required this.buckets,
    this.summaryHeadline,
    this.clinicianNote,
  });

  final String hormoneId;
  final String hormoneName;
  final int totalEntries;
  final Map<HormoneCyclePhase, PhaseInsightBucket> buckets;
  final String? summaryHeadline;
  final String? clinicianNote;

  bool get hasEnoughData =>
      totalEntries >= 3 &&
      buckets.values.where((b) => b.entryCount > 0).length >= 2;
}

String? _pickPrimarySimHormone(List<Therapy> therapies) {
  const preferredOrder = ['estradiol', 'testosterone', 'progesterone'];
  final available = <String>{
    for (final t in therapies)
      if (!t.asNeeded) ...[
        if (pkOf(t.pk) != null) t.hormoneId,
        if (pkOf(t.secondaryPk) != null && t.secondaryHormoneId != null)
          t.secondaryHormoneId!,
      ],
  };
  for (final h in preferredOrder) {
    if (available.contains(h)) {
      return h;
    }
  }
  return available.firstOrNull;
}

/// Analyzes mood and symptom patterns across simulated Peak, Mid-cycle, and Trough windows.
CyclePhaseReport? analyzeCyclePhaseInsights({
  required List<Therapy> therapies,
  required List<DoseLog> logs,
  required List<JournalEntry> journal,
  DateTime? now,
  int lookbackDays = 90,
}) {
  final hormoneId = _pickPrimarySimHormone(therapies);
  if (hormoneId == null) {
    return null;
  }
  final intakes = intakesFor(hormoneId, therapies, logs);
  if (intakes.isEmpty) {
    return null;
  }

  final refNow = now ?? DateTime.now();
  final cutoff = refNow.subtract(Duration(days: lookbackDays));
  final spots = simSpots(intakes, cutoff, refNow, n: 240);
  final range = peakTrough(spots);
  if (range == null || range.peak <= 0) {
    return null;
  }
  final span = range.peak - range.trough;

  final entryCounts = <HormoneCyclePhase, int>{
    HormoneCyclePhase.peak: 0,
    HormoneCyclePhase.mid: 0,
    HormoneCyclePhase.trough: 0,
  };
  final moodSums = <HormoneCyclePhase, double>{
    HormoneCyclePhase.peak: 0,
    HormoneCyclePhase.mid: 0,
    HormoneCyclePhase.trough: 0,
  };
  final moodCounts = <HormoneCyclePhase, int>{
    HormoneCyclePhase.peak: 0,
    HormoneCyclePhase.mid: 0,
    HormoneCyclePhase.trough: 0,
  };
  final symptomCounts = <HormoneCyclePhase, Map<String, int>>{
    HormoneCyclePhase.peak: {},
    HormoneCyclePhase.mid: {},
    HormoneCyclePhase.trough: {},
  };

  var usedEntries = 0;
  for (final entry in journal) {
    if (entry.at.isBefore(cutoff) || entry.at.isAfter(refNow)) {
      continue;
    }
    if (!entry.hasMood && !entry.hasSymptoms) {
      continue;
    }
    final lvl = levelAt(intakes, entry.at);
    if (lvl <= 0) {
      continue;
    }

    final rel = span > 1e-6 ? ((lvl - range.trough) / span).clamp(0.0, 1.0) : 0.5;
    final HormoneCyclePhase phase;
    if (rel >= 0.68) {
      phase = HormoneCyclePhase.peak;
    } else if (rel <= 0.32) {
      phase = HormoneCyclePhase.trough;
    } else {
      phase = HormoneCyclePhase.mid;
    }

    usedEntries++;
    entryCounts[phase] = entryCounts[phase]! + 1;
    final score = moodScore[entry.mood];
    if (score != null) {
      moodSums[phase] = moodSums[phase]! + score;
      moodCounts[phase] = moodCounts[phase]! + 1;
    }
    for (final sym in entry.symptoms) {
      if (symptomPresets.containsKey(sym)) {
        final map = symptomCounts[phase]!;
        map[sym] = (map[sym] ?? 0) + 1;
      }
    }
  }

  final buckets = <HormoneCyclePhase, PhaseInsightBucket>{};
  for (final phase in HormoneCyclePhase.values) {
    final mCount = moodCounts[phase]!;
    final symMap = symptomCounts[phase]!;
    String? topKey;
    var topCount = 0;
    for (final e in symMap.entries) {
      if (e.value > topCount) {
        topKey = e.key;
        topCount = e.value;
      }
    }
    buckets[phase] = PhaseInsightBucket(
      phase: phase,
      entryCount: entryCounts[phase]!,
      moodCount: mCount,
      avgMood: mCount > 0 ? moodSums[phase]! / mCount : null,
      topSymptomKey: topKey,
      topSymptomCount: topCount,
    );
  }

  final hName = presetOf(hormoneId).name;
  final peakB = buckets[HormoneCyclePhase.peak]!;
  final troughB = buckets[HormoneCyclePhase.trough]!;

  String? headline;
  String? clinicianNote;
  if (usedEntries >= 3) {
    if (peakB.avgMood != null &&
        troughB.avgMood != null &&
        (peakB.avgMood! - troughB.avgMood!).abs() >= 0.5) {
      final pStr = peakB.avgMood!.toStringAsFixed(1);
      final tStr = troughB.avgMood!.toStringAsFixed(1);
      if (peakB.avgMood! > troughB.avgMood!) {
        headline = tr(
          'Mood tends to feel brighter near peak ({0}/5) than during trough windows ({1}/5).',
          [pStr, tStr],
        );
      } else {
        headline = tr(
          'Mood tends to feel steadier near trough ({0}/5) than around peak ({1}/5).',
          [tStr, pStr],
        );
      }
      clinicianNote = tr(
        'Cycle-aware observation ({0}): average mood is {1}/5 near peak vs {2}/5 in trough windows over {3} days.',
        [hName, pStr, tStr, lookbackDays],
      );
    } else if (troughB.topSymptomKey != null && troughB.topSymptomCount >= 2) {
      final symLabel = tr(symptomPresets[troughB.topSymptomKey!]!.$1);
      headline = tr(
        '{0} appears most often during trough windows ({1}x in the last {2} days).',
        [symLabel, troughB.topSymptomCount, lookbackDays],
      );
      clinicianNote = tr(
        'Cycle-aware observation ({0}): "{1}" was logged {2}x during trough windows.',
        [hName, symLabel, troughB.topSymptomCount],
      );
    } else {
      headline = tr(
        'Your mood and check-ins stay relatively steady across {0} cycle phases.',
        [hName],
      );
      clinicianNote = tr(
        'Cycle-aware observation ({0}): check-ins stay steady across {1} entries over {2} days.',
        [hName, usedEntries, lookbackDays],
      );
    }
  }

  return CyclePhaseReport(
    hormoneId: hormoneId,
    hormoneName: hName,
    totalEntries: usedEntries,
    buckets: buckets,
    summaryHeadline: headline,
    clinicianNote: clinicianNote,
  );
}

/// Guilt-free monthly recap summarizing self-care moments without streak pressure.
class MonthlyCalmRecap {
  const MonthlyCalmRecap({
    required this.year,
    required this.month,
    required this.dosesLogged,
    required this.journalCheckIns,
    required this.movementSessions,
    required this.movementMinutes,
    required this.milestonesAndMoments,
    this.topMoodKey,
    required this.closingAffirmation,
  });

  final int year;
  final int month;
  final int dosesLogged;
  final int journalCheckIns;
  final int movementSessions;
  final int movementMinutes;
  final int milestonesAndMoments;
  final String? topMoodKey;
  final String closingAffirmation;

  bool get isEmpty =>
      dosesLogged == 0 &&
      journalCheckIns == 0 &&
      movementSessions == 0 &&
      milestonesAndMoments == 0;
}

MonthlyCalmRecap computeMonthlyCalmRecap({
  required int year,
  required int month,
  required List<DoseLog> logs,
  required List<JournalEntry> journal,
  List<WorkoutSessionLog> workoutLogs = const [],
  List<TransitionMilestone> milestones = const [],
  List<Moment> moments = const [],
}) {
  bool inMonth(DateTime d) => d.year == year && d.month == month;

  final dosesLogged = logs.where((l) => !l.skipped && inMonth(l.at)).length;
  final monthJournal = journal.where((e) => inMonth(e.at)).toList();
  final monthWorkouts = workoutLogs.where((w) => inMonth(w.at)).toList();
  final totalSec = monthWorkouts.fold<int>(0, (s, w) => s + w.durationSec);
  final milestoneCount = milestones.where((m) => inMonth(m.at)).length;
  final momentCount = moments.where((m) => inMonth(m.at)).length;

  final moodCounts = <String, int>{};
  for (final e in monthJournal) {
    if (e.mood != null && moodTypes.containsKey(e.mood)) {
      moodCounts[e.mood!] = (moodCounts[e.mood!] ?? 0) + 1;
    }
  }
  String? topMood;
  var bestMoodCount = 0;
  for (final entry in moodCounts.entries) {
    if (entry.value > bestMoodCount) {
      topMood = entry.key;
      bestMoodCount = entry.value;
    }
  }

  final totalSignals =
      dosesLogged + monthJournal.length + monthWorkouts.length + milestoneCount + momentCount;
  final String closing;
  if (totalSignals == 0) {
    closing = tr(
      'Quiet months count too. Whenever you log a dose, breath, or note, it will appear gently here.',
    );
  } else if (monthWorkouts.isNotEmpty && dosesLogged > 0) {
    closing = tr(
      'You cared for your rhythm and movement at your own pace this month—every quiet step counted.',
    );
  } else {
    closing = tr(
      'Thank you for showing up gently for yourself this month. Progress never needs perfection.',
    );
  }

  return MonthlyCalmRecap(
    year: year,
    month: month,
    dosesLogged: dosesLogged,
    journalCheckIns: monthJournal.length,
    movementSessions: monthWorkouts.length,
    movementMinutes: math.max(0, (totalSec / 60).round()),
    milestonesAndMoments: milestoneCount + momentCount,
    topMoodKey: topMood,
    closingAffirmation: closing,
  );
}

/// Formats a compact plain-text Quick Clinic / Care Card summary for clipboard sharing.
String formatQuickCareCard({
  required List<Therapy> therapies,
  required List<Lab> labs,
  required Map<String, List<double>> targets,
  required Prefs prefs,
  DateTime? now,
}) {
  final df = DateFormat('d MMM y', L10n.code);
  final buf = StringBuffer()
    ..writeln('Lunera — ${tr('Quick Clinic Care Card')}')
    ..writeln('${tr('Updated')}: ${df.format(now ?? DateTime.now())}')
    ..writeln();

  buf.writeln('${tr('Active Regimen')}:');
  if (therapies.isEmpty) {
    buf.writeln('- ${tr('None')}');
  } else {
    for (final t in therapies) {
      buf.writeln(
        '- ${t.name}: ${fmt(t.dose)} ${t.doseUnit} (${routeOf(t.route).label}, ${scheduleText(t)})',
      );
    }
  }

  final latestByHormone = <String, Lab>{};
  final sortedLabs = [...labs]..sort((a, b) => b.at.compareTo(a.at));
  for (final l in sortedLabs) {
    latestByHormone.putIfAbsent(l.hormoneId, () => l);
  }

  buf
    ..writeln()
    ..writeln('${tr('Latest Lab Results')}:');
  if (latestByHormone.isEmpty) {
    buf.writeln('- ${tr('No lab results recorded')}');
  } else {
    for (final entry in latestByHormone.entries) {
      final p = presetOf(entry.key);
      final l = entry.value;
      final u = prefs.unitOf(entry.key);
      final f = p.units[u] ?? 1.0;
      final band = targets[entry.key];
      var status = '';
      if (band != null && l.cmp == null) {
        status = (l.base >= band[0] && l.base <= band[1])
            ? ' [${tr('In range')}]'
            : (l.base < band[0]
                ? ' [${tr('Below target')}]'
                : ' [${tr('Above target')}]');
      }
      buf.writeln(
        '- ${p.name}: ${l.prefix}${fmt(l.base / f)} $u (${df.format(l.at)})$status',
      );
    }
  }

  if (prefs.careAllergies.trim().isNotEmpty) {
    buf
      ..writeln()
      ..writeln('${tr('Allergies & Sensitivities')}:')
      ..writeln(prefs.careAllergies.trim());
  }
  if (prefs.careClinicInfo.trim().isNotEmpty) {
    buf
      ..writeln()
      ..writeln('${tr('Clinic & Pharmacy')}:')
      ..writeln(prefs.careClinicInfo.trim());
  }

  return buf.toString().trimRight();
}
