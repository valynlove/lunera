import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n.dart';
import '../theme.dart';

/// Layar pembuka: langit malam, tagline, lalu logo dan nama di bawah.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  Animation<double> _step(double a, double b) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _step(0, .35),
        taglineAnim = _step(.25, .65),
        rule = _step(.55, .8),
        brand = _step(.65, 1);

    return Theme(
      data: buildTheme(Brightness.dark),
      child: Scaffold(
        body: FadeTransition(
          opacity: scene,
          child: LakeScene(
            child: SafeArea(
              child: Stack(children: [
                Align(
                  alignment: const Alignment(0, -.12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FadeTransition(
                      opacity: taglineAnim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, .12), end: Offset.zero).animate(taglineAnim),
                        child: Text(
                          context.tr('Every phase,\nyour own.'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 40,
                            height: 1.15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    gap(26),
                    FadeTransition(
                      opacity: rule,
                      child: Container(
                        width: 56,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: .8),
                      ),
                    ),
                  ]),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: FadeTransition(
                      opacity: brand,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const MoonLogo(size: 56),
                        gap(8),
                        Text(appName, style: wordmark(24, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
