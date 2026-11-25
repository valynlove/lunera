import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../workout_coach.dart';
import '../companion_avatar.dart';

extension CoachMoodAssets on CoachMood {
  String get assetPath => 'assets/images/companion/coach/coach_$name.png';

  CompanionMood get fallbackCompanionMood => switch (this) {
        CoachMood.greet => CompanionMood.wave,
        CoachMood.explain => CompanionMood.explain,
        CoachMood.care => CompanionMood.care,
        CoachMood.cheer => CompanionMood.cheer,
        CoachMood.hydrate => CompanionMood.calm,
        CoachMood.celebrate => CompanionMood.happy,
        CoachMood.think => CompanionMood.think,
        CoachMood.proud => CompanionMood.love,
      };
}

/// Renders the sporty Lunera Personal Coach mascot for a given [mood].
class CoachAvatar extends StatelessWidget {
  const CoachAvatar({
    super.key,
    required this.mood,
    this.size = 84,
    this.glowColor = C.aurora,
    this.showGlow = true,
    this.enablePulse = false,
    this.semanticLabel,
  });

  final CoachMood mood;
  final double size;
  final Color glowColor;
  final bool showGlow;
  final bool enablePulse;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || isTestEnv;

    final image = Image.asset(
      mood.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => CompanionAvatar(
        mood: mood.fallbackCompanionMood,
        size: size,
        glowColor: glowColor,
        showGlow: false,
      ),
    );

    Widget content;
    if (!showGlow) {
      content = SizedBox(width: size, height: size, child: image);
    } else if (enablePulse && !reduceMotion) {
      content = _PulsingCoachGlow(
        size: size,
        glowColor: glowColor,
        child: image,
      );
    } else {
      content = SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            image,
          ],
        ),
      );
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        image: true,
        child: ExcludeSemantics(child: content),
      );
    }
    return ExcludeSemantics(child: content);
  }
}

class _PulsingCoachGlow extends StatefulWidget {
  const _PulsingCoachGlow({
    required this.size,
    required this.glowColor,
    required this.child,
  });

  final double size;
  final Color glowColor;
  final Widget child;

  @override
  State<_PulsingCoachGlow> createState() => _PulsingCoachGlowState();
}

class _PulsingCoachGlowState extends State<_PulsingCoachGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_ctrl.value);
              return Container(
                width: widget.size * (0.84 + 0.1 * t),
                height: widget.size * (0.84 + 0.1 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.glowColor.withValues(alpha: 0.16 + 0.14 * t),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}
