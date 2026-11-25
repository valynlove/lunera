import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'models.dart';
import 'notifications.dart';
import 'profile.dart';
import 'repo.dart';
import 'schedule.dart';
import 'workout_catalog.dart';

/// Expressions for the sporty Lunera Personal Coach mascot.
enum CoachMood {
  greet,
  explain,
  care,
  cheer,
  hydrate,
  celebrate,
  think,
  proud,
  ready,
  focus,
  breathe,
  stretch,
  gentle,
  effort,
  rest,
  listen,
}

/// Classification of the Coach's daily contextual recommendation.
enum CoachContextKind {
  restedToday,
  injectionCare,
  troughGentle,
  easeBackIn,
  scheduledToday,
  readyAnytime,
}

/// Daily HRT-aware coaching summary produced by [evaluateCoachContext].
class CoachRecommendation {
  const CoachRecommendation({
    required this.kind,
    required this.coachMood,
    required this.headline,
    required this.message,
    required this.recommendedRoutine,
    required this.suggestLightMode,
    required this.totalSessions,
    required this.sessionsThisMonth,
    required this.activeDaysThisMonth,
    this.contextBadge,
    this.avoidedZone,
    this.injectionSite,
    this.daysSinceLastWorkout,
  });

  final CoachContextKind kind;
  final CoachMood coachMood;
  final String headline;
  final String message;
  final String? contextBadge;
  final String? avoidedZone; // 'lower' | 'upper' | 'core'
  final String? injectionSite;
  final WorkoutRoutine recommendedRoutine;
  final bool suggestLightMode;
  final int? daysSinceLastWorkout;
  final int totalSessions;
  final int sessionsThisMonth;
  final int activeDaysThisMonth;
}

/// Formats [d] as YYYY-MM-DD in local time for guilt-free rest-day checks.
String isoDateOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Pure baseline fitness calibration from 3 quick comfort checks.
///
/// Each input is rated 0 (gentle), 1 (steady), or 2 (active).
String calibrateBaselineLevel({
  required int squatComfort,
  required int pushupComfort,
  required int plankComfort,
}) {
  final score =
      squatComfort.clamp(0, 2) + pushupComfort.clamp(0, 2) + plankComfort.clamp(0, 2);
  if (score >= 5) return 'active';
  if (score >= 2) return 'steady';
  return 'gentle';
}

/// Reduces sets (~35%) and reps/seconds (~20%) safely for Light Mode days.
WorkoutRoutine applyLightMode(WorkoutRoutine routine) {
  return routine.copyWith(
    estimatedMinutes: math.max(6, (routine.estimatedMinutes * 0.65).round()),
    items: [
      for (final item in routine.items)
        item.copyWith(
          sets: math.max(1, (item.sets * 0.65).round()),
          reps: item.reps != null ? math.max(5, (item.reps! * 0.8).round()) : null,
          seconds: item.seconds != null
              ? math.max(15, (item.seconds! * 0.75).round())
              : null,
          useEasierVariant: true,
        ),
    ],
  );
}

/// Updates [profile] after a completed session's effort feedback without punishment.
(WorkoutProfile nextProfile, String? notice) applyEffortFeedback(
  WorkoutProfile profile,
  String effort,
) {
  if (effort == 'easy') {
    final nextEasy = profile.consecutiveEasyCount + 1;
    if (nextEasy >= 2 && profile.level != 'active') {
      final nextLevel = profile.level == 'gentle' ? 'steady' : 'active';
      return (
        profile.copyWith(level: nextLevel, consecutiveEasyCount: 0),
        tr('Pacing gently tuned up to {0} based on your steady progress.', [
          paceLabel(nextLevel),
        ]),
      );
    }
    return (
      profile.copyWith(consecutiveEasyCount: nextEasy),
      nextEasy == 1
          ? tr('Noted! One more easy session will gently nudge your pace up.')
          : null,
    );
  }
  if (effort == 'tough') {
    return (
      profile.copyWith(consecutiveEasyCount: 0),
      tr('Great effort. We will keep your current pace steady and comfortable.'),
    );
  }
  return (
    profile.copyWith(consecutiveEasyCount: 0),
    tr('Right in the sweet spot—your current target pace fits well.'),
  );
}

