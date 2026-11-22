import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../theme.dart';

class _TouchRipple {
  _TouchRipple({
    required this.center,
    required this.createdAtMs,
    required this.color,
  });

  final Offset center;
  final int createdAtMs;
  final Color color;
}

/// Interactive calming starlight ripple canvas with a gentle 4-4-6 breathing orb.
class StarlightBreathPage extends StatefulWidget {
  const StarlightBreathPage({super.key});

  @override
  State<StarlightBreathPage> createState() => _StarlightBreathPageState();
}

class _StarlightBreathPageState extends State<StarlightBreathPage>
    with SingleTickerProviderStateMixin {
  static const _cycleSeconds = 14; // 4s inhale + 4s hold + 6s exhale
  static const _rippleLifetimeMs = 1900;

  late final AnimationController _controller;
  final List<_TouchRipple> _ripples = [];
  bool _paused = false;
  bool _hapticsOn = true;
  int _lastPanSpawnMs = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cycleSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spawnRipple(Offset localPos, {bool haptic = true}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _ripples.removeWhere((r) => now - r.createdAtMs > _rippleLifetimeMs);
    const palette = [C.lavender, C.rose, C.coral, Pastel.mint];
    final color = palette[_ripples.length % palette.length];
    _ripples.add(_TouchRipple(
      center: localPos,
      createdAtMs: now,
      color: color,
    ));
    if (haptic && _hapticsOn) {
      HapticFeedback.selectionClick();
    }
    if (mounted) setState(() {});
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    });
  }

  /// Returns (phaseLabel, remainingSeconds, orbScale [0.58..1.0]).
  (String, int, double) _breathPhase(double t) {
    final sec = t * _cycleSeconds;
    if (sec < 4.0) {
      final p = Curves.easeInOutSine.transform(sec / 4.0);
      return (tr('Inhale softly'), (4 - sec.floor()).clamp(1, 4), 0.58 + 0.42 * p);
    }
    if (sec < 8.0) {
      final rem = (8 - sec.floor()).clamp(1, 4);
      return (tr('Hold gently'), rem, 1.0);
    }
    final ex = (sec - 8.0) / 6.0;
    final p = Curves.easeInOutSine.transform(ex.clamp(0.0, 1.0));
    final rem = (14 - sec.floor()).clamp(1, 6);
    return (tr('Exhale slowly'), rem, 1.0 - 0.42 * p);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                    tooltip: tr('Back'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tr('Starlight Ripples & Breath'),
                      style: display(26),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hapticsOn = !_hapticsOn);
                    },
                    icon: Icon(
                      _hapticsOn ? LucideIcons.sparkles : LucideIcons.moon,
                      size: 20,
                    ),
                    color: _hapticsOn ? C.lavender : C.iconDefault,
                    tooltip: _hapticsOn
                        ? tr('Gentle haptics on')
                        : tr('Gentle haptics off'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _spawnRipple(d.localPosition),
                onPanUpdate: (d) {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  if (now - _lastPanSpawnMs >= 160) {
                    _lastPanSpawnMs = now;
                    _spawnRipple(d.localPosition, haptic: false);
                  }
                },
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final nowMs = DateTime.now().millisecondsSinceEpoch;
                    final (label, secondsLeft, orbScale) =
                        reduceMotion ? (tr('Breathe at your pace'), 4, 0.8) : _breathPhase(_controller.value);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _StarlightCanvasPainter(
                            ripples: _ripples,
                            nowMs: nowMs,
                            lifetimeMs: _rippleLifetimeMs,
                            orbScale: orbScale,
                            ambientPhase: _controller.value,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                        Center(
                          child: IgnorePointer(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _paused ? tr('Paused') : label,
                                  style: display(30, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                if (!reduceMotion && !_paused) ...[
                                  gap(6),
                                  Text(
                                    '${secondsLeft}s',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: C.lavender.withValues(alpha: 0.90),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Text(
                    tr('Tap anywhere on the lake to send ripples of light'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Pastel.mist.withValues(alpha: 0.78),
                    ),
                  ),
                  gap(12),
                  pillButton(
                    _paused ? tr('Resume breath') : tr('Pause breath'),
                    _togglePause,
                    icon: _paused ? LucideIcons.play : LucideIcons.pause,
                    color: C.aurora,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarlightCanvasPainter extends CustomPainter {
  _StarlightCanvasPainter({
    required this.ripples,
    required this.nowMs,
    required this.lifetimeMs,
    required this.orbScale,
    required this.ambientPhase,
    required this.reduceMotion,
  });

  final List<_TouchRipple> ripples;
  final int nowMs;
  final int lifetimeMs;
  final double orbScale;
  final double ambientPhase;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.30;
    final currentR = maxR * orbScale;

    // Gentle twinkling background starlight dots
    final rnd = math.Random(19);
    for (var i = 0; i < 24; i++) {
      final sx = rnd.nextDouble() * size.width;
      final sy = rnd.nextDouble() * size.height;
      final baseAlpha = 0.18 + rnd.nextDouble() * 0.35;
      final twinkle = reduceMotion
          ? 1.0
          : 0.65 + 0.35 * math.sin((ambientPhase * 2 * math.pi) + i * 0.9);
      canvas.drawCircle(
        Offset(sx, sy),
        1.1 + (i % 3) * 0.5,
        Paint()..color = C.lavender.withValues(alpha: baseAlpha * twinkle),
      );
    }

    // Outer breathing halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          C.aurora.withValues(alpha: 0.32),
          C.magenta.withValues(alpha: 0.14),
          Colors.transparent,
        ],
        stops: const [0.25, 0.68, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: currentR * 1.38));
    canvas.drawCircle(center, currentR * 1.38, haloPaint);

    // Core breathing orb
    final orbPaint = Paint()
      ..color = C.deepCard.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentR, orbPaint);

    final rimPaint = Paint()
      ..color = C.lavender.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, currentR, rimPaint);

    // Touch ripples expanding & fading cleanly
    for (final ripple in ripples) {
      final age = nowMs - ripple.createdAtMs;
      if (age < 0 || age > lifetimeMs) continue;
      final t = Curves.easeOut.transform(age / lifetimeMs);
      final alpha = (1.0 - t).clamp(0.0, 1.0);
      final radius = 14.0 + t * 125.0;

      canvas.drawCircle(
        ripple.center,
        radius,
        Paint()
          ..color = ripple.color.withValues(alpha: alpha * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - t * 0.5),
      );
      canvas.drawCircle(
        ripple.center,
        radius * 0.52,
        Paint()
          ..color = ripple.color.withValues(alpha: alpha * 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        ripple.center,
        3.2 * (1.0 - t * 0.6),
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(_StarlightCanvasPainter oldDelegate) => true;
}
