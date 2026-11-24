import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart' show IconData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'models.dart';
import 'profile.dart';
import 'repo.dart';
import 'schedule.dart';

/// Single observation cluster of symptoms logged in Journal entries over a lookback window.
class ClusteredSymptom {
  const ClusteredSymptom({
    required this.symptomKey,
    required this.symptomName,
    required this.icon,
    required this.count,
    required this.dates,
    this.cycleCorrelation,
    required this.suggestedQuestion,
  });

  final String symptomKey;
  final String symptomName;
  final IconData icon;
  final int count;
  final List<DateTime> dates;
  final String? cycleCorrelation;
  final String suggestedQuestion;
}

/// A specific question or topic planned for the clinician consultation.
class ConsultationQuestion {
  const ConsultationQuestion({
    required this.id,
    required this.text,
    this.isAsked = false,
    this.symptomKey,
  });

  final String id;
  final String text;
  final bool isAsked;
  final String? symptomKey;

  ConsultationQuestion copyWith({
    String? id,
    String? text,
    bool? isAsked,
    String? symptomKey,
  }) =>
      ConsultationQuestion(
        id: id ?? this.id,
        text: text ?? this.text,
        isAsked: isAsked ?? this.isAsked,
        symptomKey: symptomKey ?? this.symptomKey,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isAsked': isAsked,
        if (symptomKey != null) 'symptomKey': symptomKey,
      };

  factory ConsultationQuestion.fromMap(Map<String, dynamic> m) =>
      ConsultationQuestion(
        id: m['id'] as String? ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
        text: m['text'] as String? ?? '',
        isAsked: m['isAsked'] as bool? ?? false,
        symptomKey: m['symptomKey'] as String?,
      );
}

/// A preparatory or document checklist item for the medical appointment.
class ConsultationChecklistItem {
  const ConsultationChecklistItem({
    required this.id,
    required this.title,
    this.isChecked = false,
    this.isDefault = false,
  });

  final String id;
  final String title;
  final bool isChecked;
  final bool isDefault;

  ConsultationChecklistItem copyWith({
    String? id,
    String? title,
    bool? isChecked,
    bool? isDefault,
  }) =>
      ConsultationChecklistItem(
        id: id ?? this.id,
        title: title ?? this.title,
        isChecked: isChecked ?? this.isChecked,
        isDefault: isDefault ?? this.isDefault,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isChecked': isChecked,
        'isDefault': isDefault,
      };