String? _zoneForInjectionSite(String site) {
  final lower = site.toLowerCase();
  if (lower.contains('thigh') ||
      lower.contains('buttock') ||
      lower.contains('glute') ||
      lower.contains('paha') ||
      lower.contains('bokong')) {
    return 'lower';
  }
  if (lower.contains('arm') ||
      lower.contains('deltoid') ||
      lower.contains('lengan')) {
    return 'upper';
  }
  if (lower.contains('abdomen') ||
      lower.contains('stomach') ||
      lower.contains('perut')) {
    return 'core';
  }
  return null;
}

/// Evaluates HRT schedule, recent injection site, trough timing, and workout gap
/// to craft today's guilt-free Personal Coach plan.
CoachRecommendation evaluateCoachContext({
  required DateTime now,
  required WorkoutProfile profile,
  required List<WorkoutSessionLog> workoutLogs,
  required List<Therapy> therapies,
  required List<DoseLog> doseLogs,
  required Prefs prefs,
  List<WorkoutRoutine> customRoutines = const [],
}) {
  final sortedLogs = [...workoutLogs]..sort((a, b) => b.at.compareTo(a.at));
  final lastWorkout = sortedLogs.firstOrNull;
  final daysSinceLast =
      lastWorkout == null ? null : math.max(0, daysBetween(lastWorkout.at, now));

  final monthLogs = sortedLogs
      .where((l) => l.at.year == now.year && l.at.month == now.month)
      .toList();
  final activeDays = {
    for (final l in monthLogs) isoDateOf(l.at),
  }.length;

  final presets = buildPresetRoutines(
    profile.level,
    equipment: profile.equipment,
  );
  WorkoutRoutine presetFor(String category) => presets.firstWhere(
        (r) => r.category == category,
        orElse: () => presets.first,
      );

  final todayIso = isoDateOf(now);
  final primaryRoutine = presetFor(profile.focus);

  // 1. User explicitly chose "Rest today" — validate rest warmly, zero guilt.
  if (profile.skippedDateIso == todayIso) {
    return CoachRecommendation(
      kind: CoachContextKind.restedToday,
      coachMood: CoachMood.rest,
      headline: tr('Rest day honored'),
      message: tr(
        'Recovery is part of building strength. Whenever you feel like stretching, I am right here.',
      ),
      contextBadge: tr('Resting today'),
      recommendedRoutine: presetFor('recovery'),
      suggestLightMode: true,
      daysSinceLastWorkout: daysSinceLast,
      totalSessions: sortedLogs.length,
      sessionsThisMonth: monthLogs.length,
      activeDaysThisMonth: activeDays,
    );
  }

  // 2. Check recent injection (<24h) OR scheduled injection today.
  final therapyById = {for (final t in therapies) t.id: t};
  DoseLog? recentInjection;
  for (final l in doseLogs) {
    if (l.skipped) continue;
    final t = therapyById[l.therapyId];
    final isInj = t?.route == 'inj' || l.injType != null;
    if (!isInj) continue;
    final diffHours = now.difference(l.at).inHours;
    if (diffHours >= 0 && diffHours <= 24) {
      if (recentInjection == null || l.at.isAfter(recentInjection.at)) {
        recentInjection = l;
      }
    }
  }

  final slots = buildSlots(therapies, doseLogs, prefs, back: 0, ahead: 3);
  Slot? todayInjectionSlot;
  for (final s in slots) {
    if (s.pending && s.t.route == 'inj' && sameDay(s.at, now)) {
      todayInjectionSlot = s;
      break;
    }
  }

  if (recentInjection != null || todayInjectionSlot != null) {
    final descLogs = [...doseLogs]..sort((a, b) => b.at.compareTo(a.at));
    final site = recentInjection != null && recentInjection.site.isNotEmpty
        ? recentInjection.site
        : (todayInjectionSlot != null && todayInjectionSlot.t.adm.places
            ? suggestPlace(prefs, descLogs, todayInjectionSlot.t.id)
            : '');
    final avoided = _zoneForInjectionSite(site);
    final safeRoutine = switch (avoided) {
      'lower' => profile.focus == 'feminizing'
          ? presetFor('recovery')
          : presetFor('masculinizing'),
      'upper' => presetFor('feminizing'),
      _ => presetFor('recovery'),
    };
    final siteLabel = site.isEmpty ? tr('injection site') : tr(site);
    final msg = avoided == 'lower'
        ? tr(
            'You have an injection around {0}. Let us protect that tissue—choose gentle mobility, upper body, or take a full rest day.',
            [siteLabel],
          )
        : avoided == 'upper'
            ? tr(
                'You have an injection around {0}. Let us stick to lower body or gentle mobility today, or rest comfortably.',
                [siteLabel],
              )
            : tr(
                'It is an injection day. Gentle recovery movement is plenty, and resting today is completely fine.',
              );
    return CoachRecommendation(
      kind: CoachContextKind.injectionCare,
      coachMood: CoachMood.care,
      headline: tr('Injection-day care'),
      message: msg,
      contextBadge: tr('Injection care'),
      avoidedZone: avoided,
      injectionSite: site.isEmpty ? null : site,
      recommendedRoutine: safeRoutine,
      suggestLightMode: true,
      daysSinceLastWorkout: daysSinceLast,
      totalSessions: sortedLogs.length,
      sessionsThisMonth: monthLogs.length,
      activeDaysThisMonth: activeDays,
    );
  }

  // 3. Check trough window (within 24h before next multi-day dose).
  final nearTrough = slots.any((s) {
    if (!s.pending) return false;
    if (cycleOf(s.t) < 4) return false;
    final hoursUntil = s.at.difference(now).inHours;
    return hoursUntil >= 0 && hoursUntil <= 24;
  });

  if (nearTrough) {
    return CoachRecommendation(
      kind: CoachContextKind.troughGentle,
      coachMood: CoachMood.care,
      headline: tr('Pre-dose low-energy window'),
      message: tr(
        'Energy can dip right before your next dose. Light Mode is pre-selected so every gentle set still counts.',
      ),
      contextBadge: tr('Trough window'),
      recommendedRoutine: primaryRoutine,
      suggestLightMode: true,
      daysSinceLastWorkout: daysSinceLast,
      totalSessions: sortedLogs.length,
      sessionsThisMonth: monthLogs.length,
      activeDaysThisMonth: activeDays,
    );
  }

  // 4. Gentle Restart after >= 5 days away (never a broken streak).
  if (daysSinceLast != null && daysSinceLast >= 5) {
    return CoachRecommendation(
      kind: CoachContextKind.easeBackIn,
      coachMood: CoachMood.greet,
      headline: tr('Welcome back — ease back in'),
      message: tr(
        'No streaks lost and zero pressure. Let us warm up with a calm 10-minute session at your own pace.',
      ),
      contextBadge: tr('Gentle restart'),
      recommendedRoutine: buildEaseBackInRoutine(profile.focus),
      suggestLightMode: true,
      daysSinceLastWorkout: daysSinceLast,
      totalSessions: sortedLogs.length,
      sessionsThisMonth: monthLogs.length,
      activeDaysThisMonth: activeDays,
    );
  }

  // 5. Muscle recovery rotation if user trained yesterday.
  var chosen = primaryRoutine;
  if (daysSinceLast == 1 && lastWorkout != null) {
    if (lastWorkout.category == profile.focus &&
        profile.focus != 'recovery') {
      chosen = profile.focus == 'feminizing'
          ? presetFor('bone_heart')
          : presetFor('recovery');
    }
  } else if (customRoutines.isNotEmpty &&
      profile.weekdays.contains(now.weekday) &&
      sortedLogs.isEmpty) {
    chosen = customRoutines.first;
  }

  final isPreferredDay = profile.weekdays.contains(now.weekday);
  if (isPreferredDay) {
    return CoachRecommendation(
      kind: CoachContextKind.scheduledToday,
      coachMood:
          chosen.category == 'recovery' ? CoachMood.stretch : CoachMood.cheer,
      headline: tr('Your comfort window is open'),
      message: tr(
        'Whenever you have a quiet pocket of time today, your {0} plan is ready.',
        [paceLabel(profile.level).toLowerCase()],
      ),
      contextBadge: tr('Preferred day'),
      recommendedRoutine: chosen,
      suggestLightMode: false,
      daysSinceLastWorkout: daysSinceLast,
      totalSessions: sortedLogs.length,
      sessionsThisMonth: monthLogs.length,
      activeDaysThisMonth: activeDays,
    );
  }

  return CoachRecommendation(
    kind: CoachContextKind.readyAnytime,
    coachMood: sortedLogs.isNotEmpty ? CoachMood.ready : CoachMood.greet,
    headline: tr('Ready whenever you are'),
    message: tr(
      'Short, steady sessions support bone strength, heart health, and mood—always at your own pace.',
    ),
    contextBadge: paceLabel(profile.level),
    recommendedRoutine: chosen,
    suggestLightMode: false,
    daysSinceLastWorkout: daysSinceLast,
    totalSessions: sortedLogs.length,
    sessionsThisMonth: monthLogs.length,
    activeDaysThisMonth: activeDays,
  );
}

