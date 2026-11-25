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
import '../workout_coach.dart';
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
import 'responsive.dart';
import 'sanctuary/coach_avatar.dart';
import 'sanctuary/workout_page.dart';
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
    final hasWorkoutCard = prefs.showWorkoutHomeCard;

    final header = Row(
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
                    child: Semantics(
                      header: true,
                      child: Text(
                        displayName ?? appName,
                        style: display(
                          context.isCompact ? 24 : 28,
                          weight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                            color: C.peony.withValues(alpha: 0.4), width: 1),
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
                style: tabular(
                  TextStyle(
                    fontSize: 11.5,
                    color: Pastel.cream.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
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
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: tr('Profile'),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: UserAvatar(
              size: 44,
              heroTag: 'profile_photo_hero',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ),
        ),
      ],
    );

    final calendarBridge = Center(
      child: Semantics(
        button: true,
        label: tr('View full schedule in Calendar'),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(tabProvider.notifier).state = 1;
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendarDays,
                      size: 16, color: Pastel.lilac),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      tr('View full schedule in Calendar'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Pastel.lilac,
                      ),
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
      ),
    );

    Widget buildEmptyState() {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
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
                            size: 70,
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
          ),
        ),
      );
    }

    Widget buildPopulatedContent() {
      final banners = <Widget>[
        if (overdue.isNotEmpty)
          OverdueAlertBanner(
            overdue: overdue,
            onReview: () =>
                showOverdueSheet(context, overdue, logs, supplies, prefs),
          ),
        AlertsCard(supplies: supplies),
      ];

      final doseCards = [
        for (final t in ths)
          DoseCard(
            t: t,
            slots: slots,
            logs: logs,
            supplies: supplies,
            prefs: prefs,
          ),
      ];

      final companion = AmbientCompanionCard(
        now: DateTime.now(),
        logs: logs,
        slots: slots,
        therapies: ths,
      );

      final week = WeekCard(ths: ths, logs: logs);

      final secondaryTools = <Widget>[
        const MoodQuickCard(),
        if (hasWorkoutCard)
          _HomeMovementCoachCard(
            therapies: ths,
            doseLogs: logs,
            prefs: prefs,
          ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (w >= kSplitMinWidth) {
            return AdaptiveSplitView(
              primaryFlex: 7,
              secondaryFlex: 5,
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...banners,
                  ...doseCards,
                  week,
                ],
              ),
              secondary: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  companion,
                  const SizedBox(height: 14),
                  const MoodQuickCard(),
                  if (hasWorkoutCard) ...[
                    const SizedBox(height: 12),
                    _HomeMovementCoachCard(
                      therapies: ths,
                      doseLogs: logs,
                      prefs: prefs,
                    ),
                  ],
                  const SizedBox(height: 10),
                  calendarBridge,
                ],
              ),
            );
          }

          if (w >= kCompactMaxWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...banners,
                companion,
                const SizedBox(height: 14),
                AdaptiveGrid(
                  compactColumns: 1,
                  mediumColumns: doseCards.length >= 2 ? 2 : 1,
                  expandedColumns: doseCards.length >= 2 ? 2 : 1,
                  minColumnWidth: 280,
                  children: doseCards,
                ),
                const SizedBox(height: 14),
                week,
                AdaptiveGrid(
                  compactColumns: 1,
                  mediumColumns: secondaryTools.length >= 2 ? 2 : 1,
                  expandedColumns: secondaryTools.length >= 2 ? 2 : 1,
                  minColumnWidth: 260,
                  children: secondaryTools,
                ),
                const SizedBox(height: 10),
                calendarBridge,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...banners,
              companion,
              const SizedBox(height: 14),
              ...doseCards,
              week,
              const MoodQuickCard(),
              if (hasWorkoutCard) ...[
                const SizedBox(height: 12),
                _HomeMovementCoachCard(
                  therapies: ths,
                  doseLogs: logs,
                  prefs: prefs,
                ),
              ],
              const SizedBox(height: 6),
              calendarBridge,
            ],
          );
        },
      );
    }

    return ListView(
      padding: context.pagePadding(top: 12, bottom: 32),
      children: [
        AdaptivePageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 16),
              if (ths.isEmpty) ...[
                if (overdue.isNotEmpty)
                  OverdueAlertBanner(
                    overdue: overdue,
                    onReview: () =>
                        showOverdueSheet(context, overdue, logs, supplies, prefs),
                  ),
                AlertsCard(supplies: supplies),
                buildEmptyState(),
              ] else
                buildPopulatedContent(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeMovementCoachCard extends ConsumerWidget {
  const _HomeMovementCoachCard({
    required this.therapies,
    required this.doseLogs,
    required this.prefs,
  });

  final List<Therapy> therapies;
  final List<DoseLog> doseLogs;
  final Prefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workoutProvider);
    final rec = evaluateCoachContext(
      now: DateTime.now(),
      profile: ws.profile,
      workoutLogs: ws.logs,
      therapies: therapies,
      doseLogs: doseLogs,
      prefs: prefs,
      customRoutines: ws.customRoutines,
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WorkoutCoachPage()),
        );
      },
      child: Row(
        children: [
          CoachAvatar(
            mood: rec.coachMood,
            size: 68,
            glowColor: Pastel.mint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Movement Coach'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rec.headline} · ${rec.recommendedRoutine.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: C.iconDefault),
        ],
      ),
    );
  }
}
