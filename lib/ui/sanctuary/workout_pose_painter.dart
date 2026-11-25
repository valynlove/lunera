import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../../workout_catalog.dart';

/// Normalized 2D joint skeleton used to interpolate smoothly between Start & End poses.
class _PoseFrame {
  const _PoseFrame({
    required this.head,
    required this.shoulder,
    required this.hip,
    required this.knee,
    required this.foot,
    required this.elbow,
    required this.hand,
    this.kneeBack,
    this.footBack,
    this.elbowBack,
    this.handBack,
    this.focusJoint,
    this.hasWall = false,
  });

  final Offset head;
  final Offset shoulder;
  final Offset hip;
  final Offset knee;
  final Offset foot;
  final Offset elbow;
  final Offset hand;
  final Offset? kneeBack;
  final Offset? footBack;
  final Offset? elbowBack;
  final Offset? handBack;
  final Offset? focusJoint;
  final bool hasWall;

  static _PoseFrame lerp(_PoseFrame a, _PoseFrame b, double t) {
    Offset lp(Offset p, Offset q) => Offset(
          lerpDouble(p.dx, q.dx, t)!,
          lerpDouble(p.dy, q.dy, t)!,
        );
    Offset? lpOpt(Offset? p, Offset? q) {
      if (p == null && q == null) return null;
      return lp(p ?? q!, q ?? p!);
    }

    return _PoseFrame(
      head: lp(a.head, b.head),
      shoulder: lp(a.shoulder, b.shoulder),
      hip: lp(a.hip, b.hip),
      knee: lp(a.knee, b.knee),
      foot: lp(a.foot, b.foot),
      elbow: lp(a.elbow, b.elbow),
      hand: lp(a.hand, b.hand),
      kneeBack: lpOpt(a.kneeBack, b.kneeBack),
      footBack: lpOpt(a.footBack, b.footBack),
      elbowBack: lpOpt(a.elbowBack, b.elbowBack),
      handBack: lpOpt(a.handBack, b.handBack),
      focusJoint: lpOpt(a.focusJoint, b.focusJoint),
      hasWall: a.hasWall || b.hasWall,
    );
  }
}

