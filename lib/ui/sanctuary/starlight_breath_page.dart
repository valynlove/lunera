import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../responsive.dart';

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

/// Configurable breathing rhythm preset in seconds.
class BreathPreset {
  const BreathPreset({
    required this.id,
    required this.labelKey,
    required this.inhale,
    required this.holdIn,
    required this.exhale,
    this.holdOut = 0,
  });

  final String id;
  final String labelKey;
  final int inhale;
  final int holdIn;
  final int exhale;
  final int holdOut;

  int get totalSeconds => math.max(4, inhale + holdIn + exhale + holdOut);

  String get ratioLabel => holdOut > 0
      ? '$inhale-$holdIn-$exhale-$holdOut'
      : '$inhale-$holdIn-$exhale';
}

const List<BreathPreset> starlightBreathPresets = [
  BreathPreset(
      id: 'starlight', labelKey: 'Starlight', inhale: 4, holdIn: 4, exhale: 6),
  BreathPreset(
      id: 'box', labelKey: 'Box', inhale: 4, holdIn: 4, exhale: 4, holdOut: 4),
  BreathPreset(id: 'sleep', labelKey: 'Sleep', inhale: 4, holdIn: 7, exhale: 8),
  BreathPreset(
      id: 'sigh', labelKey: 'Calm Sigh', inhale: 4, holdIn: 1, exhale: 6),
];

/// Interactive calming starlight ripple canvas with customizable breathing presets and haptics.
class StarlightBreathPage extends StatefulWidget {
  const StarlightBreathPage({super.key});

  @override
  State<StarlightBreathPage> createState() => _StarlightBreathPageState();
}

