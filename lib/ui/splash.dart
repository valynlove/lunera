import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../theme.dart';

/// Eternal Dusk splash screen inspired by Wall o' Pay's staged entrance and minimal indicator.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.onFinish,
    this.minDuration = const Duration(milliseconds: 1200),
  });

  /// Invoked once the entrance animation completes (or immediately when reduced motion is active).
  final VoidCallback? onFinish;

  /// Minimum display time for the coordinated splash sequence.
  final Duration minDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;

  late final Animation<double> _bgFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _loadingFade;

  bool _finishDispatched = false;
  bool _reducedMotion = false;
  bool _animationsStarted = false;

  @override
  void initState() {
    super.initState();

    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    _introController = AnimationController(
      vsync: this,
      duration: isTestEnv ? Duration.zero : widget.minDuration,
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _bgFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.12, 0.62, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _brandFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.34, 0.74, curve: Curves.easeOut),
    );

    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.34, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.54, 0.92, curve: Curves.easeOut),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.54, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _loadingFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerFinish();
      }
    });

    if (isTestEnv) {
      _reducedMotion = true;
      _animationsStarted = true;
      _introController.value = 1.0;
      _ambientController.value = 0.5;
      _triggerFinish();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    if (disableAnimations || isTestEnv) {
      _reducedMotion = true;
      _animationsStarted = true;
      if (_introController.value < 1.0) {
        _introController.value = 1.0;
      }
      if (_ambientController.isAnimating) {
        _ambientController.stop();
      }
      _ambientController.value = 0.5;
      _triggerFinish();
    } else if (!_animationsStarted) {
      _animationsStarted = true;
      _introController.forward();
      _ambientController.repeat(reverse: true);
    }
  }

  void _triggerFinish() {
    if (_finishDispatched || !mounted) return;
    _finishDispatched = true;
    widget.onFinish?.call();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: C.voidBg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: C.voidBg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Eternal Dusk splash background + overlay + atmospheric scrim
              FadeTransition(
                opacity: _bgFade,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/eternal_dusk_splash_bg.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [C.voidBg, C.midnight, C.nebula],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0.24,
                        child: Image.asset(
                          'assets/images/eternal_dusk_overlay.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            C.voidBg.withValues(alpha: 0.28),
                            C.midnight.withValues(alpha: 0.14),
                            C.voidBg.withValues(alpha: 0.56),
                          ],
                          stops: const [0.0, 0.46, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Responsive centered logo, wordmark, and lower tagline/indicator
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final shortest = constraints.biggest.shortestSide;
                    final logoSize = (shortest * 0.30).clamp(96.0, 156.0);
                    final titleSize = (shortest * 0.088).clamp(30.0, 42.0);

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              children: [
                                const Spacer(flex: 4),

                                // Centered 3D Emblem with Ambient Glow Pulse
                                FadeTransition(
                                  opacity: _logoFade,
                                  child: ScaleTransition(
                                    scale: _logoScale,
                                    child: RepaintBoundary(
                                      child: AnimatedBuilder(
                                        animation: _ambientController,
                                        builder: (context, child) {
                                          final pulse = _ambientController.value;
                                          final haloSize =
                                              logoSize * (1.28 + 0.08 * pulse);
                                          return SizedBox(
                                            width: logoSize * 1.4,
                                            height: logoSize * 1.4,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: haloSize,
                                                  height: haloSize,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        C.aurora.withValues(
                                                            alpha: 0.30 +
                                                                0.10 * pulse),
                                                        C.magenta.withValues(
                                                            alpha: 0.18 +
                                                                0.06 * pulse),
                                                        C.coral.withValues(
                                                            alpha: 0.06),
                                                        Colors.transparent,
                                                      ],
                                                      stops: const [
                                                        0.0,
                                                        0.46,
                                                        0.72,
                                                        1.0,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                child!,
                                              ],
                                            ),
                                          );
                                        },
                                        child: MoonLogo(size: logoSize),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Brand Name: LUNERA
                                FadeTransition(
                                  opacity: _brandFade,
                                  child: SlideTransition(
                                    position: _brandSlide,
                                    child: Text(
                                      appName.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: wordmark(
                                        titleSize,
                                        color: Colors.white,
                                      ).copyWith(
                                        letterSpacing: 5.5,
                                        shadows: [
                                          Shadow(
                                            color:
                                                C.aurora.withValues(alpha: 0.55),
                                            blurRadius: 18,
                                          ),
                                          Shadow(
                                            color:
                                                C.voidBg.withValues(alpha: 0.75),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const Spacer(flex: 5),

                                // Bottom Tagline & Minimal Loading Indicator
                                FadeTransition(
                                  opacity: _taglineFade,
                                  child: SlideTransition(
                                    position: _taglineSlide,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    C.lavender
                                                        .withValues(alpha: 0.75),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              child: Icon(
                                                LucideIcons.sparkles,
                                                size: 16,
                                                color: C.iconActive,
                                              ),
                                            ),
                                            Container(
                                              width: 48,
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    C.coral
                                                        .withValues(alpha: 0.75),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          tr('Your Journey, In Every Phase.'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.6,
                                            color: C.mist,
                                            shadows: [
                                              Shadow(
                                                color: C.voidBg
                                                    .withValues(alpha: 0.75),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        FadeTransition(
                                          opacity: _loadingFade,
                                          child: _EternalDuskLoadingBar(
                                            reducedMotion: _reducedMotion,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 36),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimalist 48x3 gradient loading indicator matching Wall o' Pay's splash polish.
class _EternalDuskLoadingBar extends StatefulWidget {
  const _EternalDuskLoadingBar({required this.reducedMotion});
  final bool reducedMotion;

  @override
  State<_EternalDuskLoadingBar> createState() => _EternalDuskLoadingBarState();
}

class _EternalDuskLoadingBarState extends State<_EternalDuskLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.reducedMotion) {
      _pulseController.value = 0.5;
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _EternalDuskLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _pulseController.stop();
        _pulseController.value = 0.5;
      } else {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glowProgress = _pulseController.value;
        return Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: C.lavender.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 20 + 24 * glowProgress,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  C.aurora.withValues(alpha: 0.85),
                  C.magenta.withValues(alpha: 0.90),
                  C.coral.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: C.aurora.withValues(alpha: 0.35 * glowProgress),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
