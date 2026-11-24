export 'home/alerts_card.dart';
export 'home/dose_card.dart';
export 'home/onboarding_step_tile.dart';
export 'home/slot_tile.dart';
export 'home/week_card.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../guides_data.dart';
import '../l10n.dart';
import '../models.dart';
import '../profile.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'ambient_companion.dart';
import 'article_page.dart';
import 'care_alerts_sheet.dart';
import 'companion_avatar.dart';
import 'home/alerts_card.dart';
import 'home/dose_card.dart';
import 'home/onboarding_step_tile.dart';
import 'home/week_card.dart';
import 'journal.dart';
import 'profile_page.dart';
import 'security_page.dart';
import 'sheets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).value ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = <DoseLog>[...(ref.watch(logsProvider).value ?? <DoseLog>[])]
      ..sort((a, b) => b.at.compareTo(a.at));
    final slots = buildSlots(ths, logs, prefs);
    final overdue = [
      for (final s in slots)
        if (s.status == 'overdue') s
    ];

    final displayName = ref.watch(displayNameProvider);
    final greet = greeting();

    final fg = Theme.of(context).colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // 1. Header (Airy, welcoming, high contrast)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greet,',
                    style: TextStyle(
                      fontSize: 14,
                      color: fg.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName ?? appName,
                          style: display(24, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: C.peony.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: C.peony.withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: Text(
                            'DEV',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: C.peony,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEEE, d MMMM y', L10n.code)
                        .format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Pastel.cream.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const CareAlertsBell(),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              tooltip: tr('Add therapy'),
              onPressed: () {
                HapticFeedback.lightImpact();
                showSheet(context, TherapySheet(supplies: supplies));
              },
              icon: const Icon(LucideIcons.plus),
            ),
            const SizedBox(width: 10),
            UserAvatar(
              size: 44,
              heroTag: 'profile_photo_hero',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. High-priority Banners (Overdue doses & Low supply alerts)
        if (overdue.isNotEmpty)
          OverdueAlertBanner(
            overdue: overdue,
            onReview: () =>
                showOverdueSheet(context, overdue, logs, supplies, prefs),
          ),
        AlertsCard(supplies: supplies),

        // 3. Main content
        if (ths.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
              children: [
                Text(tr('No therapies yet'), style: display(32)),
                gap(8),
                Text(
                  tr('Add your first medication to start tracking your schedule.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Pastel.mist.withValues(alpha: 0.85)),
                ),
                gap(18),
                pillButton(
                  tr('Add therapy'),
                  () {
                    HapticFeedback.lightImpact();
                    showSheet(context, TherapySheet(supplies: supplies));
                  },
                  icon: LucideIcons.plus,
                ),
                gap(24),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CompanionAvatar(
                            mood: CompanionMood.wave,
                            size: 54,
                            glowColor: C.aurora,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('Get started in 3 calm steps'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      gap(14),
                      OnboardingStepTile(
                        stepNumber: '1',
                        icon: LucideIcons.plus,
                        color: C.aurora,
                        title: tr('Add your first therapy'),
                        subtitle:
                            tr('Set up your medication, route, and schedule'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showSheet(context, TherapySheet(supplies: supplies));
                        },
                      ),
                      const Divider(height: 20),
                      OnboardingStepTile(
                        stepNumber: '2',
                        icon: LucideIcons.shieldCheck,
                        color: C.lavender,
                        title: tr('Protect your privacy'),
                        subtitle: tr(
                            'Optional PIN lock, Decoy Calculator & discreet reminders'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const SecurityPage()),
                          );
                        },
                      ),
                      if (guideById('start_safely') case final startGuide?) ...[
                        const Divider(height: 20),
                        OnboardingStepTile(
                          stepNumber: '3',
                          icon: LucideIcons.compass,
                          color: C.coral,
                          title: tr('Read the Start Here guide'),
                          subtitle: tr(
                              'Calm safety, dosing & harm-reduction essentials'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ArticlePage(article: startGuide),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Ambient Companion Card
          AmbientCompanionCard(
            now: DateTime.now(),
            logs: logs,
            slots: slots,
            therapies: ths,
          ),
          const SizedBox(height: 14),

          // Hero Dose Cards
          for (final t in ths)
            DoseCard(
                t: t,
                slots: slots,
                logs: logs,
                supplies: supplies,
                prefs: prefs),

          // 7-day Hormone Trend Curve
          WeekCard(ths: ths, logs: logs),

          // Quick Mood Check-in
          const MoodQuickCard(),

          // Seamless bridge to Calendar tab
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(tabProvider.notifier).state = 1;
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.calendarDays,
                        size: 16, color: Pastel.lilac),
                    const SizedBox(width: 8),
                    Text(
                      tr('View full schedule in Calendar'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Pastel.lilac,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: Pastel.lilac),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
