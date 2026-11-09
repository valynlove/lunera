import 'package:flutter/material.dart';
import '../l10n.dart';
import '../theme.dart';

/// Minimal loading screen shown briefly while auth state resolves.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: C.deep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Cosmic backdrop
            Image.asset(
              'assets/images/arcane_astral_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F0E33), Color(0xFF14123A), Color(0xFF0B091E)],
                  ),
                ),
              ),
            ),
            // Atmospheric scrim
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F0E33).withValues(alpha: 0.62),
                    const Color(0xFF14123A).withValues(alpha: 0.72),
                    const Color(0xFF0B091E).withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
            // Centered logo + brand name + tagline
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          C.peony.withValues(alpha: 0.28),
                          const Color(0xFFF1BA79).withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFD6B277).withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: C.peony.withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFFF1BA79).withValues(alpha: 0.18),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Center(child: MoonLogo(size: 80)),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    appName,
                    style: wordmark(30, color: const Color(0xFFFCE3BD)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('Every Phase, Your Own.'),
                    textAlign: TextAlign.center,
                    style: display(
                      18,
                      color: Colors.white.withValues(alpha: 0.88),
                      weight: FontWeight.w500,
                    ),
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