class _StarlightBreathPageState extends State<StarlightBreathPage>
    with SingleTickerProviderStateMixin {
  static const _rippleLifetimeMs = 1900;

  late final AnimationController _controller;
  final List<_TouchRipple> _ripples = [];
  bool _paused = false;
  bool _hapticsOn = true;
  int _lastPanSpawnMs = 0;

  String _presetId = 'starlight';
  int _customInhale = 4;
  int _customHoldIn = 4;
  int _customExhale = 6;
  int _customHoldOut = 0;

  String _lastPhaseKey = '';
  double _prevProgress = 0.0;
  int _cyclesCompleted = 0;

  BreathPreset get _activePreset {
    if (_presetId == 'custom') {
      return BreathPreset(
        id: 'custom',
        labelKey: 'Custom',
        inhale: _customInhale,
        holdIn: _customHoldIn,
        exhale: _customExhale,
        holdOut: _customHoldOut,
      );
    }
    return starlightBreathPresets.firstWhere(
      (p) => p.id == _presetId,
      orElse: () => starlightBreathPresets.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _activePreset.totalSeconds),
    )
      ..addListener(_onBreathTick)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.removeListener(_onBreathTick);
    _controller.dispose();
    super.dispose();
  }

  void _onBreathTick() {
    if (_paused || !mounted) {
      return;
    }
    final v = _controller.value;
    if (v < _prevProgress - 0.5) {
      setState(() => _cyclesCompleted++);
    }
    _prevProgress = v;

    final phaseKey = _breathPhase(v).$1;
    if (phaseKey != _lastPhaseKey) {
      _lastPhaseKey = phaseKey;
      if (_hapticsOn) {
        if (phaseKey == 'inhale') {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  void _applyPresetDuration() {
    final total = _activePreset.totalSeconds;
    _controller.duration = Duration(seconds: total);
    _prevProgress = 0.0;
    _lastPhaseKey = '';
    if (!_paused) {
      _controller
        ..reset()
        ..repeat();
    } else {
      _controller.reset();
    }
  }

  void _selectPreset(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _presetId = id;
      _applyPresetDuration();
    });
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
    if (mounted) {
      setState(() {});
    }
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

  /// Returns (phaseKey, phaseLabel, remainingSeconds, orbScale [0.58..1.0]).
  (String, String, int, double) _breathPhase(double t) {
    final p = _activePreset;
    final total = p.totalSeconds.toDouble();
    final sec = (t * total).clamp(0.0, total - 0.0001);

    if (sec < p.inhale) {
      final frac = Curves.easeInOutSine.transform((sec / p.inhale).clamp(0.0, 1.0));
      final rem = (p.inhale - sec.floor()).clamp(1, p.inhale);
      return ('inhale', tr('Inhale softly'), rem, 0.58 + 0.42 * frac);
    }

    final afterInhale = sec - p.inhale;
    if (p.holdIn > 0 && afterInhale < p.holdIn) {
      final rem = (p.holdIn - afterInhale.floor()).clamp(1, p.holdIn);
      return ('holdIn', tr('Hold gently'), rem, 1.0);
    }

    final afterHoldIn = afterInhale - p.holdIn;
    if (afterHoldIn < p.exhale) {
      final frac =
          Curves.easeInOutSine.transform((afterHoldIn / p.exhale).clamp(0.0, 1.0));
      final rem = (p.exhale - afterHoldIn.floor()).clamp(1, p.exhale);
      return ('exhale', tr('Exhale slowly'), rem, 1.0 - 0.42 * frac);
    }

    final afterExhale = afterHoldIn - p.exhale;
    final rem = math.max(1, (p.holdOut - afterExhale.floor()));
    return ('holdOut', tr('Rest softly'), rem, 0.58);
  }

  void _openCustomSheet() {
    HapticFeedback.selectionClick();
    var inh = _customInhale;
    var hIn = _customHoldIn;
    var exh = _customExhale;
    var hOut = _customHoldOut;

    showSheet(
      context,
      StatefulBuilder(
        builder: (ctx, setModalState) {
          Widget sliderRow(
            String label,
            int val,
            int min,
            int max,
            ValueChanged<int> onChanged,
          ) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${val}s',
                          style: tabular(const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: C.lavender))),
                    ],
                  ),
                  Slider(
                    value: val.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    activeColor: C.aurora,
                    onChanged: (v) => setModalState(() => onChanged(v.round())),
                  ),
                ],
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('Custom Breathing Rhythm'), style: display(24)),
              gap(12),
              sliderRow(tr('Inhale'), inh, 2, 10, (v) => inh = v),
              sliderRow(tr('Hold after inhale'), hIn, 0, 10, (v) => hIn = v),
              sliderRow(tr('Exhale'), exh, 2, 12, (v) => exh = v),
              sliderRow(tr('Rest after exhale'), hOut, 0, 8, (v) => hOut = v),
              gap(10),
              pillButton(tr('Apply rhythm'), () {
                setState(() {
                  _customInhale = inh;
                  _customHoldIn = hIn;
                  _customExhale = exh;
                  _customHoldOut = hOut;
                  _presetId = 'custom';
                  _applyPresetDuration();
                });
                Navigator.pop(ctx);
              }, icon: LucideIcons.check),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final active = _activePreset;

    return Scaffold(
      body: SafeArea(
        child: AdaptivePageFrame(
          reading: true,
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
                    if (_cyclesCompleted > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Pastel.mint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Pastel.mint.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          '$_cyclesCompleted×',
                          style: tabular(const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Pastel.mint,
                          )),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final preset in starlightBreathPresets)
                      ChoiceChip(
                        label: Text(
                          '${tr(preset.labelKey)} ${preset.ratioLabel}',
                          style: tabular(const TextStyle(fontSize: 11.5)),
                        ),
                        selected: _presetId == preset.id,
                        onSelected: (_) => _selectPreset(preset.id),
                      ),
                    ChoiceChip(
                      label: Text(
                        _presetId == 'custom'
                            ? '${tr('Custom')} ${active.ratioLabel}'
                            : tr('Custom'),
                        style: tabular(const TextStyle(fontSize: 11.5)),
                      ),
                      selected: _presetId == 'custom',
                      onSelected: (_) => _openCustomSheet(),
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
                      final (_, label, secondsLeft, animatedScale) =
                          _breathPhase(_controller.value);
                      final orbScale = reduceMotion ? 0.8 : animatedScale;

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
                                  if (!_paused) ...[
                                    gap(6),
                                    Text(
                                      '${secondsLeft}s',
                                      style: tabular(TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            C.lavender.withValues(alpha: 0.90),
                                      )),
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
      if (age < 0 || age > lifetimeMs) {
        continue;
      }
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