(_PoseFrame start, _PoseFrame end) _framesFor(PoseKind kind) {
  switch (kind) {
    case PoseKind.gluteBridge:
      const a = _PoseFrame(
        head: Offset(0.22, 0.78),
        shoulder: Offset(0.32, 0.78),
        hip: Offset(0.55, 0.80),
        knee: Offset(0.68, 0.58),
        foot: Offset(0.78, 0.82),
        elbow: Offset(0.42, 0.82),
        hand: Offset(0.54, 0.82),
        focusJoint: Offset(0.55, 0.80),
      );
      const b = _PoseFrame(
        head: Offset(0.22, 0.78),
        shoulder: Offset(0.32, 0.76),
        hip: Offset(0.54, 0.58),
        knee: Offset(0.70, 0.56),
        foot: Offset(0.78, 0.82),
        elbow: Offset(0.42, 0.82),
        hand: Offset(0.54, 0.82),
        focusJoint: Offset(0.54, 0.58),
      );
      return (a, b);

    case PoseKind.squat:
      const a = _PoseFrame(
        head: Offset(0.48, 0.22),
        shoulder: Offset(0.48, 0.34),
        hip: Offset(0.47, 0.54),
        knee: Offset(0.50, 0.69),
        foot: Offset(0.49, 0.84),
        elbow: Offset(0.52, 0.44),
        hand: Offset(0.58, 0.48),
        focusJoint: Offset(0.47, 0.54),
      );
      const b = _PoseFrame(
        head: Offset(0.52, 0.38),
        shoulder: Offset(0.48, 0.48),
        hip: Offset(0.36, 0.65),
        knee: Offset(0.56, 0.66),
        foot: Offset(0.50, 0.84),
        elbow: Offset(0.60, 0.47),
        hand: Offset(0.70, 0.46),
        focusJoint: Offset(0.36, 0.65),
      );
      return (a, b);

    case PoseKind.splitSquat:
      const a = _PoseFrame(
        head: Offset(0.50, 0.22),
        shoulder: Offset(0.50, 0.34),
        hip: Offset(0.49, 0.54),
        knee: Offset(0.60, 0.68),
        foot: Offset(0.62, 0.84),
        kneeBack: Offset(0.39, 0.69),
        footBack: Offset(0.34, 0.84),
        elbow: Offset(0.54, 0.44),
        hand: Offset(0.60, 0.50),
        focusJoint: Offset(0.60, 0.68),
      );
      const b = _PoseFrame(
        head: Offset(0.50, 0.35),
        shoulder: Offset(0.50, 0.47),
        hip: Offset(0.48, 0.64),
        knee: Offset(0.64, 0.65),
        foot: Offset(0.63, 0.84),
        kneeBack: Offset(0.42, 0.78),
        footBack: Offset(0.33, 0.84),
        elbow: Offset(0.54, 0.54),
        hand: Offset(0.62, 0.54),
        focusJoint: Offset(0.64, 0.65),
      );
      return (a, b);

    case PoseKind.clamshell:
      const a = _PoseFrame(
        head: Offset(0.24, 0.70),
        shoulder: Offset(0.34, 0.73),
        hip: Offset(0.56, 0.74),
        knee: Offset(0.66, 0.76),
        foot: Offset(0.55, 0.82),
        kneeBack: Offset(0.66, 0.79),
        footBack: Offset(0.55, 0.82),
        elbow: Offset(0.26, 0.79),
        hand: Offset(0.34, 0.78),
        focusJoint: Offset(0.66, 0.76),
      );
      const b = _PoseFrame(
        head: Offset(0.24, 0.70),
        shoulder: Offset(0.34, 0.73),
        hip: Offset(0.56, 0.74),
        knee: Offset(0.64, 0.56),
        foot: Offset(0.55, 0.82),
        kneeBack: Offset(0.66, 0.79),
        footBack: Offset(0.55, 0.82),
        elbow: Offset(0.26, 0.79),
        hand: Offset(0.34, 0.78),
        focusJoint: Offset(0.64, 0.56),
      );
      return (a, b);

    case PoseKind.quadrupedHip:
      const a = _PoseFrame(
        head: Offset(0.26, 0.54),
        shoulder: Offset(0.36, 0.58),
        hip: Offset(0.62, 0.58),
        knee: Offset(0.62, 0.78),
        foot: Offset(0.72, 0.82),
        elbow: Offset(0.36, 0.70),
        hand: Offset(0.36, 0.82),
        focusJoint: Offset(0.62, 0.78),
      );
      const b = _PoseFrame(
        head: Offset(0.26, 0.54),
        shoulder: Offset(0.36, 0.58),
        hip: Offset(0.62, 0.58),
        knee: Offset(0.75, 0.58),
        foot: Offset(0.84, 0.64),
        kneeBack: Offset(0.61, 0.79),
        footBack: Offset(0.70, 0.82),
        elbow: Offset(0.36, 0.70),
        hand: Offset(0.36, 0.82),
        focusJoint: Offset(0.75, 0.58),
      );
      return (a, b);

    case PoseKind.deadBug:
      const a = _PoseFrame(
        head: Offset(0.24, 0.78),
        shoulder: Offset(0.35, 0.79),
        hip: Offset(0.58, 0.80),
        knee: Offset(0.60, 0.60),
        foot: Offset(0.74, 0.60),
        kneeBack: Offset(0.57, 0.62),
        footBack: Offset(0.70, 0.62),
        elbow: Offset(0.36, 0.66),
        hand: Offset(0.36, 0.54),
        focusJoint: Offset(0.47, 0.80),
      );
      const b = _PoseFrame(
        head: Offset(0.24, 0.78),
        shoulder: Offset(0.35, 0.79),
        hip: Offset(0.58, 0.80),
        knee: Offset(0.74, 0.75),
        foot: Offset(0.88, 0.76),
        kneeBack: Offset(0.57, 0.62),
        footBack: Offset(0.70, 0.62),
        elbow: Offset(0.26, 0.73),
        hand: Offset(0.14, 0.72),
        focusJoint: Offset(0.47, 0.80),
      );
      return (a, b);

    case PoseKind.birdDog:
      const a = _PoseFrame(
        head: Offset(0.28, 0.54),
        shoulder: Offset(0.38, 0.58),
        hip: Offset(0.62, 0.58),
        knee: Offset(0.62, 0.78),
        foot: Offset(0.72, 0.82),
        elbow: Offset(0.38, 0.70),
        hand: Offset(0.38, 0.82),
        focusJoint: Offset(0.50, 0.58),
      );
      const b = _PoseFrame(
        head: Offset(0.28, 0.54),
        shoulder: Offset(0.38, 0.58),
        hip: Offset(0.62, 0.58),
        knee: Offset(0.77, 0.58),
        foot: Offset(0.90, 0.58),
        kneeBack: Offset(0.62, 0.78),
        footBack: Offset(0.71, 0.82),
        elbow: Offset(0.25, 0.56),
        hand: Offset(0.14, 0.56),
        elbowBack: Offset(0.38, 0.70),
        handBack: Offset(0.38, 0.82),
        focusJoint: Offset(0.50, 0.58),
      );
      return (a, b);

    case PoseKind.pushUp:
      const a = _PoseFrame(
        head: Offset(0.24, 0.48),
        shoulder: Offset(0.33, 0.54),
        hip: Offset(0.56, 0.64),
        knee: Offset(0.71, 0.73),
        foot: Offset(0.84, 0.82),
        elbow: Offset(0.33, 0.68),
        hand: Offset(0.33, 0.82),
        focusJoint: Offset(0.33, 0.54),
      );
      const b = _PoseFrame(
        head: Offset(0.24, 0.66),
        shoulder: Offset(0.33, 0.70),
        hip: Offset(0.56, 0.75),
        knee: Offset(0.71, 0.78),
        foot: Offset(0.84, 0.82),
        elbow: Offset(0.41, 0.76),
        hand: Offset(0.33, 0.82),
        focusJoint: Offset(0.33, 0.70),
      );
      return (a, b);

    case PoseKind.wallPushUp:
      const a = _PoseFrame(
        head: Offset(0.56, 0.24),
        shoulder: Offset(0.58, 0.36),
        hip: Offset(0.63, 0.58),
        knee: Offset(0.67, 0.71),
        foot: Offset(0.70, 0.84),
        elbow: Offset(0.42, 0.37),
        hand: Offset(0.26, 0.38),
        focusJoint: Offset(0.58, 0.36),
        hasWall: true,
      );
      const b = _PoseFrame(
        head: Offset(0.40, 0.27),
        shoulder: Offset(0.43, 0.39),
        hip: Offset(0.55, 0.60),
        knee: Offset(0.63, 0.72),
        foot: Offset(0.70, 0.84),
        elbow: Offset(0.38, 0.45),
        hand: Offset(0.26, 0.38),
        focusJoint: Offset(0.43, 0.39),
        hasWall: true,
      );
      return (a, b);

    case PoseKind.overheadPress:
      const a = _PoseFrame(
        head: Offset(0.50, 0.24),
        shoulder: Offset(0.50, 0.36),
        hip: Offset(0.50, 0.57),
        knee: Offset(0.50, 0.71),
        foot: Offset(0.50, 0.84),
        elbow: Offset(0.40, 0.46),
        hand: Offset(0.39, 0.35),
        elbowBack: Offset(0.60, 0.46),
        handBack: Offset(0.61, 0.35),
        focusJoint: Offset(0.50, 0.36),
      );
      const b = _PoseFrame(
        head: Offset(0.50, 0.24),
        shoulder: Offset(0.50, 0.36),
        hip: Offset(0.50, 0.57),
        knee: Offset(0.50, 0.71),
        foot: Offset(0.50, 0.84),
        elbow: Offset(0.42, 0.24),
        hand: Offset(0.43, 0.13),
        elbowBack: Offset(0.58, 0.24),
        handBack: Offset(0.57, 0.13),
        focusJoint: Offset(0.50, 0.36),
      );
      return (a, b);

    case PoseKind.row:
      const a = _PoseFrame(
        head: Offset(0.34, 0.34),
        shoulder: Offset(0.40, 0.42),
        hip: Offset(0.58, 0.54),
        knee: Offset(0.54, 0.70),
        foot: Offset(0.54, 0.84),
        elbow: Offset(0.36, 0.56),
        hand: Offset(0.35, 0.68),
        focusJoint: Offset(0.40, 0.42),
      );
      const b = _PoseFrame(
        head: Offset(0.34, 0.34),
        shoulder: Offset(0.40, 0.42),
        hip: Offset(0.58, 0.54),
        knee: Offset(0.54, 0.70),
        foot: Offset(0.54, 0.84),
        elbow: Offset(0.52, 0.40),
        hand: Offset(0.48, 0.52),
        focusJoint: Offset(0.52, 0.40),
      );
      return (a, b);

    case PoseKind.plank:
      const a = _PoseFrame(
        head: Offset(0.22, 0.62),
        shoulder: Offset(0.32, 0.66),
        hip: Offset(0.56, 0.72),
        knee: Offset(0.71, 0.77),
        foot: Offset(0.84, 0.82),
        elbow: Offset(0.32, 0.81),
        hand: Offset(0.22, 0.82),
        focusJoint: Offset(0.52, 0.71),
      );
      const b = _PoseFrame(
        head: Offset(0.22, 0.61),
        shoulder: Offset(0.32, 0.65),
        hip: Offset(0.56, 0.70),
        knee: Offset(0.71, 0.76),
        foot: Offset(0.84, 0.82),
        elbow: Offset(0.32, 0.81),
        hand: Offset(0.22, 0.82),
        focusJoint: Offset(0.52, 0.70),
      );
      return (a, b);

    case PoseKind.backExtension:
      const a = _PoseFrame(
        head: Offset(0.22, 0.76),
        shoulder: Offset(0.34, 0.78),
        hip: Offset(0.58, 0.80),
        knee: Offset(0.73, 0.81),
        foot: Offset(0.86, 0.82),
        elbow: Offset(0.46, 0.80),
        hand: Offset(0.56, 0.80),
        focusJoint: Offset(0.38, 0.78),
      );
      const b = _PoseFrame(
        head: Offset(0.22, 0.72),
        shoulder: Offset(0.34, 0.74),
        hip: Offset(0.58, 0.80),
        knee: Offset(0.73, 0.81),
        foot: Offset(0.86, 0.82),
        elbow: Offset(0.26, 0.64),
        hand: Offset(0.14, 0.60),
        focusJoint: Offset(0.34, 0.74),
      );
      return (a, b);

    case PoseKind.stepMarch:
      const a = _PoseFrame(
        head: Offset(0.50, 0.22),
        shoulder: Offset(0.50, 0.34),
        hip: Offset(0.50, 0.55),
        knee: Offset(0.52, 0.70),
        foot: Offset(0.52, 0.84),
        kneeBack: Offset(0.48, 0.70),
        footBack: Offset(0.48, 0.84),
        elbow: Offset(0.42, 0.45),
        hand: Offset(0.40, 0.56),
        elbowBack: Offset(0.58, 0.45),
        handBack: Offset(0.60, 0.56),
        focusJoint: Offset(0.50, 0.55),
      );
      const b = _PoseFrame(
        head: Offset(0.50, 0.21),
        shoulder: Offset(0.50, 0.33),
        hip: Offset(0.50, 0.54),
        knee: Offset(0.63, 0.54),
        foot: Offset(0.63, 0.70),
        kneeBack: Offset(0.47, 0.70),
        footBack: Offset(0.47, 0.84),
        elbow: Offset(0.40, 0.42),
        hand: Offset(0.33, 0.34),
        elbowBack: Offset(0.58, 0.46),
        handBack: Offset(0.64, 0.53),
        focusJoint: Offset(0.63, 0.54),
      );
      return (a, b);

    case PoseKind.calfRaise:
      const a = _PoseFrame(
        head: Offset(0.50, 0.24),
        shoulder: Offset(0.50, 0.36),
        hip: Offset(0.50, 0.56),
        knee: Offset(0.50, 0.70),
        foot: Offset(0.52, 0.84),
        elbow: Offset(0.43, 0.46),
        hand: Offset(0.38, 0.54),
        focusJoint: Offset(0.50, 0.76),
      );
      const b = _PoseFrame(
        head: Offset(0.50, 0.19),
        shoulder: Offset(0.50, 0.31),
        hip: Offset(0.50, 0.51),
        knee: Offset(0.50, 0.65),
        foot: Offset(0.52, 0.80),
        elbow: Offset(0.43, 0.41),
        hand: Offset(0.38, 0.49),
        focusJoint: Offset(0.50, 0.72),
      );
      return (a, b);

    case PoseKind.catCow:
      const a = _PoseFrame(
        head: Offset(0.26, 0.52),
        shoulder: Offset(0.37, 0.59),
        hip: Offset(0.62, 0.58),
        knee: Offset(0.62, 0.78),
        foot: Offset(0.72, 0.82),
        elbow: Offset(0.37, 0.70),
        hand: Offset(0.37, 0.82),
        focusJoint: Offset(0.50, 0.62),
      );
      const b = _PoseFrame(
        head: Offset(0.27, 0.63),
        shoulder: Offset(0.37, 0.54),
        hip: Offset(0.62, 0.56),
        knee: Offset(0.62, 0.78),
        foot: Offset(0.72, 0.82),
        elbow: Offset(0.37, 0.69),
        hand: Offset(0.37, 0.82),
        focusJoint: Offset(0.50, 0.48),
      );
      return (a, b);

    case PoseKind.hipStretch:
      const a = _PoseFrame(
        head: Offset(0.48, 0.30),
        shoulder: Offset(0.48, 0.42),
        hip: Offset(0.48, 0.62),
        knee: Offset(0.63, 0.64),
        foot: Offset(0.63, 0.83),
        kneeBack: Offset(0.45, 0.82),
        footBack: Offset(0.30, 0.83),
        elbow: Offset(0.52, 0.52),
        hand: Offset(0.60, 0.58),
        focusJoint: Offset(0.48, 0.62),
      );
      const b = _PoseFrame(
        head: Offset(0.56, 0.32),
        shoulder: Offset(0.56, 0.44),
        hip: Offset(0.56, 0.65),
        knee: Offset(0.68, 0.65),
        foot: Offset(0.65, 0.83),
        kneeBack: Offset(0.43, 0.82),
        footBack: Offset(0.28, 0.83),
        elbow: Offset(0.60, 0.54),
        hand: Offset(0.67, 0.60),
        focusJoint: Offset(0.56, 0.65),
      );
      return (a, b);

    case PoseKind.thoracicTwist:
      const a = _PoseFrame(
        head: Offset(0.26, 0.70),
        shoulder: Offset(0.38, 0.74),
        hip: Offset(0.58, 0.76),
        knee: Offset(0.68, 0.66),
        foot: Offset(0.58, 0.82),
        elbow: Offset(0.30, 0.74),
        hand: Offset(0.20, 0.74),
        focusJoint: Offset(0.38, 0.74),
      );
      const b = _PoseFrame(
        head: Offset(0.26, 0.70),
        shoulder: Offset(0.38, 0.74),
        hip: Offset(0.58, 0.76),
        knee: Offset(0.68, 0.66),
        foot: Offset(0.58, 0.82),
        elbow: Offset(0.44, 0.58),
        hand: Offset(0.54, 0.46),
        focusJoint: Offset(0.44, 0.58),
      );
      return (a, b);

    case PoseKind.childsPose:
      const a = _PoseFrame(
        head: Offset(0.32, 0.68),
        shoulder: Offset(0.40, 0.70),
        hip: Offset(0.64, 0.70),
        knee: Offset(0.58, 0.82),
        foot: Offset(0.74, 0.82),
        elbow: Offset(0.26, 0.77),
        hand: Offset(0.16, 0.81),
        focusJoint: Offset(0.52, 0.70),
      );
      const b = _PoseFrame(
        head: Offset(0.30, 0.74),
        shoulder: Offset(0.39, 0.74),
        hip: Offset(0.66, 0.74),
        knee: Offset(0.58, 0.82),
        foot: Offset(0.74, 0.82),
        elbow: Offset(0.24, 0.80),
        hand: Offset(0.14, 0.82),
        focusJoint: Offset(0.52, 0.74),
      );
      return (a, b);
  }
}