/// Complete offline-first persisted state for Movement Coach.
class WorkoutState {
  const WorkoutState({
    this.profile = const WorkoutProfile(),
    this.customRoutines = const [],
    this.logs = const [],
  });

  final WorkoutProfile profile;
  final List<WorkoutRoutine> customRoutines;
  final List<WorkoutSessionLog> logs;

  WorkoutState copyWith({
    WorkoutProfile? profile,
    List<WorkoutRoutine>? customRoutines,
    List<WorkoutSessionLog>? logs,
  }) =>
      WorkoutState(
        profile: profile ?? this.profile,
        customRoutines: customRoutines ?? this.customRoutines,
        logs: logs ?? this.logs,
      );

  Map<String, dynamic> toMap() => {
        'profile': profile.toMap(),
        'customRoutines': [for (final r in customRoutines) r.toMap()],
        'logs': [for (final l in logs) l.toMap()],
      };

  factory WorkoutState.fromMap(Map<String, dynamic> m) {
    final pMap = m['profile'] is Map
        ? (m['profile'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final rList = m['customRoutines'] is List
        ? [
            for (final x in m['customRoutines'] as List)
              if (x is Map)
                WorkoutRoutine.from(
                  (x['id'] as String?) ?? 'custom',
                  x.cast<String, dynamic>(),
                ),
          ]
        : const <WorkoutRoutine>[];
    final lList = m['logs'] is List
        ? [
            for (final x in m['logs'] as List)
              if (x is Map)
                WorkoutSessionLog.from(
                  (x['id'] as String?) ?? 'wlog',
                  x.cast<String, dynamic>(),
                ),
          ]
        : const <WorkoutSessionLog>[];
    lList.sort((a, b) => b.at.compareTo(a.at));
    return WorkoutState(
      profile: WorkoutProfile.from('main', pMap),
      customRoutines: rList,
      logs: lList,
    );
  }
}

const String _kWorkoutPrefsKey = 'lunera_workout_v1';

/// Riverpod controller managing WorkoutProfile, custom routines, and session logs
/// with SharedPreferences offline persistence and optional Firestore cloud sync.
class WorkoutController extends Notifier<WorkoutState> {
  String? _activeCloudUid;

  SharedPreferences? _getPrefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  String _storageKey([String? uidOverride]) {
    var uid = uidOverride;
    if (uid == null) {
      try {
        uid = ref.watch(userProvider).valueOrNull?.uid;
      } catch (_) {}
    }
    if (uid != null && uid.isNotEmpty) {
      return '${_kWorkoutPrefsKey}_$uid';
    }
    return _kWorkoutPrefsKey;
  }

  @override
  WorkoutState build() {
    String? uid;
    try {
      uid = ref.watch(userProvider).valueOrNull?.uid;
    } catch (_) {}

    final prefs = _getPrefs();
    var initial = const WorkoutState();
    if (prefs != null) {
      final key = _storageKey(uid);
      if (key != _kWorkoutPrefsKey &&
          !prefs.containsKey(key) &&
          prefs.containsKey(_kWorkoutPrefsKey)) {
        final legacy = prefs.getString(_kWorkoutPrefsKey);
        if (legacy != null) {
          prefs.setString(key, legacy);
          prefs.remove(_kWorkoutPrefsKey);
        }
      }
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            initial = WorkoutState.fromMap(decoded.cast<String, dynamic>());
          }
        } catch (_) {}
      }
    }

