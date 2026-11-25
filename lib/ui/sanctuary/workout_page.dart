import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../models.dart';
import '../../notifications.dart';
import '../../repo.dart';
import '../../theme.dart';
import '../../workout_catalog.dart';
import '../../workout_coach.dart';
import 'coach_avatar.dart';
import 'workout_session_page.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Main hub for Lunera's HRT-aware, guilt-free Personal Movement Coach.
class WorkoutCoachPage extends ConsumerStatefulWidget {
  const WorkoutCoachPage({super.key, this.autoStartToday = false});

  final bool autoStartToday;

  @override
  ConsumerState<WorkoutCoachPage> createState() => _WorkoutCoachPageState();
}

class _WorkoutCoachPageState extends ConsumerState<WorkoutCoachPage> {
  int _programTab = 0; // 0 = HRT Programs, 1 = Custom Routines
  bool? _lightModeOverride;
  bool _showOnboardingOverride = false;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStartToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoStarted) return;
        final ws = ref.read(workoutProvider);
        if (!ws.profile.onboarded) return;
        _autoStarted = true;
        final therapies =
            ref.read(therapiesProvider).valueOrNull ?? const <Therapy>[];
        final doseLogs =
            ref.read(logsProvider).valueOrNull ?? const <DoseLog>[];
        final prefs = ref.read(prefsProvider).valueOrNull ?? const Prefs();
        final rec = evaluateCoachContext(
          now: DateTime.now(),
          profile: ws.profile,
          workoutLogs: ws.logs,
          therapies: therapies,
          doseLogs: doseLogs,
          prefs: prefs,
          customRoutines: ws.customRoutines,
        );
        _startRoutine(
          rec.recommendedRoutine,
          lightMode: _lightModeOverride ?? rec.suggestLightMode,
        );
      });
    }
  }

  Future<void> _startRoutine(
    WorkoutRoutine routine, {
    required bool lightMode,
  }) async {
    HapticFeedback.lightImpact();
    final effective = lightMode ? applyLightMode(routine) : routine;
    final notice = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => WorkoutSessionPage(
          routine: effective,
          isLightMode: lightMode,
        ),
      ),
    );
    if (!mounted) return;
    if (notice != null && notice.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notice)),
      );
    }
  }

  Future<void> _toggleRestToday(bool isCurrentlyResting) async {
    HapticFeedback.selectionClick();
    final ctrl = ref.read(workoutProvider.notifier);
    if (isCurrentlyResting) {
      await ctrl.clearRestToday();
      return;
    }
    await ctrl.markRestToday(DateTime.now());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Rest day honored. Take care of yourself today.')),
        action: SnackBarAction(
          label: tr('Undo'),
          onPressed: () {
            ctrl.clearRestToday();
          },
        ),
      ),
    );
  }

  void _openRoutinePreview(WorkoutRoutine routine, {required bool lightMode}) {
    final effective = lightMode ? applyLightMode(routine) : routine;
    showSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  effective.title,
                  style: display(24, color: Colors.white, weight: FontWeight.w600),
                ),
              ),
              Text(
                '~${effective.estimatedMinutes} min',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: C.lavender,
                ),
              ),
            ],
          ),
          gap(4),
          Text(
            categorySubtitle(effective.category),
            style: TextStyle(
              fontSize: 12.5,
              color: Pastel.mist.withValues(alpha: 0.8),
            ),
          ),
          gap(14),
          for (var i = 0; i < effective.items.length; i++) ...[
            _ExercisePreviewRow(item: effective.items[i], index: i + 1),
            if (i < effective.items.length - 1) gap(10),
          ],
          gap(18),
          SizedBox(
            width: double.infinity,
            child: pillButton(
              tr('Start session'),
              () {
                Navigator.pop(context);
                _startRoutine(routine, lightMode: lightMode);
              },
              icon: LucideIcons.play,
            ),
          ),
        ],
      ),
    );
  }

  void _openCustomRoutineBuilder([WorkoutRoutine? existing]) {
    showSheet(
      context,
      _CustomRoutineBuilderSheet(
        existing: existing,
        onSave: (routine) async {
          await ref.read(workoutProvider.notifier).saveCustomRoutine(routine);
        },
      ),
    );
  }

  Future<void> _deleteCustomRoutine(WorkoutRoutine routine) async {
    final ok = await confirm(
      context,
      tr('Delete "{0}"?', [routine.title]),
    );
    if (!ok || !mounted) return;
    await ref.read(workoutProvider.notifier).deleteCustomRoutine(routine.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);
    final therapies =
        ref.watch(therapiesProvider).valueOrNull ?? const <Therapy>[];
    final doseLogs = ref.watch(logsProvider).valueOrNull ?? const <DoseLog>[];
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();

    final showOnboarding = !state.profile.onboarded || _showOnboardingOverride;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: showOnboarding
                ? _OnboardingFlow(
                    initialProfile: state.profile,
                    initialShowHomeCard: prefs.showWorkoutHomeCard,
                    onCancel: state.profile.onboarded
                        ? () => setState(() => _showOnboardingOverride = false)
                        : null,
                    onFinish: (updatedProfile, showOnHome) async {
                      await ref
                          .read(workoutProvider.notifier)
                          .updateProfile(updatedProfile);
                      final repo = ref.read(repoProvider);
                      if (repo != null &&
                          showOnHome != prefs.showWorkoutHomeCard) {
                        await repo.setPrefs(
                            prefs.copy(showWorkoutHomeCard: showOnHome));
                      }
                      if (mounted) {
                        setState(() => _showOnboardingOverride = false);
                      }
                    },
                  )
                : _buildDashboard(
                    context,
                    state: state,
                    therapies: therapies,
                    doseLogs: doseLogs,
                    prefs: prefs,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context, {
    required WorkoutState state,
    required List<Therapy> therapies,
    required List<DoseLog> doseLogs,
    required Prefs prefs,
  }) {
    final rec = evaluateCoachContext(
      now: DateTime.now(),
      profile: state.profile,
      workoutLogs: state.logs,
      therapies: therapies,
      doseLogs: doseLogs,
      prefs: prefs,
      customRoutines: state.customRoutines,
    );
    final useLight = _lightModeOverride ?? rec.suggestLightMode;
    final effectiveRec =
        useLight ? applyLightMode(rec.recommendedRoutine) : rec.recommendedRoutine;
    final presets = buildPresetRoutines(
      state.profile.level,
      equipment: state.profile.equipment,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        // Header
        Row(
          children: [
            IconButton(
              tooltip: tr('Back'),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.arrowLeft),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                tr('Movement Coach'),
                style: display(30, color: Colors.white, weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: tr('Coach preferences & baseline'),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _showOnboardingOverride = true);
              },
              icon: const Icon(LucideIcons.slidersHorizontal),
            ),
          ],
        ),
        gap(10),

        // Signature Hero Card (Personal Coach Plan for Today)
        AppCard(
          highlight: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachAvatar(
                    mood: rec.coachMood,
                    size: 76,
                    glowColor: rec.kind == CoachContextKind.injectionCare
                        ? C.coral
                        : C.aurora,
                    enablePulse: true,
                    semanticLabel: tr('Lunera Movement Coach'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rec.contextBadge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (rec.kind == CoachContextKind.injectionCare
                                      ? C.coral
                                      : Pastel.mint)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: (rec.kind ==
                                            CoachContextKind.injectionCare
                                        ? C.coral
                                        : Pastel.mint)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              rec.contextBadge!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: rec.kind ==
                                        CoachContextKind.injectionCare
                                    ? C.coral
                                    : Pastel.mint,
                              ),
                            ),
                          ),
                        gap(6),
                        Text(
                          rec.headline,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        gap(4),
                        Text(
                          rec.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Pastel.mist.withValues(alpha: 0.86),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              gap(14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.midnight.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.lavender.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    iconBadge(LucideIcons.sparkles, C.lavender,
                        size: 40, iconSize: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectiveRec.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            tr('{0} exercises · ~{1} min', [
                              effectiveRec.items.length,
                              effectiveRec.estimatedMinutes,
                            ]),
                            style: TextStyle(
                              fontSize: 12,
                              color: Pastel.mist.withValues(alpha: 0.78),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: tr('Preview routine'),
                      onPressed: () => _openRoutinePreview(
                        rec.recommendedRoutine,
                        lightMode: useLight,
                      ),
                      icon: const Icon(LucideIcons.eye, size: 19),
                    ),
                  ],
                ),
              ),
              gap(14),
              SizedBox(
                width: double.infinity,
                child: pillButton(
                  tr('Start {0}-min session', [effectiveRec.estimatedMinutes]),
                  () => _startRoutine(
                    rec.recommendedRoutine,
                    lightMode: useLight,
                  ),
                  icon: LucideIcons.play,
                ),
              ),
              gap(10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(
                      tr('Light mode'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: useLight,
                    onSelected: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _lightModeOverride = v);
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _toggleRestToday(
                        rec.kind == CoachContextKind.restedToday),
                    icon: Icon(
                      rec.kind == CoachContextKind.restedToday
                          ? LucideIcons.rotateCcw
                          : LucideIcons.moon,
                      size: 16,
                    ),
                    label: Text(
                      rec.kind == CoachContextKind.restedToday
                          ? tr('Resume today')
                          : tr('Rest today'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        gap(14),

        // Guilt-Free Progress Strip (No streaks!)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: _StatColumn(
                  value: '${rec.totalSessions}',
                  label: tr('Total sessions'),
                  color: C.lavender,
                ),
              ),
              Container(
                  width: 1,
                  height: 34,
                  color: C.lavender.withValues(alpha: 0.16)),
              Expanded(
                child: _StatColumn(
                  value: '${rec.activeDaysThisMonth}',
                  label: tr('Active days (mo)'),
                  color: Pastel.mint,
                ),
              ),
              Container(
                  width: 1,
                  height: 34,
                  color: C.lavender.withValues(alpha: 0.16)),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _showOnboardingOverride = true),
                  child: _StatColumn(
                    value: paceLabel(state.profile.level),
                    label: tr('Current pace'),
                    color: C.coral,
                  ),
                ),
              ),
            ],
          ),
        ),
        gap(18),

        // Programs & Custom Routines
        PillTabs<int>(
          items: [
            (0, tr('HRT Programs')),
            (1, tr('Custom Routines')),
          ],
          value: _programTab,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _programTab = v);
          },
        ),
        gap(14),

        if (_programTab == 0) ...[
          for (final routine in presets) ...[
            _RoutineCard(
              routine: routine,
              isAvoidedZone: (rec.avoidedZone == 'lower' &&
                      routine.category == 'feminizing') ||
                  (rec.avoidedZone == 'upper' &&
                      routine.category == 'masculinizing'),
              onPreview: () =>
                  _openRoutinePreview(routine, lightMode: useLight),
              onStart: () => _startRoutine(routine, lightMode: useLight),
            ),
            gap(10),
          ],
        ] else ...[
          if (state.customRoutines.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const CoachAvatar(
                    mood: CoachMood.think,
                    size: 76,
                  ),
                  gap(10),
                  Text(
                    tr('No custom routines yet'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  gap(4),
                  Text(
                    tr('Mix exercises from the catalog or add your own movements at your preferred sets and reps.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Pastel.mist.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  gap(14),
                  pillButton(
                    tr('Create custom routine'),
                    () => _openCustomRoutineBuilder(),
                    icon: LucideIcons.plus,
                  ),
                ],
              ),
            )
          else ...[
            for (final routine in state.customRoutines) ...[
              _RoutineCard(
                routine: routine,
                onPreview: () =>
                    _openRoutinePreview(routine, lightMode: useLight),
                onStart: () => _startRoutine(routine, lightMode: useLight),
                onEdit: () => _openCustomRoutineBuilder(routine),
                onDelete: () => _deleteCustomRoutine(routine),
              ),
              gap(10),
            ],
            gap(4),
            OutlinedButton.icon(
              onPressed: () => _openCustomRoutineBuilder(),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(tr('Create custom routine')),
            ),
          ],
        ],

        if (state.logs.isNotEmpty) ...[
          SectionHeader(title: tr('Recent sessions')),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (var i = 0; i < state.logs.take(5).length; i++) ...[
                  _SessionHistoryRow(log: state.logs[i]),
                  if (i < state.logs.take(5).length - 1)
                    const Divider(height: 16),
                ],
              ],
            ),
          ),
        ],

        gap(18),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 17, color: C.lavender),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('Based on WHO Physical Activity Guidelines, NHS Strength & Flexibility Guides, and ACE Exercise Library principles. General fitness guidance only—not medical advice.'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Pastel.mist.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: Pastel.mist.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onPreview,
    required this.onStart,
    this.isAvoidedZone = false,
    this.onEdit,
    this.onDelete,
  });

  final WorkoutRoutine routine;
  final bool isAvoidedZone;
  final VoidCallback onPreview;
  final VoidCallback onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = switch (routine.category) {
      'feminizing' => C.rose,
      'masculinizing' => C.violet,
      'bone_heart' => Pastel.mint,
      'recovery' => C.lavender,
      _ => C.coral,
    };
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onPreview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconBadge(
                routine.category == 'recovery'
                    ? LucideIcons.wind
                    : LucideIcons.dumbbell,
                accent,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('{0} exercises · ~{1} min', [
                        routine.items.length,
                        routine.estimatedMinutes,
                      ]),
                      style: TextStyle(
                        fontSize: 12,
                        color: Pastel.mist.withValues(alpha: 0.78),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: tr('Edit'),
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 17),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: tr('Delete'),
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 17),
                ),
              FilledButton.tonal(
                onPressed: onStart,
                child: Text(tr('Start')),
              ),
            ],
          ),
          if (isAvoidedZone) ...[
            gap(8),
            Text(
              tr('Near recent injection zone—consider skipping or switching to recovery today.'),
              style: const TextStyle(
                fontSize: 11.5,
                color: C.coral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExercisePreviewRow extends StatelessWidget {
  const _ExercisePreviewRow({required this.item, required this.index});
  final WorkoutExerciseItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final spec = exerciseById(item.exerciseId);
    final name = item.customName?.trim().isNotEmpty == true
        ? item.customName!.trim()
        : (spec?.name ?? item.exerciseId);
    final target = item.isTimed
        ? '${item.sets} × ${item.seconds}s'
        : '${item.sets} × ${item.reps ?? 10}';
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.aurora.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: C.lavender,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          target,
          style: TextStyle(
            fontSize: 12.5,
            color: Pastel.mist.withValues(alpha: 0.84),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SessionHistoryRow extends StatelessWidget {
  const _SessionHistoryRow({required this.log});
  final WorkoutSessionLog log;

  @override
  Widget build(BuildContext context) {
    final effortLabel = switch (log.effort) {
      'easy' => tr('Too easy'),
      'tough' => tr('A bit tough'),
      _ => tr('Just right'),
    };
    final dateStr = DateFormat('d MMM, HH:mm', L10n.code).format(log.at);
    final mins = (log.durationSec / 60).ceil().clamp(1, 180);
    return Row(
      children: [
        const Icon(LucideIcons.circleCheck, size: 18, color: Pastel.mint),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.routineTitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '$dateStr · ~$mins min · $effortLabel',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Pastel.mist.withValues(alpha: 0.74),
                ),
              ),
            ],
          ),
        ),
        if (log.wasLightMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Pastel.mint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tr('Light'),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Pastel.mint,
              ),
            ),
          ),
      ],
    );
  }
}