  factory ConsultationChecklistItem.fromMap(Map<String, dynamic> m) =>
      ConsultationChecklistItem(
        id: m['id'] as String? ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
        title: m['title'] as String? ?? '',
        isChecked: m['isChecked'] as bool? ?? false,
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

/// An active or completed clinical consultation preparation session.
class ConsultationSession {
  const ConsultationSession({
    required this.id,
    this.scheduledAt,
    this.doctorOrClinic = '',
    this.questions = const [],
    this.checklist = const [],
    this.postVisitNotes = '',
    this.isCompleted = false,
  });

  final String id;
  final DateTime? scheduledAt;
  final String doctorOrClinic;
  final List<ConsultationQuestion> questions;
  final List<ConsultationChecklistItem> checklist;
  final String postVisitNotes;
  final bool isCompleted;

  ConsultationSession copyWith({
    String? id,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? doctorOrClinic,
    List<ConsultationQuestion>? questions,
    List<ConsultationChecklistItem>? checklist,
    String? postVisitNotes,
    bool? isCompleted,
  }) =>
      ConsultationSession(
        id: id ?? this.id,
        scheduledAt:
            clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
        doctorOrClinic: doctorOrClinic ?? this.doctorOrClinic,
        questions: questions ?? this.questions,
        checklist: checklist ?? this.checklist,
        postVisitNotes: postVisitNotes ?? this.postVisitNotes,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
        'doctorOrClinic': doctorOrClinic,
        'questions': [for (final q in questions) q.toMap()],
        'checklist': [for (final c in checklist) c.toMap()],
        'postVisitNotes': postVisitNotes,
        'isCompleted': isCompleted,
      };

  factory ConsultationSession.fromMap(Map<String, dynamic> m) =>
      ConsultationSession(
        id: m['id'] as String? ?? 'session_default',
        scheduledAt: m['scheduledAt'] is String
            ? DateTime.tryParse(m['scheduledAt'] as String)
            : null,
        doctorOrClinic: m['doctorOrClinic'] as String? ?? '',
        questions: m['questions'] is List
            ? [
                for (final q in m['questions'] as List)
                  if (q is Map)
                    ConsultationQuestion.fromMap(q.cast<String, dynamic>())
              ]
            : const [],
        checklist: m['checklist'] is List
            ? [
                for (final c in m['checklist'] as List)
                  if (c is Map)
                    ConsultationChecklistItem.fromMap(c.cast<String, dynamic>())
              ]
            : const [],
        postVisitNotes: m['postVisitNotes'] as String? ?? '',
        isCompleted: m['isCompleted'] as bool? ?? false,
      );
}

/// Returns standard default checklist items for an HRT appointment.
List<ConsultationChecklistItem> defaultConsultationChecklist() => [
      ConsultationChecklistItem(
        id: 'chk_labs',
        title: tr('Recent blood work / lab results printout or digital copy'),
        isDefault: true,
      ),
      ConsultationChecklistItem(
        id: 'chk_regimen',
        title: tr('Current HRT medication list with exact dose and schedule'),
        isDefault: true,
      ),
      ConsultationChecklistItem(
        id: 'chk_id_card',
        title: tr('Government photo ID and insurance / clinic card'),
        isDefault: true,
      ),
      ConsultationChecklistItem(
        id: 'chk_refills',
        title: tr('Prescription refill quantities and preferred pharmacy'),
        isDefault: true,
      ),
      ConsultationChecklistItem(
        id: 'chk_report',
        title: tr('Printed or digital Lunera Doctor Summary Report'),
        isDefault: true,
      ),
    ];

/// Standard suggested topics for quick one-tap addition.
List<String> defaultSuggestedTopics() => [
      tr('Review recent hormone blood test levels against target ranges'),
      tr('Discuss dosage adjustment or regimen optimization'),
      tr('Evaluate energy, mood rhythm, and physical changes'),
      tr('Check injection site tissue and needle supplies renewal'),
      tr('Request prescription renewal for the next 3–6 months'),
    ];

/// Pure algorithm clustering journal symptoms over [lookbackDays] and detecting dose cycle correlations.
List<ClusteredSymptom> clusterJournalSymptoms({
  required List<JournalEntry> journal,
  required List<DoseLog> logs,
  List<Therapy> therapies = const [],
  DateTime? now,
  int lookbackDays = 90,
}) {
  final referenceTime = now ?? DateTime.now();
  final cutoff = referenceTime.subtract(Duration(days: lookbackDays));

  // 1. Group occurrences by symptom key
  final Map<String, List<DateTime>> symptomDates = {};
  for (final entry in journal) {
    if (entry.at.isBefore(cutoff) || entry.at.isAfter(referenceTime)) continue;
    for (final sym in entry.symptoms) {
      if (symptomPresets.containsKey(sym)) {
        (symptomDates[sym] ??= []).add(entry.at);
      }
    }
  }

  // Filter valid taken logs and sort ascending
  final validLogs = logs.where((l) => !l.skipped).toList()
    ..sort((a, b) => a.at.compareTo(b.at));

  final List<ClusteredSymptom> clusters = [];

  for (final entry in symptomDates.entries) {
    final symKey = entry.key;
    final dates = entry.value..sort();
    final count = dates.length;
    if (count == 0) continue;

    final preset = symptomPresets[symKey]!;
    final symName = tr(preset.$1);
    final icon = preset.$2;

    int nearDoseCount = 0; // within 2 days after dose
    int lateCycleCount = 0; // late in dose cycle (near trough)
    int midCycleCount = 0;

    for (final symDate in dates) {
      DoseLog? priorDose;
      for (final log in validLogs.reversed) {
        if (!log.at.isAfter(symDate)) {
          priorDose = log;
          break;
        }
      }

      if (priorDose != null) {
        final therapy =
            therapies.where((t) => t.id == priorDose!.therapyId).firstOrNull;
        final isDaily =
            therapy != null && (therapy.daily || cycleOf(therapy) <= 1);
        if (isDaily) {
          // Daily therapies have no distinct cycle phases (near-dose vs trough)
          continue;
        }
        final cycleDays = therapy != null ? cycleOf(therapy) : 7;
        final troughThreshold = math.max(3, cycleDays - 2);

        final daysAfter = symDate.difference(priorDose.at).inDays;
        if (daysAfter <= 2) {
          nearDoseCount++;
        } else if (daysAfter >= troughThreshold) {
          lateCycleCount++;
        } else {
          midCycleCount++;
        }
      }
    }

    String? correlation;
    if (validLogs.isNotEmpty && count >= 2) {
      if (nearDoseCount / count >= 0.5) {
        correlation = tr('Frequently occurs within 1–2 days after dose');
      } else if (lateCycleCount / count >= 0.5) {
        correlation = tr('Tends to occur late in dose cycle (near trough)');
      } else if (midCycleCount / count >= 0.5) {
        correlation = tr('Frequently occurs mid-cycle');
      }
    }

    final String question;
    if (correlation != null) {
      question = tr(
        'I noticed {0} ({1}x recently, {2}). Is this expected or related to my dosage rhythm?',
        [symName, count, correlation.toLowerCase()],
      );
    } else if (count >= 3) {
      question = tr(
        'I experienced {0} {1} times in recent weeks. Should we explore managing this?',
        [symName, count],
      );
    } else {
      question = tr(
        'I experienced {0} recently. Is this common with my current regimen?',
        [symName],
      );
    }

    clusters.add(ClusteredSymptom(
      symptomKey: symKey,
      symptomName: symName,
      icon: icon,
      count: count,
      dates: dates,
      cycleCorrelation: correlation,
      suggestedQuestion: question,
    ));
  }

  clusters.sort((a, b) => b.count.compareTo(a.count));
  return clusters;
}

const String _kConsultationPrefsKey = 'lunera_consultation_session';

/// Riverpod controller managing consultation preparation state with persistent storage.
class ConsultationController extends Notifier<ConsultationSession> {
  SharedPreferences? _getPrefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  String _storageKey() {
    String? uid;
    try {
      uid = ref.watch(userProvider).value?.uid;
    } catch (_) {}
    if (uid != null && uid.isNotEmpty) {
      return '${_kConsultationPrefsKey}_$uid';
    }
    return _kConsultationPrefsKey;
  }

  @override
  ConsultationSession build() {
    final prefs = _getPrefs();
    if (prefs != null) {
      final key = _storageKey();
      // Legacy migration: if scoped key is empty but un-scoped legacy key exists, migrate it
      if (key != _kConsultationPrefsKey && !prefs.containsKey(key) && prefs.containsKey(_kConsultationPrefsKey)) {
        final legacy = prefs.getString(_kConsultationPrefsKey);
        if (legacy != null) {
          prefs.setString(key, legacy);
          prefs.remove(_kConsultationPrefsKey);
        }
      }
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return ConsultationSession.fromMap(map);
        } catch (_) {}
      }
    }
    return ConsultationSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      checklist: defaultConsultationChecklist(),
    );
  }

  Future<void> _persist() async {
    final prefs = _getPrefs() ?? await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(), jsonEncode(state.toMap()));
  }

  void updateDoctorOrClinic(String name) {
    state = state.copyWith(doctorOrClinic: name.trim());
    _persist();
  }

  void updateScheduledAt(DateTime? date) {
    state = state.copyWith(
      scheduledAt: date,
      clearScheduledAt: date == null,
    );
    _persist();
  }

  void addQuestion(String text, {String? symptomKey}) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final newQ = ConsultationQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}_${state.questions.length}',
      text: clean,
      symptomKey: symptomKey,
    );
    state = state.copyWith(questions: [...state.questions, newQ]);
    _persist();
  }

  void toggleQuestion(String id) {
    state = state.copyWith(
      questions: [
        for (final q in state.questions)
          if (q.id == id) q.copyWith(isAsked: !q.isAsked) else q,
      ],
    );
    _persist();
  }

  void removeQuestion(String id) {
    state = state.copyWith(
      questions: [for (final q in state.questions) if (q.id != id) q],
    );
    _persist();
  }

  void toggleChecklistItem(String id) {
    state = state.copyWith(
      checklist: [
        for (final item in state.checklist)
          if (item.id == id)
            item.copyWith(isChecked: !item.isChecked)
          else
            item,
      ],
    );
    _persist();
  }

  void addChecklistItem(String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    final newItem = ConsultationChecklistItem(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}_${state.checklist.length}',
      title: clean,
    );
    state = state.copyWith(checklist: [...state.checklist, newItem]);
    _persist();
  }

  void removeChecklistItem(String id) {
    state = state.copyWith(
      checklist: [for (final c in state.checklist) if (c.id != id) c],
    );
    _persist();
  }

  void updatePostVisitNotes(String notes) {
    state = state.copyWith(postVisitNotes: notes);
    _persist();
  }

  void toggleCompleted() {
    state = state.copyWith(isCompleted: !state.isCompleted);
    _persist();
  }

  void resetSession() {
    state = ConsultationSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      checklist: defaultConsultationChecklist(),
    );
    _persist();
  }

  static String _resolveStorageKey([String? uid]) {
    if (uid != null && uid.isNotEmpty) {
      return '${_kConsultationPrefsKey}_$uid';
    }
    return _kConsultationPrefsKey;
  }

  static Future<ConsultationSession?> loadDirect(
      [String? uid, SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final key = _resolveStorageKey(uid);
    if (key != _kConsultationPrefsKey &&
        !p.containsKey(key) &&
        p.containsKey(_kConsultationPrefsKey)) {
      final legacy = p.getString(_kConsultationPrefsKey);
      if (legacy != null) {
        p.setString(key, legacy);
        p.remove(_kConsultationPrefsKey);
      }
    }
    final raw = p.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return ConsultationSession.fromMap(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> importSession(
    Map<String, dynamic> rawSession, {
    required bool replace,
    String? uid,
    SharedPreferences? prefs,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final key = _resolveStorageKey(uid);
    final incoming = ConsultationSession.fromMap(rawSession);
    if (replace) {
      await p.setString(key, jsonEncode(incoming.toMap()));
    } else {
      final existing = await loadDirect(uid, p);
      if (existing == null) {
        await p.setString(key, jsonEncode(incoming.toMap()));
      } else {
        final existingQIds = {for (final q in existing.questions) q.id};
        final existingCIds = {for (final c in existing.checklist) c.id};
        final mergedQuestions = [
          ...existing.questions,
          ...incoming.questions.where((q) => !existingQIds.contains(q.id)),
        ];
        final mergedChecklist = [
          ...existing.checklist,
          ...incoming.checklist.where((c) => !existingCIds.contains(c.id)),
        ];
        final merged = existing.copyWith(
          scheduledAt: incoming.scheduledAt ?? existing.scheduledAt,
          doctorOrClinic: incoming.doctorOrClinic.isNotEmpty
              ? incoming.doctorOrClinic
              : existing.doctorOrClinic,
          questions: mergedQuestions,
          checklist: mergedChecklist,
          postVisitNotes: incoming.postVisitNotes.isNotEmpty
              ? incoming.postVisitNotes
              : existing.postVisitNotes,
        );
        await p.setString(key, jsonEncode(merged.toMap()));
      }
    }
  }

  /// Purges local stored consultation session for [uid] on logout.
  static Future<void> clearLocal([String? uid, SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (uid != null && uid.isNotEmpty) {
      await p.remove('${_kConsultationPrefsKey}_$uid');
    }
    await p.remove(_kConsultationPrefsKey);
  }
}

final consultationProvider =
    NotifierProvider<ConsultationController, ConsultationSession>(
        ConsultationController.new);
