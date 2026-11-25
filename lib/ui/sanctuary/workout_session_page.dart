import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../workout_catalog.dart';
import '../../workout_coach.dart';
import 'coach_avatar.dart';
import 'workout_pose_painter.dart';

/// Distraction-free active workout mode with 2-pose diagram, step-by-step form
/// cues, flexible rest/hold timers, and a guilt-free post-session effort check.
class WorkoutSessionPage extends ConsumerStatefulWidget {
  const WorkoutSessionPage({
    super.key,
    required this.routine,
    this.isLightMode = false,
  });

  final WorkoutRoutine routine;
  final bool isLightMode;

  @override
  ConsumerState<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends ConsumerState<WorkoutSessionPage> {
  late final DateTime _startedAt;
  late final List<List<bool>> _completedSets;
  late final List<bool> _easierVariant;

  int _index = 0;
  bool _guideExpanded = true;
  bool _showEffortCheck = false;
  bool _saving = false;

  Timer? _restTimer;
  int? _restSecondsLeft;

  Timer? _holdTimer;
  int? _holdSecondsLeft;
  bool _holdRunning = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _completedSets = [
      for (final item in widget.routine.items)
        List<bool>.filled(item.sets, false),
    ];
    _easierVariant = [
      for (final item in widget.routine.items) item.useEasierVariant,
    ];
    _resetHoldTimerForCurrent();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  WorkoutExerciseItem get _currentItem => widget.routine.items[_index];

  ExerciseSpec? get _currentSpec => exerciseById(_currentItem.exerciseId);

  int get _totalCompletedSets => _completedSets.fold<int>(
        0,
        (sum, list) => sum + list.where((done) => done).length,
      );

  int get _totalPlannedSets =>
      _completedSets.fold<int>(0, (sum, list) => sum + list.length);

  void _resetHoldTimerForCurrent() {
    _holdTimer?.cancel();
    _holdRunning = false;
    _holdSecondsLeft =
        widget.routine.items.isNotEmpty ? _currentItem.seconds : null;
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restSecondsLeft = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final next = (_restSecondsLeft ?? 1) - 1;
      if (next <= 0) {
        t.cancel();
        HapticFeedback.lightImpact();
        setState(() => _restSecondsLeft = null);
      } else {
        setState(() => _restSecondsLeft = next);
      }
    });
  }

  void _skipRest() {
    HapticFeedback.selectionClick();
    _restTimer?.cancel();
    setState(() => _restSecondsLeft = null);
  }

  void _addRestTime() {
    HapticFeedback.selectionClick();
    setState(() {
      _restSecondsLeft = (_restSecondsLeft ?? 0) + 15;
    });
  }

  void _toggleHoldTimer() {
    HapticFeedback.selectionClick();
    if (_holdRunning) {
      _holdTimer?.cancel();
      setState(() => _holdRunning = false);
      return;
    }
    final initial = _holdSecondsLeft ?? _currentItem.seconds ?? 30;
    setState(() {
      _holdSecondsLeft = initial <= 0 ? (_currentItem.seconds ?? 30) : initial;
      _holdRunning = true;
    });
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final next = (_holdSecondsLeft ?? 1) - 1;
      if (next <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          _holdSecondsLeft = 0;
          _holdRunning = false;
        });
        _completeNextIncompleteSet();
      } else {
        setState(() => _holdSecondsLeft = next);
      }
    });
  }

  void _toggleSet(int setIdx) {
    HapticFeedback.lightImpact();
    final wasDone = _completedSets[_index][setIdx];
    setState(() {
      _completedSets[_index][setIdx] = !wasDone;
    });
    if (!wasDone) {
      final allDoneForExercise = _completedSets[_index].every((d) => d);
      if (!allDoneForExercise) {
        _startRestTimer(_currentItem.restSeconds);
      } else {
        _restTimer?.cancel();
        setState(() => _restSecondsLeft = null);
      }
    }
  }

  void _completeNextIncompleteSet() {
    final sets = _completedSets[_index];
    final nextIdx = sets.indexWhere((done) => !done);
    if (nextIdx >= 0) {
      _toggleSet(nextIdx);
      return;
    }
    _goNextOrFinish();
  }

  void _goToExercise(int nextIndex) {
    HapticFeedback.selectionClick();
    _restTimer?.cancel();
    setState(() {
      _restSecondsLeft = null;
      _index = nextIndex.clamp(0, widget.routine.items.length - 1);
      _resetHoldTimerForCurrent();
    });
  }

  void _goNextOrFinish() {
    if (_index < widget.routine.items.length - 1) {
      _goToExercise(_index + 1);
    } else {
      _restTimer?.cancel();
      _holdTimer?.cancel();
      HapticFeedback.mediumImpact();
      setState(() {
        _restSecondsLeft = null;
        _holdRunning = false;
        _showEffortCheck = true;
      });
    }
  }

  Future<bool> _confirmLeaveIfActive() async {
    if (_showEffortCheck || _totalCompletedSets == 0) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Leave session?')),
        content: Text(
          tr('You have completed {0} {0?set|sets}. Leaving now discards this unfinished session.',
              [_totalCompletedSets]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(tr('Keep going')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(tr('Leave')),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _submitEffort(String effort) async {
    if (_saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final elapsedSec = DateTime.now().difference(_startedAt).inSeconds;
    final log = WorkoutSessionLog(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      at: DateTime.now(),
      routineId: widget.routine.id,
      routineTitle: widget.routine.title,
      category: widget.routine.category,
      durationSec: elapsedSec < 10 ? 60 : elapsedSec,
      completedSets: _totalCompletedSets > 0 ? _totalCompletedSets : 1,
      totalSets: _totalPlannedSets > 0 ? _totalPlannedSets : 1,
      effort: effort,
      wasLightMode: widget.isLightMode,
    );
    final notice = await ref
        .read(workoutProvider.notifier)
        .completeSession(log, effort);
    if (!mounted) return;
    Navigator.pop(context, notice ?? tr('Session saved. Nice work today!'));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routine.items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('This routine has no exercises yet.')),
                gap(12),
                pillButton(tr('Back'), () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: _showEffortCheck || _totalCompletedSets == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmLeaveIfActive();
        if (ok && mounted) nav.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _showEffortCheck
                  ? _buildEffortCheckView(context)
                  : _buildActiveWorkoutView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveWorkoutView(BuildContext context) {
    final item = _currentItem;
    final spec = _currentSpec;
    final title = item.customName?.trim().isNotEmpty == true
        ? item.customName!.trim()
        : (spec?.name ?? item.exerciseId);
    final sets = _completedSets[_index];
    final allExerciseDone = sets.every((d) => d);
    final isLast = _index == widget.routine.items.length - 1;
    final targetLabel = item.isTimed
        ? tr('{0} sec hold / pace', [item.seconds ?? 30])
        : tr('{0} reps', [item.reps ?? 10]);

    return Column(
      children: [
        // Top header bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: tr('Close session'),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final ok = await _confirmLeaveIfActive();
                  if (ok && mounted) nav.pop();
                },
                icon: const Icon(LucideIcons.x),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Exercise {0} of {1}',
                          [_index + 1, widget.routine.items.length]),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: C.lavender,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / widget.routine.items.length,
                        minHeight: 5,
                        backgroundColor: C.nebula,
                        valueColor: const AlwaysStoppedAnimation(C.aurora),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isLightMode) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Pastel.mint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Pastel.mint.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    tr('Light Mode'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Pastel.mint,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              // 2-pose diagram
              if (spec != null)
                WorkoutPoseStage(
                  poseKind: spec.poseKind,
                  height: 172,
                  accent: C.lavender,
                )
              else
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.midnight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: C.lavender.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.dumbbell,
                    size: 36,
                    color: C.lavender,
                  ),
                ),
              gap(14),

              // Title & easier variant switch
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: display(26,
                              color: Colors.white, weight: FontWeight.w600),
                        ),
                        gap(4),
                        Text(
                          '${sets.length} ${tr('sets')} · $targetLabel',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: C.lavender,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (spec != null)
                    FilterChip(
                      label: Text(
                        tr('Make it easier'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _easierVariant[_index],
                      onSelected: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _easierVariant[_index] = v);
                      },
                    ),
                ],
              ),

              if (_easierVariant[_index] && spec != null) ...[
                gap(10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Pastel.mint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Pastel.mint.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.sparkles,
                          size: 16, color: Pastel.mint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tr('Easier variation')}: ${spec.easierVariant}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Pastel.mist.withValues(alpha: 0.92),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Inline Rest Timer Banner (when active)
              if (_restSecondsLeft != null) ...[
                gap(12),
                AppCard(
                  highlight: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const CoachAvatar(
                        mood: CoachMood.hydrate,
                        size: 72,
                        glowColor: Pastel.mint,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Catch your breath · {0}s', [_restSecondsLeft!]),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              tr('Sip water whenever you need.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Pastel.mist.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _addRestTime,
                        child: const Text('+15s'),
                      ),
                      TextButton(
                        onPressed: _skipRest,
                        child: Text(tr('Skip')),
                      ),
                    ],
                  ),
                ),
              ],

              // Timed exercise countdown (for Plank, Step March, Stretches)
              if (item.isTimed) ...[
                gap(12),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.timer,
                          size: 20, color: C.lavender),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_holdSecondsLeft ?? item.seconds ?? 30}s',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _toggleHoldTimer,
                        icon: Icon(
                          _holdRunning ? LucideIcons.pause : LucideIcons.play,
                          size: 16,
                        ),
                        label: Text(
                          _holdRunning ? tr('Pause') : tr('Start timer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              gap(14),

              // Set checklist (no nested cards inside AppCard)
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Sets checklist'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.lavender,
                      ),
                    ),
                    gap(8),
                    for (var s = 0; s < sets.length; s++) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _toggleSet(s),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: sets[s]
                                ? Pastel.mint.withValues(alpha: 0.14)
                                : C.midnight.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sets[s]
                                  ? Pastel.mint.withValues(alpha: 0.45)
                                  : C.lavender.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                sets[s]
                                    ? LucideIcons.circleCheck
                                    : LucideIcons.circle,
                                size: 20,
                                color:
                                    sets[s] ? Pastel.mint : C.iconDefault,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tr('Set {0}', [s + 1]),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: sets[s]
                                        ? Colors.white
                                        : Pastel.mist.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              Text(
                                targetLabel,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: sets[s]
                                      ? Pastel.mint
                                      : Pastel.mist.withValues(alpha: 0.72),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (s < sets.length - 1) gap(8),
                    ],
                  ],
                ),
              ),

              // Collapsible Form & Breathing Guide
              if (spec != null) ...[
                gap(14),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _guideExpanded = !_guideExpanded);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const CoachAvatar(
                                mood: CoachMood.explain,
                                size: 56,
                                showGlow: false,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tr('Form & Breathing Guide'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                _guideExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 18,
                                color: C.iconDefault,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_guideExpanded) ...[
                        gap(10),
                        for (var i = 0; i < spec.steps.length; i++) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: C.lavender,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  spec.steps[i],
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Pastel.mist.withValues(alpha: 0.9),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          gap(6),
                        ],
                        gap(4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.wind,
                                size: 15, color: Pastel.mint),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                spec.breathCue,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Pastel.mint,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                        gap(6),
                        Text(
                          '${tr('Reference')}: ${spec.sourceRef}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Pastel.mist.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom thumb-zone navigation & primary action
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: C.voidBg.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: C.lavender.withValues(alpha: 0.14)),
            ),
          ),
          child: Row(
            children: [
              if (_index > 0) ...[
                IconButton.outlined(
                  tooltip: tr('Previous exercise'),
                  onPressed: () => _goToExercise(_index - 1),
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: pillButton(
                  allExerciseDone
                      ? (isLast
                          ? tr('Finish session')
                          : tr('Next exercise'))
                      : tr('Complete set'),
                  allExerciseDone
                      ? _goNextOrFinish
                      : _completeNextIncompleteSet,
                  icon: allExerciseDone
                      ? (isLast
                          ? LucideIcons.check
                          : LucideIcons.arrowRight)
                      : LucideIcons.circleCheck,
                ),
              ),
              if (!allExerciseDone && !isLast) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _goNextOrFinish,
                  child: Text(tr('Skip')),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffortCheckView(BuildContext context) {
    final elapsedMins =
        (DateTime.now().difference(_startedAt).inSeconds / 60).ceil().clamp(1, 180);
    final totalDoneSoFar = ref.read(workoutProvider).logs.length + 1;
    final isMilestone =
        totalDoneSoFar == 1 || totalDoneSoFar % 5 == 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(
          child: CoachAvatar(
            mood: isMilestone ? CoachMood.proud : CoachMood.celebrate,
            size: 130,
            glowColor: Pastel.mint,
            enablePulse: true,
          ),
        ),
        gap(14),
        Text(
          tr('You showed up today'),
          textAlign: TextAlign.center,
          style: display(30, color: Colors.white, weight: FontWeight.w600),
        ),
        gap(6),
        Text(
          tr('{0} {0?set|sets} completed · ~{1} min',
              [_totalCompletedSets > 0 ? _totalCompletedSets : 1, elapsedMins]),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: Pastel.mint,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        gap(22),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr("How did today's session feel?"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              gap(4),
              Text(
                tr('This helps me adjust your future pace gently—never as a test.'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: Pastel.mist.withValues(alpha: 0.8),
                ),
              ),
              gap(14),
              _EffortOptionTile(
                icon: LucideIcons.feather,
                color: Pastel.mint,
                title: tr('Too easy'),
                subtitle: tr('I felt I had plenty of energy left.'),
                busy: _saving,
                onTap: () => _submitEffort('easy'),
              ),
              gap(10),
              _EffortOptionTile(
                icon: LucideIcons.sparkles,
                color: C.lavender,
                title: tr('Just right'),
                subtitle: tr('Challenging enough, steady and comfortable.'),
                busy: _saving,
                onTap: () => _submitEffort('right'),
              ),
              gap(10),
              _EffortOptionTile(
                icon: LucideIcons.heartHandshake,
                color: C.coral,
                title: tr('A bit tough'),
                subtitle: tr('Felt demanding today—keep future targets gentle.'),
                busy: _saving,
                onTap: () => _submitEffort('tough'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EffortOptionTile extends StatelessWidget {
  const _EffortOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: busy ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.midnight.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            iconBadge(icon, color, size: 40, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Pastel.mist.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 18, color: C.iconDefault),
          ],
        ),
      ),
    );
  }
}