/// Interactive 2-pose animated diagram widget for exercise form inspection.
///
/// Automatically respects system Reduce Motion and Flutter widget test environments
/// by using a static pose with manual Start/End pose controls instead of looping.
class WorkoutPoseStage extends StatefulWidget {
  const WorkoutPoseStage({
    super.key,
    required this.poseKind,
    this.height = 176,
    this.accent = C.lavender,
  });

  final PoseKind poseKind;
  final double height;
  final Color accent;

  @override
  State<WorkoutPoseStage> createState() => _WorkoutPoseStageState();
}

class _WorkoutPoseStageState extends State<WorkoutPoseStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _manualPoseEnd = false;
  bool _isPlaying = true;

  bool get _disableAutoLoop {
    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return isTestEnv || reduceMotion;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(covariant WorkoutPoseStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poseKind != widget.poseKind) {
      _manualPoseEnd = false;
      _syncLoop();
    }
  }

  void _syncLoop() {
    if (_disableAutoLoop || !_isPlaying) {
      _ctrl.stop();
      _ctrl.value = _manualPoseEnd ? 1.0 : 0.0;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _selectPose(bool endPose) {
    HapticFeedback.selectionClick();
    setState(() {
      _isPlaying = false;
      _manualPoseEnd = endPose;
    });
    _ctrl.stop();
    _ctrl.value = endPose ? 1.0 : 0.0;
  }

  void _togglePlay() {
    if (_disableAutoLoop) {
      _selectPose(!_manualPoseEnd);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _isPlaying = !_isPlaying);
    _syncLoop();
  }

  @override
  Widget build(BuildContext context) {
    final canAutoPlay = !_disableAutoLoop;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: C.midnight.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.28),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _isPlaying && canAutoPlay
                    ? Curves.easeInOutCubic.transform(_ctrl.value)
                    : (_manualPoseEnd ? 1.0 : 0.0);
                return CustomPaint(
                  painter: WorkoutPosePainter(
                    poseKind: widget.poseKind,
                    progress: t,
                    accent: widget.accent,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PosePillButton(
              label: tr('Start pose'),
              selected: (!_isPlaying || !canAutoPlay) && !_manualPoseEnd,
              onTap: () => _selectPose(false),
            ),
            const SizedBox(width: 8),
            if (canAutoPlay) ...[
              Tooltip(
                message: _isPlaying ? tr('Pause diagram') : tr('Play diagram'),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _togglePlay,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? widget.accent.withValues(alpha: 0.22)
                          : C.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      _isPlaying ? LucideIcons.pause : LucideIcons.play,
                      size: 16,
                      color: C.mist,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            _PosePillButton(
              label: tr('End pose'),
              selected: (!_isPlaying || !canAutoPlay) && _manualPoseEnd,
              onTap: () => _selectPose(true),
            ),
          ],
        ),
      ],
    );
  }
}

