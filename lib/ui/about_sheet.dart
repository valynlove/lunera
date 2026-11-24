/// Modal bottom sheet "Tentang Lunera" ([AboutLuneraSheet]) yang menampilkan
/// informasi versi, filosofi desain Arcane Astral, pilar lore Lunera, prinsip utama,
/// penafian medis, dan tautan repositori dengan ikon surgawi otentik.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'app_changelog.dart';

/// Displays the About Lunera modal sheet with Eternal Dusk branding, lore pillars,
/// core architecture principles, medical disclaimer, and source links.
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
    final mutedColor = C.mist.withValues(alpha: 0.78);
    final borderColor = C.lavender.withValues(alpha: dark ? 0.22 : 0.18);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? C.deepCard : theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: C.lavender.withValues(alpha: dark ? 0.28 : 0.20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
              if (dark)
                BoxShadow(
                  color: C.aurora.withValues(alpha: 0.16),
                  blurRadius: 28,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 24, color: C.iconActive),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('About {0}', [appName]),
                        style: display(22, color: dark ? Colors.white : C.midnight, weight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 24),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    // Brand Header Showcase
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  C.aurora.withValues(alpha: 0.36),
                                  C.magenta.withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: C.lavender.withValues(alpha: 0.48),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: C.aurora.withValues(alpha: 0.32),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: MoonLogo(size: 80),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            appName,
                            style: wordmark(28, color: C.lavender),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: dark ? C.nebula.withValues(alpha: 0.85) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: C.lavender.withValues(alpha: 0.38),
                              ),
                            ),
                            child: Text(
                              'v${UpdateCheckerService.currentVersion} • ${tr('Eternal Dusk Edition')}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: C.lavender,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('Every Phase, Your Own.'),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Lore Manifesto Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? C.nebula.withValues(alpha: 0.58) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: C.lavender.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.quote, size: 24, color: C.coral),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              tr('Lunera was created with a clear purpose: tracking hormone therapy and physical transitions should feel peaceful, empowering, and respectful—never cold or clinical.'),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.48,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: dark ? C.mist.withValues(alpha: 0.94) : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Pillars of Care
                    Row(
                      children: [
                        const Icon(LucideIcons.sparkles, size: 18, color: C.iconActive),
                        const SizedBox(width: 8),
                        Text(
                          tr('Brand Lore & Philosophy'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Pastel.lilac,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4 Lore Pillars
                    _LoreCard(
                      icon: LucideIcons.moon,
                      iconColor: Pastel.lilac,
                      title: tr('The Moon Phase Rhythms'),
                      description: tr(
                          'Hormones fluctuate in graceful physiological waves. Lunera honors your body\'s unique cadence with personalized cycles and gentle rhythms.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: LucideIcons.shield,
                      iconColor: C.amber,
                      title: tr('The Celestial Sanctuary'),
                      description: tr(
                          'Your personal health data is sacred. Lunera guards your journey with offline-first sovereignty, PBKDF2 encryption, and biometric privacy.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: LucideIcons.sparkles,
                      iconColor: Pastel.mint,
                      title: tr('The Guiding Star'),
                      description: tr(
                          'Scientific pharmacokinetic curves, intelligent injection site rotation, and supply alerts illuminate your path with clinical clarity.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: LucideIcons.paintbrush,
                      iconColor: C.magenta,
                      title: tr('The Eternal Dusk Canvas'),
                      description: tr(
                          'An atmospheric midnight aurora and twilight sunset aesthetic designed to calm anxiety, replacing stark clinical charts with serene warmth.'),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Section: Core Sovereignty & Architecture
                    Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 18, color: C.iconActive),
                        const SizedBox(width: 8),
                        Text(
                          tr('Core Principles'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Pastel.lilac,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PrincipleRow(
                      icon: LucideIcons.zap,
                      title: tr('Offline-First Architecture'),
                      subtitle: tr('Fast local storage with zero network dependency and complete data ownership.'),
                    ),
                    const SizedBox(height: 12),
                    _PrincipleRow(
                      icon: LucideIcons.fingerprintPattern,
                      title: tr('Biometric & Privacy Guard'),
                      subtitle: tr('Instant privacy shield, decoy calculator mode, and discreet masked push alerts.'),
                    ),
                    const SizedBox(height: 12),
                    _PrincipleRow(
                      icon: LucideIcons.timer,
                      title: tr('Guided Calm Injection'),
                      subtitle: tr('Step-by-step calming assistant with injection angle guidance and breathing pacing.'),
                    ),
                    const SizedBox(height: 12),
                    _PrincipleRow(
                      icon: LucideIcons.bellRing,
                      title: tr('Precision Reminders'),
                      subtitle: tr('Alarm-manager powered scheduled doses and automatic supply pickup alerts.'),
                    ),
                    const SizedBox(height: 24),

                    // Section: Medical Disclaimer
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: dark ? C.nebula.withValues(alpha: 0.72) : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: C.coral.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.stethoscope, size: 24, color: C.coral),
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
                                    color: C.coral,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$appName ${tr('is a tracking and reminder tool, not a substitute for medical advice. ')}${tr('Estimated levels use an average model and can differ from lab results. Dosing decisions always stay with your doctor.')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: dark ? C.mist.withValues(alpha: 0.88) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: App Information & Transparency
                    Row(
                      children: [
                        const Icon(LucideIcons.info, size: 18, color: C.iconActive),
                        const SizedBox(width: 8),
                        Text(
                          tr('App Information'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Pastel.lilac,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? C.midnight.withValues(alpha: 0.65) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
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
                              foregroundColor: C.iconActive,
                              side: BorderSide(color: C.iconActive.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(LucideIcons.bookOpen, size: 18),
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
                            icon: const Icon(LucideIcons.messageSquare, size: 18),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.76),
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Pastel.lilac, size: 20),
        ),
        const SizedBox(width: 12),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
        if (isLink)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Pastel.sky,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: Pastel.sky,
                  ),
                ],
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
      ],
    );
  }
}
