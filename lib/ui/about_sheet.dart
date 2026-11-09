/// Modal bottom sheet "Tentang Lunera" ([AboutLuneraSheet]) yang menampilkan
/// informasi versi, filosofi desain Arcane Astral, pilar lore Lunera, prinsip utama,
/// penafian medis, dan tautan repositori (terinspirasi dari konsep Wall o' Pay).
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'app_changelog.dart';

/// Menampilkan modal bottom sheet berisi informasi aplikasi, filosofi brand, dan pilar lore Lunera.
void showAboutLuneraSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AboutLuneraSheet(),
  );
}

class AboutLuneraSheet extends StatelessWidget {
  const AboutLuneraSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.68);
    final borderColor = const Color(0xFFD6B277).withValues(alpha: dark ? 0.30 : 0.22);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? C.deepCard : theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFFD6B277).withValues(alpha: dark ? 0.35 : 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
              if (dark)
                BoxShadow(
                  color: C.peony.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('About {0}', [appName]),
                        style: display(20, color: dark ? Colors.white : C.midnight, weight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: tr('Close'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  children: [
                    // Brand Header Card
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  C.peony.withValues(alpha: 0.32),
                                  const Color(0xFFF1BA79).withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFFD6B277).withValues(alpha: 0.48),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: C.peony.withValues(alpha: 0.25),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: MoonLogo(size: 76),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            appName,
                            style: wordmark(26, color: const Color(0xFFFCE3BD)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF19143F).withValues(alpha: 0.8) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFD6B277).withValues(alpha: 0.38),
                              ),
                            ),
                            child: const Text(
                              'v${UpdateCheckerService.currentVersion} • Release',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF1BA79),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('Every Phase, Your Own.'),
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lore Quote Highlight Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF19143F).withValues(alpha: 0.6) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD6B277).withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            color: Color(0xFFF1BA79),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr('A serene celestial sanctuary for hormone journeys and mindful health tracking—every phase, your own.'),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: dark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Brand Lore & Philosophy
                    Text(
                      tr('Brand Lore & Philosophy'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Pastel.lilac,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('Lunera was created with a clear purpose: tracking hormone therapy and physical transitions should feel peaceful, empowering, and respectful—never cold or clinical.'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: mutedColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4 Lore Pillars
                    _LoreCard(
                      icon: Icons.nightlight_round,
                      iconColor: C.peony,
                      title: tr('The Moon Phase Rhythms'),
                      description: tr('Hormones fluctuate in graceful physiological waves. Lunera honors your body\'s unique cadence with personalized cycles and gentle rhythms.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.shield_outlined,
                      iconColor: Pastel.lilac,
                      title: tr('The Celestial Sanctuary'),
                      description: tr('Your personal health data is sacred. Lunera guards your journey with offline-first sovereignty, PBKDF2 encryption, and biometric privacy.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFF1BA79),
                      title: tr('The Guiding Star'),
                      description: tr('Scientific pharmacokinetic curves, intelligent injection site rotation, and supply alerts illuminate your path with clinical clarity.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.dark_mode_outlined,
                      iconColor: Pastel.sky,
                      title: tr('The Arcane Astral Canvas'),
                      description: tr('A nocturnal midnight aesthetic designed to reduce anxiety, replacing stark sterile hospital charts with celestial tranquility.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Section: Core Principles
                    Text(
                      tr('Core Principles'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Pastel.lilac,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PrincipleRow(
                      icon: Icons.offline_bolt_outlined,
                      title: tr('Offline-First Architecture'),
                      subtitle: tr('Fast local storage with zero network dependency and complete privacy.'),
                    ),
                    const SizedBox(height: 10),
                    _PrincipleRow(
                      icon: Icons.fingerprint_rounded,
                      title: tr('Biometric & Privacy Guard'),
                      subtitle: tr('Instant privacy shield, decoy calculator mode, and discreet push alerts.'),
                    ),
                    const SizedBox(height: 10),
                    _PrincipleRow(
                      icon: Icons.insights_rounded,
                      title: tr('Clinical Pharmacokinetics'),
                      subtitle: tr('Advanced mathematical simulations modeled for steady-state hormone levels.'),
                    ),
                    const SizedBox(height: 10),
                    _PrincipleRow(
                      icon: Icons.healing_rounded,
                      title: tr('Smart Site Rotation'),
                      subtitle: tr('Automated injection mapping to prevent lipohypertrophy and tissue fatigue.'),
                    ),
                    const SizedBox(height: 24),

                    // Section: Medical Disclaimer
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF161238).withValues(alpha: 0.8) : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD6B277).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            color: Color(0xFFF1BA79),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('Medical Disclaimer'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: Color(0xFFF1BA79),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$appName ${tr('is a tracking and reminder tool, not a substitute for medical advice. ')}${tr('Estimated levels use an average model and can differ from lab results. Dosing decisions always stay with your doctor.')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: dark ? Colors.white.withValues(alpha: 0.80) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: App Information
                    Text(
                      tr('App Information'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Pastel.lilac,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF19143F).withValues(alpha: 0.5) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _MetaRow(
                            label: tr('Developer'),
                            value: 'Valynlove / Lunera Team',
                          ),
                          const Divider(height: 16),
                          _MetaRow(
                            label: tr('License'),
                            value: 'MIT License (Open Source)',
                          ),
                          const Divider(height: 16),
                          _MetaRow(
                            label: tr('Source Code'),
                            value: tr('GitHub Repository'),
                            isLink: true,
                            onTap: () {
                              UpdateCheckerService.openUrl('https://github.com/valynlove/lunera');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Pastel.lilac,
                              side: BorderSide(color: Pastel.lilac.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.history_edu_rounded, size: 18),
                            label: Text(
                              tr('Version Changelog'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              showAppChangelogSheet(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: C.peony,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: C.peony.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.feedback_outlined, size: 18),
                            label: Text(
                              tr('Send Feedback'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              UpdateCheckerService.openUrl('https://github.com/valynlove/lunera/issues');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoreCard extends StatelessWidget {
  const _LoreCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Pastel.lilac, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isLink ? const Color(0xFFF1BA79) : null,
                ),
              ),
              if (isLink) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: Color(0xFFF1BA79),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
