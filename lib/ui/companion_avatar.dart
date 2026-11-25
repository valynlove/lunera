import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// Available expressions for Lunera's Eternal Dusk chibi companion.
enum CompanionMood {
  idle,
  happy,
  cheer,
  think,
  explain,
  ponder,
  care,
  calm,
  wave,
  remind,
  sleepy,
  wink,
  annoyed,
  confused,
  cry,
  facepalm,
  laugh,
  love,
  shocked,
  shy;

  String get assetPath => 'assets/images/companion/regular/$name.png';
}

/// Renders the Lunera companion illustration for a given [mood] with an optional ambient glow.
class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({
    super.key,
    required this.mood,
    this.size = 74,
    this.glowColor = C.aurora,
    this.showGlow = true,
    this.enablePulse = false,
  });

  final CompanionMood mood;
  final double size;
  final Color glowColor;
  final bool showGlow;
  final bool enablePulse;

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
      errorBuilder: (_, __, ___) => Icon(
        LucideIcons.sparkles,
        color: glowColor,
        size: size * 0.45,
      ),
    );

    if (!showGlow) {
      return SizedBox(width: size, height: size, child: image);
    }

    if (enablePulse && !reduceMotion) {
      return _PulsingCompanionGlow(
        size: size,
        glowColor: glowColor,
        child: image,
      );
    }

    return SizedBox(
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
}

class _PulsingCompanionGlow extends StatefulWidget {
  const _PulsingCompanionGlow({
    required this.glowColor,
    required this.size,
    required this.child,
  });

  final Color glowColor;
  final double size;
  final Widget child;

  @override
  State<_PulsingCompanionGlow> createState() => _PulsingCompanionGlowState();
}

class _PulsingCompanionGlowState extends State<_PulsingCompanionGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _animation = Tween<double>(begin: 0.16, end: 0.32).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (!isTestEnv) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 0.88,
              height: widget.size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.glowColor.withValues(alpha: _animation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}
