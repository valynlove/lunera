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
  wink;

  String get assetPath => 'assets/images/companion/$name.png';
}

/// Renders the Lunera companion illustration for a given [mood] with an optional ambient glow.
class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({
    super.key,
    required this.mood,
    this.size = 64,
    this.glowColor = C.aurora,
    this.showGlow = true,
  });

  final CompanionMood mood;
  final double size;
  final Color glowColor;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
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
