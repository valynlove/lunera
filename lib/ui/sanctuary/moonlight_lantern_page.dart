import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../sanctuary_data.dart';
import '../../theme.dart';
import '../responsive.dart';

/// Gentle, no-punishment companion lantern that blooms slowly as sparks are lit.
class MoonlightLanternPage extends StatefulWidget {
  const MoonlightLanternPage({super.key});

  @override
  State<MoonlightLanternPage> createState() => _MoonlightLanternPageState();
}

class _MoonlightLanternPageState extends State<MoonlightLanternPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  LanternState _state = const LanternState();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loaded = await SanctuaryStore.load();
      if (!mounted) return;
      setState(() {
        _state = loaded;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  Future<void> _lightSpark() async {
    HapticFeedback.lightImpact();
    try {
      final updated = await SanctuaryStore.lightTodaySpark();
      if (!mounted) return;
      setState(() => _state = updated);
    } catch (_) {
      // Ignore storage errors gracefully.
    }
  }

  String _stageTitle(int stage) {
    switch (stage) {
      case 0:
        return tr('Quiet Dusk');
      case 1:
        return tr('First Spark');
      case 2:
        return tr('Soft Bloom');
      case 3:
        return tr('Lantern Glow');
      default:
        return tr('Aurora Sanctuary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final canLight = _state.canLightToday();
    final affTuple =
        lanternAffirmations[_state.sparks % lanternAffirmations.length];
    final affirmation = L10n.code == 'id' ? affTuple.$2 : affTuple.$1;

    return Scaffold(
      body: SafeArea(
        child: AdaptivePageFrame(
          reading: true,
          child: ListView(
            padding: context.pagePadding(top: 12, bottom: 36),
            children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: tr('Back'),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tr('Moonlight Lantern'),
                    style: display(30),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            gap(12),
            SizedBox(
              height: 230,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) => CustomPaint(
                  painter: _MoonlightLanternPainter(
                    sparks: _state.sparks,
                    stage: _state.stage,
                    pulse: reduceMotion ? 0.5 : _glowController.value,
                  ),
                ),
              ),
            ),
            gap(8),
            Center(
              child: Text(
                _stageTitle(_state.stage),
                style: display(28, color: Colors.white),
              ),
            ),
            gap(4),
            Center(
              child: Text(
                tr('{0} {0?spark|sparks} lit', [_state.sparks]),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: C.lavender,
                ),
              ),
            ),
            gap(18),
            AppCard(
              highlight: true,
              padding: const EdgeInsets.all(18),
              child: Text(
                affirmation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Pastel.mist.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
            ),
            gap(18),
            if (!_loaded)
              const Center(child: CircularProgressIndicator())
            else if (canLight)
              pillButton(
                tr('Light today\'s gentle spark'),
                _lightSpark,
                icon: LucideIcons.sparkles,
                color: C.aurora,
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Pastel.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Pastel.mint.withValues(alpha: 0.36)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.check,
                        size: 18, color: Pastel.mint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('Today\'s spark is glowing. Come back whenever you like.'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Pastel.mint,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            gap(16),
            Text(
              tr('Your lantern never dims or resets if you skip days. Rest is part of care.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Pastel.mist.withValues(alpha: 0.72),
                height: 1.45,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _MoonlightLanternPainter extends CustomPainter {
  _MoonlightLanternPainter({
    required this.sparks,
    required this.stage,
    required this.pulse,
  });

  final int sparks;
  final int stage;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final baseGlow = 56.0 + stage * 18.0 + pulse * 10.0;

    // Soft outer twilight halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (stage >= 3 ? C.coral : C.aurora).withValues(alpha: 0.34),
          C.magenta.withValues(alpha: 0.14),
          Colors.transparent,
        ],
        stops: const [0.2, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseGlow * 1.6));
    canvas.drawCircle(center, baseGlow * 1.6, haloPaint);

    // Blooming light petals based on stage & sparks
    final petalCount = math.min(12, 4 + sparks);
    final petalOrbit = 42.0 + stage * 8.0;
    for (var i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * 2 * math.pi - math.pi / 2;
      final px = center.dx + math.cos(angle) * petalOrbit;
      final py = center.dy + math.sin(angle) * petalOrbit;
      final petalColor = i.isEven ? C.lavender : C.rose;
      canvas.drawCircle(
        Offset(px, py),
        i < sparks ? 5.5 + pulse * 1.5 : 2.5,
        Paint()
          ..color = petalColor.withValues(alpha: i < sparks ? 0.72 : 0.18),
      );
    }

    // Lantern glass body
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 64, height: 84),
      const Radius.circular(26),
    );
    canvas.drawRRect(
      glassRect,
      Paint()..color = C.deepCard.withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      glassRect,
      Paint()
        ..color = C.lavender.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Inner crescent ember
    final coreR = 12.0 + stage * 2.2 + pulse * 2.0;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.92),
          C.coral.withValues(alpha: 0.80),
          C.magenta.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: coreR * 1.8));
    canvas.drawCircle(center, coreR * 1.8, corePaint);
    canvas.drawCircle(
      center,
      coreR * 0.45,
      Paint()..color = Colors.white.withValues(alpha: sparks > 0 ? 0.95 : 0.45),
    );
  }

  @override
  bool shouldRepaint(_MoonlightLanternPainter oldDelegate) =>
      oldDelegate.sparks != sparks ||
      oldDelegate.stage != stage ||
      oldDelegate.pulse != pulse;
}
