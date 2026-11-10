import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';

/// Celestial Arcane Astral splash screen inspired by the Lunera sanctuary aesthetic.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFF141936),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Celestial dreamy background
            Image.asset(
              'assets/images/arcane_astral_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF17264D),
                      Color(0xFF131D38),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
              ),
            ),

            // Soft starlight gradient scrim for contrast and depth
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.30),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Center: Celestial Crescent Moon Emblem + Wordmark + Star Divider + Tagline
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Celestial Crescent Moon with orbit rings
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD6B277).withValues(alpha: 0.40),
                            blurRadius: 42,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: C.peony.withValues(alpha: 0.32),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icons/celestial/moon_crescent.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LUNERA Wordmark
                    Text(
                      appName.toUpperCase(),
                      style: wordmark(
                        34,
                        color: Colors.white,
                      ).copyWith(
                        letterSpacing: 5.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFF1BA79).withValues(alpha: 0.65),
                            blurRadius: 18,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Celestial Star Divider
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
                                const Color(0xFFE8D3A5).withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: Color(0xFFE8D3A5),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE8D3A5).withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tagline: YOUR JOURNEY, YOUR PACE.
                    Text(
                      tr('YOUR JOURNEY, YOUR PACE.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.2,
                        color: Color(0xFFF4EBDA),
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