class _PosePillButton extends StatelessWidget {
  const _PosePillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? C.aurora.withValues(alpha: 0.28)
              : C.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? C.violet
                : C.lavender.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Pastel.mist.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter drawing a clean, minimalist 2-pose exercise diagram.
class WorkoutPosePainter extends CustomPainter {
  const WorkoutPosePainter({
    required this.poseKind,
    required this.progress,
    this.accent = C.lavender,
  });

  final PoseKind poseKind;
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final (start, end) = _framesFor(poseKind);
    final frame = _PoseFrame.lerp(start, end, progress.clamp(0.0, 1.0));

    Offset pt(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    // Subtle floor mat line
    final floorPaint = Paint()
      ..color = C.lavender.withValues(alpha: 0.22)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.85),
      Offset(size.width * 0.9, size.height * 0.85),
      floorPaint,
    );

    if (frame.hasWall) {
      canvas.drawLine(
        Offset(size.width * 0.23, size.height * 0.14),
        Offset(size.width * 0.23, size.height * 0.85),
        floorPaint,
      );
    }

    // Active muscle / joint halo
    if (frame.focusJoint != null) {
      final fj = pt(frame.focusJoint!);
      canvas.drawCircle(
        fj,
        18,
        Paint()..color = accent.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        fj,
        10,
        Paint()
          ..color = accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final backLimbPaint = Paint()
      ..color = C.violet.withValues(alpha: 0.55)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final limbPaint = Paint()
      ..color = C.mist
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final torsoPaint = Paint()
      ..color = accent
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    final hip = pt(frame.hip);
    final shoulder = pt(frame.shoulder);
    final head = pt(frame.head);
    final knee = pt(frame.knee);
    final foot = pt(frame.foot);
    final elbow = pt(frame.elbow);
    final hand = pt(frame.hand);

    // Back limbs first for depth clarity
    if (frame.kneeBack != null && frame.footBack != null) {
      final kb = pt(frame.kneeBack!);
      final fb = pt(frame.footBack!);
      canvas.drawLine(hip, kb, backLimbPaint);
      canvas.drawLine(kb, fb, backLimbPaint);
    }
    if (frame.elbowBack != null && frame.handBack != null) {
      final eb = pt(frame.elbowBack!);
      final hb = pt(frame.handBack!);
      canvas.drawLine(shoulder, eb, backLimbPaint);
      canvas.drawLine(eb, hb, backLimbPaint);
    }

    // Primary lower limb
    canvas.drawLine(hip, knee, limbPaint);
    canvas.drawLine(knee, foot, limbPaint);

    // Torso
    canvas.drawLine(hip, shoulder, torsoPaint);

    // Primary upper limb
    canvas.drawLine(shoulder, elbow, limbPaint);
    canvas.drawLine(elbow, hand, limbPaint);

    // Head
    canvas.drawCircle(head, 11, Paint()..color = C.mist);
    canvas.drawCircle(
      head,
      11,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant WorkoutPosePainter oldDelegate) =>
      oldDelegate.poseKind != poseKind ||
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent;
}
