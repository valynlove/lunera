import 'package:flutter/material.dart' show Color, IconData;
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'consultation_prep.dart';
import 'l10n.dart';
import 'models.dart';
import 'schedule.dart';
import 'theme.dart';

/// Level of urgency for an aggregated clinical care alert.
enum AlertPriority { critical, warning, info }

/// Destination navigation target for a care alert action button.
enum AlertActionTarget { logDose, supplies, calendar, consultation }

/// A unified actionable clinical care alert.
class CareAlert {
  const CareAlert({
    required this.id,
    required this.priority,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.target,
    required this.actionLabel,
  });

  final String id;
  final AlertPriority priority;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final AlertActionTarget target;
  final String actionLabel;
}

/// Evaluates active care alerts across therapies, supplies, schedule, trough windows, and doctor consultations.
List<CareAlert> evaluateCareAlerts({
  required List<Therapy> therapies,
  required List<DoseLog> logs,
  required List<Supply> supplies,
  required Prefs prefs,
  required ConsultationSession consultation,
  DateTime? now,
}) {
  final referenceTime = now ?? DateTime.now();
  final alerts = <CareAlert>[];

  // 1. Overdue doses within recent 7 days
  final recentSlots = buildSlots(therapies, logs, prefs, back: 7, ahead: 0);
  final overdueSlots = recentSlots.where((s) => s.status == 'overdue').toList();
  for (final slot in overdueSlots) {
    final isToday = slot.at.year == referenceTime.year &&
        slot.at.month == referenceTime.month &&
        slot.at.day == referenceTime.day;
    final timeStr = isToday
        ? DateFormat('HH:mm').format(slot.at)
        : DateFormat('d MMM, HH:mm', L10n.code).format(slot.at);
    alerts.add(
      CareAlert(
        id: 'overdue_${slot.t.id}_${slot.at.millisecondsSinceEpoch}',
        priority: AlertPriority.warning,
        icon: LucideIcons.clockAlert,
        color: C.coral,
        title: tr('Overdue Dose: {0}', [slot.t.name]),
        description: tr(
          'Scheduled dose from {0} was not logged. Log now or mark skipped.',
          [timeStr],
        ),
        target: AlertActionTarget.logDose,
        actionLabel: tr('Log Dose'),
      ),
    );
  }

  // 2. Critical, Depleted, or Open-Vial Beyond-Use Supplies
  final refToday = DateTime(
    referenceTime.year,
    referenceTime.month,
    referenceTime.day,
  );
  for (final s in supplies) {
    if (!s.generic && s.openExpiry != null && s.qty > 0) {
      final openDays = daysBetween(refToday, s.openExpiry!);
      if (openDays < 0) {
        alerts.add(
          CareAlert(
            id: 'openvial_exp_${s.id}',
            priority: AlertPriority.critical,
            icon: LucideIcons.alertTriangle,
            color: C.coral,
            title: tr('Open Vial Past Limit: {0}', [s.name]),
            description: tr(
              'Opened {0}-day window has passed. Replace with a fresh vial for safety.',
              [s.beyondUseDays],
            ),
            target: AlertActionTarget.supplies,
            actionLabel: tr('View Supplies'),
          ),
        );
      } else if (openDays <= 5) {
        alerts.add(
          CareAlert(
            id: 'openvial_soon_${s.id}',
            priority: AlertPriority.warning,
            icon: LucideIcons.flaskConical,
            color: C.amber,
            title: tr('Open Vial Expiring Soon: {0}', [s.name]),
            description: tr(
              '{0} {0?day|days} left in {1}-day open-vial window.',
              [openDays, s.beyondUseDays],
            ),
            target: AlertActionTarget.supplies,
            actionLabel: tr('View Supplies'),
          ),
        );
      }
    }

    final forecast = estimateSupplyForecast(s, therapies);
    if (forecast == null) continue;

    if (forecast.urgency == RefillUrgency.depleted) {
      alerts.add(
        CareAlert(
          id: 'depleted_${s.id}',
          priority: AlertPriority.critical,
          icon: LucideIcons.alertTriangle,
          color: C.coral,
          title: tr('Depleted: {0}', [s.name]),
          description: tr(
            'Stock is depleted. Order now to maintain uninterrupted therapy rhythm.',
          ),
          target: AlertActionTarget.supplies,
          actionLabel: tr('View Supplies'),
        ),
      );
    } else if (forecast.urgency == RefillUrgency.critical) {
      alerts.add(
        CareAlert(
          id: 'critical_${s.id}',
          priority: AlertPriority.warning,
          icon: LucideIcons.alertCircle,
          color: C.amber,
          title: tr('Reorder Urgently: {0}', [s.name]),
          description: tr(
            '~{0} days of stock remaining. Approaching runout date on {1}.',
            [
              forecast.daysLeft,
              '${forecast.runOutDate.day}/${forecast.runOutDate.month}'
            ],
          ),
          target: AlertActionTarget.supplies,
          actionLabel: tr('Reorder Assistant'),
        ),
      );
    }
  }

  // 3. Trough Lab Testing Window within next 48 hours
  final upcomingSlots = buildSlots(therapies, logs, prefs, back: 0, ahead: 4);
  final troughWindows = computeTroughWindows(upcomingSlots);
  for (final tw in troughWindows) {
    final hoursDiff = tw.targetDate.difference(referenceTime).inHours;
    if (hoursDiff >= -12 && hoursDiff <= 48) {
      alerts.add(
        CareAlert(
          id: 'trough_${tw.therapy.id}_${tw.targetDate.millisecondsSinceEpoch}',
          priority: AlertPriority.info,
          icon: LucideIcons.flaskConical,
          color: Pastel.mint,
          title: tr('Optimal Trough Lab Window'),
          description: tr(
            'Ideal time for blood draw before your next {0} dose to capture accurate baseline trough levels.',
            [tw.therapy.name],
          ),
          target: AlertActionTarget.calendar,
          actionLabel: tr('View Calendar'),
        ),
      );
    }
  }

  // 4. Upcoming Doctor Consultation within next 7 days
  if (consultation.scheduledAt != null && !consultation.isCompleted) {
    final daysUntil = consultation.scheduledAt!.difference(referenceTime).inDays;
    if (daysUntil >= 0 && daysUntil <= 7) {
      final clinicName = consultation.doctorOrClinic.isNotEmpty
          ? consultation.doctorOrClinic
          : tr('Doctor Visit');
      alerts.add(
        CareAlert(
          id: 'consultation_${consultation.id}',
          priority: AlertPriority.info,
          icon: LucideIcons.stethoscope,
          color: Pastel.sky,
          title: tr('Upcoming Appointment: {0}', [clinicName]),
          description: tr(
            '{0} questions and {1} checklist items prepared for your consultation.',
            [
              consultation.questions.length,
              consultation.checklist.where((c) => c.isChecked).length
            ],
          ),
          target: AlertActionTarget.consultation,
          actionLabel: tr('Open Prep Sheet'),
        ),
      );
    }
  }

  // Sort by priority (critical -> warning -> info)
  alerts.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  return alerts;
}