    if (uid != null && uid.isNotEmpty && uid != _activeCloudUid) {
      _activeCloudUid = uid;
      Future.microtask(() => _reconcileFromCloud(uid!));
    }
    return initial;
  }

  bool get _hasFirebase {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _reconcileFromCloud(String uid) async {
    if (!_hasFirebase) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users/$uid/workout')
          .doc('main')
          .get();
      if (!doc.exists || doc.data() == null) return;
      final cloud = WorkoutState.fromMap(doc.data()!);
      final merged = _mergeStates(state, cloud);
      state = merged;
      await _persistLocal(merged, uidOverride: uid);
    } catch (_) {
      // Offline-first: silently retain local state.
    }
  }

  static WorkoutState _mergeStates(WorkoutState local, WorkoutState cloud) {
    final routinesById = <String, WorkoutRoutine>{
      for (final r in cloud.customRoutines) r.id: r,
    };
    for (final r in local.customRoutines) {
      final prev = routinesById[r.id];
      if (prev == null || !r.updatedAt.isBefore(prev.updatedAt)) {
        routinesById[r.id] = r;
      }
    }
    final logsById = <String, WorkoutSessionLog>{
      for (final l in cloud.logs) l.id: l,
      for (final l in local.logs) l.id: l,
    };
    final mergedLogs = logsById.values.toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final profile = local.profile.onboarded ? local.profile : cloud.profile;
    return WorkoutState(
      profile: profile,
      customRoutines: routinesById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      logs: mergedLogs,
    );
  }

  Future<void> _persistLocal(WorkoutState next, {String? uidOverride}) async {
    final prefs = _getPrefs() ?? await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(uidOverride), jsonEncode(next.toMap()));
  }

  Future<void> _persist(WorkoutState next) async {
    state = next;
    await _persistLocal(next);
    String? uid;
    try {
      uid = ref.read(userProvider).valueOrNull?.uid;
    } catch (_) {}
    if (uid != null && uid.isNotEmpty && _hasFirebase) {
      try {
        await Repo.trackWrite(
          () => FirebaseFirestore.instance
              .collection('users/$uid/workout')
              .doc('main')
              .set(next.toMap()),
        );
      } catch (_) {}
    }
    try {
      final appPrefs = ref.read(prefsProvider).valueOrNull ?? const Prefs();
      await AppNotifier.instance.syncWorkoutReminders(next.profile, appPrefs);
    } catch (_) {}
  }

  Future<void> updateProfile(WorkoutProfile profile) =>
      _persist(state.copyWith(profile: profile));

  Future<void> markRestToday(DateTime now) =>
      _persist(state.copyWith(
        profile: state.profile.copyWith(skippedDateIso: isoDateOf(now)),
      ));

  Future<void> clearRestToday() =>
      _persist(state.copyWith(
        profile: state.profile.copyWith(clearSkippedDate: true),
      ));

  Future<void> saveCustomRoutine(WorkoutRoutine routine) {
    final list = [
      for (final r in state.customRoutines)
        if (r.id != routine.id) r,
      routine,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _persist(state.copyWith(customRoutines: list));
  }

  Future<void> deleteCustomRoutine(String id) {
    final list = [
      for (final r in state.customRoutines)
        if (r.id != id) r,
    ];
    return _persist(state.copyWith(customRoutines: list));
  }

  Future<String?> completeSession(WorkoutSessionLog log, String effort) async {
    final (nextProfile, notice) = applyEffortFeedback(state.profile, effort);
    final updatedProfile = nextProfile.copyWith(clearSkippedDate: true);
    final logs = [
      log,
      for (final l in state.logs)
        if (l.id != log.id) l,
    ]..sort((a, b) => b.at.compareTo(a.at));
    await _persist(state.copyWith(profile: updatedProfile, logs: logs));
    return notice;
  }

  /// Direct loader used by [Repo.exportJson] without requiring widget context.
  static Future<WorkoutState> loadDirect([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = (uid != null && uid.isNotEmpty)
        ? '${_kWorkoutPrefsKey}_$uid'
        : _kWorkoutPrefsKey;
    final raw = prefs.getString(key) ?? prefs.getString(_kWorkoutPrefsKey);
    if (raw == null || raw.isEmpty) return const WorkoutState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return WorkoutState.fromMap(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return const WorkoutState();
  }

  /// Direct importer used by [Repo.importData] supporting merge & replace modes.
  static Future<void> importDirect({
    List<dynamic>? rawProfiles,
    List<dynamic>? rawRoutines,
    List<dynamic>? rawLogs,
    required bool replace,
    String? uid,
  }) async {
    final existing = replace ? const WorkoutState() : await loadDirect(uid);
    var nextProfile = existing.profile;
    if (rawProfiles != null && rawProfiles.isNotEmpty) {
      final first = rawProfiles.first;
      if (first is Map) {
        nextProfile = WorkoutProfile.from(
          (first['id'] as String?) ?? 'main',
          first.cast<String, dynamic>(),
        );
      }
    }

    final routinesById = <String, WorkoutRoutine>{
      for (final r in existing.customRoutines) r.id: r,
    };
    if (rawRoutines != null) {
      for (final raw in rawRoutines) {
        if (raw is Map) {
          final r = WorkoutRoutine.from(
            (raw['id'] as String?) ?? 'custom',
            raw.cast<String, dynamic>(),
          );
          routinesById[r.id] = r;
        }
      }
    }

    final logsById = <String, WorkoutSessionLog>{
      for (final l in existing.logs) l.id: l,
    };
    if (rawLogs != null) {
      for (final raw in rawLogs) {
        if (raw is Map) {
          final l = WorkoutSessionLog.from(
            (raw['id'] as String?) ?? 'wlog',
            raw.cast<String, dynamic>(),
          );
          logsById[l.id] = l;
        }
      }
    }

    final next = WorkoutState(
      profile: nextProfile,
      customRoutines: routinesById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      logs: logsById.values.toList()..sort((a, b) => b.at.compareTo(a.at)),
    );

    final prefs = await SharedPreferences.getInstance();
    final key = (uid != null && uid.isNotEmpty)
        ? '${_kWorkoutPrefsKey}_$uid'
        : _kWorkoutPrefsKey;
    await prefs.setString(key, jsonEncode(next.toMap()));
  }
}

final workoutProvider =
    NotifierProvider<WorkoutController, WorkoutState>(WorkoutController.new);
