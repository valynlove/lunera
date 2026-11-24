import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../care_alerts.dart';
import '../consultation_prep.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import 'consultation_prep_page.dart';

/// Tombol lonceng pengingat cerdas (Care Alerts Bell) dengan badge indikator.
class CareAlertsBell extends ConsumerWidget {
  const CareAlertsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapies = ref.watch(therapiesProvider).valueOrNull ?? const [];
    final logs = ref.watch(logsProvider).valueOrNull ?? const [];
    final supplies = ref.watch(suppliesProvider).valueOrNull ?? const [];
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final consultation = ref.watch(consultationProvider);

    final alerts = evaluateCareAlerts(
      therapies: therapies,
      logs: logs,
      supplies: supplies,
      prefs: prefs,
      consultation: consultation,
    );

    final hasCritical = alerts.any((a) => a.priority == AlertPriority.critical);
    final hasWarning = alerts.any((a) => a.priority == AlertPriority.warning);

    final badgeColor = hasCritical
        ? C.coral
        : (hasWarning ? C.amber : Pastel.mint);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: tr('Care Reminders & Alerts'),
          icon: const Icon(LucideIcons.bell, size: 20, color: C.iconDefault),
          onPressed: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const CareAlertsSheet(),
            );
          },
        ),
        if (alerts.isNotEmpty)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Lembar laci pengingat perawatan terpadu (Smart Care Alerts Sheet).
class CareAlertsSheet extends ConsumerWidget {
  const CareAlertsSheet({super.key});

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    AlertActionTarget target,
  ) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    switch (target) {
      case AlertActionTarget.logDose:
        ref.read(tabProvider.notifier).state = 2; // Home tab
        break;
      case AlertActionTarget.supplies:
        ref.read(tabProvider.notifier).state = 3; // Supplies tab
        break;
      case AlertActionTarget.calendar:
        ref.read(tabProvider.notifier).state = 1; // Calendar tab
        break;
      case AlertActionTarget.consultation:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ConsultationPrepPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapies = ref.watch(therapiesProvider).valueOrNull ?? const [];
    final logs = ref.watch(logsProvider).valueOrNull ?? const [];
    final supplies = ref.watch(suppliesProvider).valueOrNull ?? const [];
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final consultation = ref.watch(consultationProvider);

    final alerts = evaluateCareAlerts(
      therapies: therapies,
      logs: logs,
      supplies: supplies,
      prefs: prefs,
      consultation: consultation,
    );

    return Container(
      decoration: const BoxDecoration(
        color: C.midnight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: C.lavender.withValues(alpha: 0.35),
              ),
            ),
          ),
          gap(14),
          Row(
            children: [
              iconBadge(LucideIcons.bellRing, Pastel.sky),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Care Reminders'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      tr('{0} active care items require attention',
                          [alerts.length]),
                      style: TextStyle(
                        fontSize: 12,
                        color: Pastel.mist.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          gap(16),

          if (alerts.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                children: [
                  iconBadge(LucideIcons.checkCircle2, Pastel.mint),
                  gap(12),
                  Text(
                    tr('Everything is serene'),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  gap(4),
                  Text(
                    tr('All doses are logged, supplies are healthy, and no urgent care actions are pending.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Pastel.mist.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final alert = alerts[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: C.surface,
                      border: Border.all(
                        color: alert.color.withValues(alpha: 0.32),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: alert.color.withValues(alpha: 0.18),
                              ),
                              child: Icon(alert.icon,
                                  size: 16, color: alert.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                alert.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Pastel.mist.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: alert.color,
                            ),
                            icon: const Icon(LucideIcons.arrowRight, size: 14),
                            label: Text(
                              alert.actionLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _handleAction(
                              context,
                              ref,
                              alert.target,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