/// 3-step onboarding + optional baseline calibration flow for Movement Coach.
class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow({
    required this.initialProfile,
    required this.initialShowHomeCard,
    required this.onFinish,
    this.onCancel,
  });

  final WorkoutProfile initialProfile;
  final bool initialShowHomeCard;
  final Future<void> Function(WorkoutProfile profile, bool showOnHome) onFinish;
  final VoidCallback? onCancel;

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  int _step = 0;
  late String _focus;
  late Set<String> _equipment;
  late Set<int> _weekdays;
  late String _reminderTime;
  late bool _notifyWorkout;
  late bool _showHomeCard;

  int _squatComfort = 0;
  int _pushupComfort = 0;
  int _plankComfort = 0;
  String? _manualLevelOverride;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.initialProfile.focus;
    _equipment = {...widget.initialProfile.equipment};
    _weekdays = {...widget.initialProfile.weekdays};
    _reminderTime = widget.initialProfile.reminderTime;
    _notifyWorkout = widget.initialProfile.notifyWorkout;
    _showHomeCard = widget.initialShowHomeCard;
    if (widget.initialProfile.onboarded) {
      _manualLevelOverride = widget.initialProfile.level;
    }
  }

  String get _calibratedLevel =>
      _manualLevelOverride ??
      calibrateBaselineLevel(
        squatComfort: _squatComfort,
        pushupComfort: _pushupComfort,
        plankComfort: _plankComfort,
      );

  Future<void> _pickTime() async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(
      hour: parts.length == 2 ? (int.tryParse(parts[0]) ?? 18) : 18,
      minute: parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      _reminderTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit({bool skipToGentle = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final level = skipToGentle ? 'gentle' : _calibratedLevel;
    final profile = widget.initialProfile.copyWith(
      onboarded: true,
      focus: _focus,
      level: level,
      equipment:
          _equipment.isEmpty ? const ['bodyweight'] : _equipment.toList(),
      weekdays: (_weekdays.toList()..sort()),
      reminderTime: _reminderTime,
      notifyWorkout: _notifyWorkout,
      baselineAt: DateTime.now(),
    );
    await widget.onFinish(profile, _showHomeCard);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: tr('Back'),
                onPressed: () {
                  if (_step > 0) {
                    setState(() => _step--);
                  } else if (widget.onCancel != null) {
                    widget.onCancel!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              Expanded(
                child: Text(
                  tr('Personal Coach Setup'),
                  style:
                      display(26, color: Colors.white, weight: FontWeight.w600),
                ),
              ),
              Text(
                '${_step + 1}/3',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: C.lavender,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const CoachAvatar(
                      mood: CoachMood.explain,
                      size: 64,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        switch (_step) {
                          0 => tr(
                              'Tell me your main focus and what equipment you have—no gym needed.'),
                          1 => tr(
                              'Let us gauge your comfortable starting pace so sets and reps fit you right.'),
                          _ => tr(
                              'Pick days and times that feel relaxed. You can skip or rest anytime with zero penalties.'),
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: Pastel.mist.withValues(alpha: 0.88),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              gap(16),
              if (_step == 0) ...[
                Text(
                  tr('Choose your HRT movement focus'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                gap(10),
                for (final cat in const [
                  'feminizing',
                  'masculinizing',
                  'bone_heart',
                  'recovery',
                ]) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _focus = cat);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _focus == cat
                            ? C.aurora.withValues(alpha: 0.22)
                            : C.deepCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _focus == cat
                              ? C.violet
                              : C.lavender.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _focus == cat
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            size: 19,
                            color: _focus == cat ? C.lavender : C.iconDefault,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryLabel(cat),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  categorySubtitle(cat),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Pastel.mist.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  gap(8),
                ],
                gap(10),
                Text(
                  tr('Available equipment'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final eq in [
                      ('bodyweight', tr('Bodyweight only')),
                      ('dumbbells', tr('Light dumbbells')),
                      ('bands', tr('Resistance bands')),
                    ])
                      FilterChip(
                        label: Text(eq.$2),
                        selected: _equipment.contains(eq.$1),
                        onSelected: (v) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (v) {
                              _equipment.add(eq.$1);
                            } else if (_equipment.length > 1) {
                              _equipment.remove(eq.$1);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ] else if (_step == 1) ...[
                _BaselineQuestionCard(
                  title: tr('1. Comfortable squats'),
                  value: _squatComfort,
                  options: [
                    tr('Chair / up to 8'),
                    tr('10–15 steady'),
                    tr('16+ comfortably'),
                  ],
                  onChanged: (v) => setState(() {
                    _manualLevelOverride = null;
                    _squatComfort = v;
                  }),
                ),
                gap(10),
                _BaselineQuestionCard(
                  title: tr('2. Comfortable push-up variation'),
                  value: _pushupComfort,
                  options: [
                    tr('Wall push-up'),
                    tr('Counter / knees'),
                    tr('Floor push-up'),
                  ],
                  onChanged: (v) => setState(() {
                    _manualLevelOverride = null;
                    _pushupComfort = v;
                  }),
                ),
                gap(10),
                _BaselineQuestionCard(
                  title: tr('3. Comfortable plank hold'),
                  value: _plankComfort,
                  options: [
                    tr('Under 20s / knees'),
                    tr('20–40 seconds'),
                    tr('45+ seconds'),
                  ],
                  onChanged: (v) => setState(() {
                    _manualLevelOverride = null;
                    _plankComfort = v;
                  }),
                ),
                gap(14),
                AppCard(
                  highlight: true,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      iconBadge(LucideIcons.gauge, Pastel.mint,
                          size: 42, iconSize: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Suggested starting pace: {0}', [
                                paceLabel(_calibratedLevel),
                              ]),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              tr('Sets and reps will match this comfort tier.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Pastel.mist.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  tr('Preferred days'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text(tr(_weekdayLabels[d - 1])),
                        selected: _weekdays.contains(d),
                        onSelected: (v) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (v) {
                              _weekdays.add(d);
                            } else {
                              _weekdays.remove(d);
                            }
                          });
                        },
                      ),
                  ],
                ),
                gap(14),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: iconBadge(LucideIcons.clock, C.lavender),
                        title: Text(tr('Preferred time window')),
                        trailing: Text(
                          _reminderTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        onTap: _pickTime,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: iconBadge(LucideIcons.bell, Pastel.mint),
                        title: Text(tr('Gentle movement reminders')),
                        subtitle: Text(
                          AppNotifier.instance.supported
                              ? tr(
                                  'Optional & separate from dose alarms. Zero nagging.')
                              : tr('Only available on Android and iOS apps.'),
                        ),
                        value: _notifyWorkout,
                        onChanged: !AppNotifier.instance.supported
                            ? null
                            : (v) async {
                                HapticFeedback.selectionClick();
                                if (v &&
                                    !await AppNotifier.instance
                                        .requestPermission()) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr('Notification permission was declined. You can still use Movement Coach anytime.'),
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                setState(() => _notifyWorkout = v);
                              },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: iconBadge(LucideIcons.home, C.coral),
                        title: Text(tr('Show shortcut card on Home')),
                        subtitle: Text(
                          tr('Adds a calm Movement Coach card to your Home tab.'),
                        ),
                        value: _showHomeCard,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _showHomeCard = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Pinned thumb-zone bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(
            color: C.voidBg.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: C.lavender.withValues(alpha: 0.14)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: switch (_step) {
                  0 => pillButton(
                      tr('Next: Baseline check'),
                      () {
                        HapticFeedback.selectionClick();
                        setState(() => _step = 1);
                      },
                      icon: LucideIcons.arrowRight,
                    ),
                  1 => pillButton(
                      tr('Next: Comfort schedule'),
                      () {
                        HapticFeedback.selectionClick();
                        setState(() => _step = 2);
                      },
                      icon: LucideIcons.arrowRight,
                    ),
                  _ => pillButton(
                      tr('Save & open Movement Coach'),
                      () {
                        if (!_busy) _submit();
                      },
                      icon: LucideIcons.check,
                    ),
                },
              ),
              if (_step == 1) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _busy ? null : () => _submit(skipToGentle: true),
                  child: Text(tr('Skip test — start Gentle')),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BaselineQuestionCard extends StatelessWidget {
  const _BaselineQuestionCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final int value;
  final List<String> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < options.length; i++)
                ChoiceChip(
                  label: Text(options[i], style: const TextStyle(fontSize: 12)),
                  selected: value == i,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for creating or editing a custom workout routine.
class _CustomRoutineBuilderSheet extends StatefulWidget {
  const _CustomRoutineBuilderSheet({
    required this.onSave,
    this.existing,
  });

  final WorkoutRoutine? existing;
  final Future<void> Function(WorkoutRoutine routine) onSave;

  @override
  State<_CustomRoutineBuilderSheet> createState() =>
      _CustomRoutineBuilderSheetState();
}

class _CustomRoutineBuilderSheetState
    extends State<_CustomRoutineBuilderSheet> {
  late final TextEditingController _titleCtrl;
  late List<WorkoutExerciseItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _items = [
      if (widget.existing != null)
        ...widget.existing!.items
      else
        const WorkoutExerciseItem(
          exerciseId: 'glute_bridge',
          sets: 2,
          reps: 10,
        ),
    ];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _items.isEmpty) return;
    final title = _titleCtrl.text.trim().isEmpty
        ? tr('My Custom Routine')
        : _titleCtrl.text.trim();
    setState(() => _saving = true);
    final est = (_items.length * 3).clamp(5, 90);
    final routine = WorkoutRoutine(
      id: widget.existing?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: 'custom',
      isCustom: true,
      estimatedMinutes: est,
      items: _items,
      updatedAt: DateTime.now(),
    );
    await widget.onSave(routine);
    if (mounted) Navigator.pop(context);
  }

  void _addCatalogExercise(ExerciseSpec spec) {
    HapticFeedback.selectionClick();
    setState(() {
      _items.add(
        WorkoutExerciseItem(
          exerciseId: spec.id,
          sets: spec.baseSets.$1,
          reps: spec.isTimed ? null : spec.baseRepsOrSec.$1,
          seconds: spec.isTimed ? spec.baseRepsOrSec.$1 : null,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky header CTA so keyboard never obscures Save
        Row(
          children: [
            Expanded(
              child: Text(
                widget.existing == null
                    ? tr('Create custom routine')
                    : tr('Edit routine'),
                style: display(24, color: Colors.white, weight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: _saving || _items.isEmpty ? null : _save,
              child: Text(tr('Save')),
            ),
          ],
        ),
        gap(12),
        TextField(
          controller: _titleCtrl,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: tr('Routine name'),
            hintText: tr('e.g. Evening Posture & Core'),
          ),
        ),
        gap(16),
        Text(
          tr('Exercises ({0})', [_items.length]),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        gap(8),
        for (var i = 0; i < _items.length; i++) ...[
          _BuilderItemTile(
            item: _items[i],
            onChanged: (updated) => setState(() => _items[i] = updated),
            onRemove: _items.length <= 1
                ? null
                : () => setState(() => _items.removeAt(i)),
          ),
          gap(8),
        ],
        gap(10),
        Text(
          tr('Add movement from official catalog'),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: C.lavender,
          ),
        ),
        gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final spec in workoutExercises)
              ActionChip(
                avatar: const Icon(LucideIcons.plus, size: 14),
                label: Text(spec.name, style: const TextStyle(fontSize: 12)),
                onPressed: () => _addCatalogExercise(spec),
              ),
          ],
        ),
      ],
    );
  }
}

class _BuilderItemTile extends StatelessWidget {
  const _BuilderItemTile({
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final WorkoutExerciseItem item;
  final ValueChanged<WorkoutExerciseItem> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final spec = exerciseById(item.exerciseId);
    final name = item.customName?.trim().isNotEmpty == true
        ? item.customName!.trim()
        : (spec?.name ?? item.exerciseId);
    final target = item.isTimed ? (item.seconds ?? 30) : (item.reps ?? 10);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.midnight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.lavender.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: tr('Remove'),
                  onPressed: onRemove,
                  icon: const Icon(LucideIcons.trash2, size: 17),
                ),
            ],
          ),
          Row(
            children: [
              _StepperGroup(
                label: tr('Sets'),
                valueText: '${item.sets}',
                onMinus: item.sets > 1
                    ? () => onChanged(item.copyWith(sets: item.sets - 1))
                    : null,
                onPlus: item.sets < 8
                    ? () => onChanged(item.copyWith(sets: item.sets + 1))
                    : null,
              ),
              const SizedBox(width: 14),
              _StepperGroup(
                label: item.isTimed ? tr('Sec') : tr('Reps'),
                valueText: '$target',
                onMinus: target > (item.isTimed ? 10 : 3)
                    ? () => onChanged(
                          item.isTimed
                              ? item.copyWith(seconds: target - 5)
                              : item.copyWith(reps: target - 2),
                        )
                    : null,
                onPlus: () => onChanged(
                  item.isTimed
                      ? item.copyWith(seconds: target + 5)
                      : item.copyWith(reps: target + 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperGroup extends StatelessWidget {
  const _StepperGroup({
    required this.label,
    required this.valueText,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String valueText;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Pastel.mist.withValues(alpha: 0.78),
          ),
        ),
        IconButton(
          tooltip: tr('Decrease'),
          onPressed: onMinus,
          icon: const Icon(LucideIcons.minus, size: 16),
        ),
        Text(
          valueText,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          tooltip: tr('Increase'),
          onPressed: onPlus,
          icon: const Icon(LucideIcons.plus, size: 16),
        ),
      ],
    );
  }
}
