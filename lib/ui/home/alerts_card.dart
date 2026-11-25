import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../schedule.dart';
import '../../theme.dart';
import 'slot_tile.dart';

/// Stok yang hampir habis atau kedaluwarsa, supaya tidak baru ketahuan saat jadwal tiba.
class AlertsCard extends ConsumerWidget {
  const AlertsCard({super.key, required this.supplies});
  final List<Supply> supplies;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = <(IconData, String)>[];
    for (final s in supplies) {
      if (s.expired) {
        alerts.add(
            (LucideIcons.circleAlert, tr('{0} has expired', [s.name])));
        continue;
      }
      if (s.low) {
        alerts.add((
          LucideIcons.package,
          s.generic
              ? tr('{0} has {1} left', [s.name, fmt(s.qty)])
              : tr('{0} has {1} {1?dose|doses} left', [s.name, s.doses])
        ));
      }
      final d = s.daysToExpiry;
      if (d != null && d <= 30) {
        alerts.add((
          LucideIcons.calendarOff,
          tr('{0} expires in {1} {1?day|days}', [s.name, d])
        ));
      }
    }
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(tabProvider.notifier).state = 3;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: cardBox(context, radius: 20).copyWith(
              border:
                  Border.all(color: C.amber.withValues(alpha: .65), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconBadge(LucideIcons.package, C.amber,
                    size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerts.length == 1
                            ? tr('Supply alert ({0})', [alerts.length])
                            : tr('Supply alerts ({0})', [alerts.length]),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Pastel.butter),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alerts.first.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: Pastel.mist.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight,
                    size: 18, color: C.amber.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner peringatan ringkas untuk dosis yang terlewat.
class OverdueAlertBanner extends StatelessWidget {
  const OverdueAlertBanner({super.key, required this.overdue, required this.onReview});

  final List<Slot> overdue;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: C.nebula.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: C.coral.withValues(alpha: 0.60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: C.coral.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                iconBadge(LucideIcons.triangleAlert, C.coral,
                    size: 36, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('{0} missed {0?dose|doses}', [overdue.length]),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('Tap to review and log or skip'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Pastel.mist.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onReview();
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(tr('Review'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menampilkan modal bottom sheet (atau dialog di layar lebar) untuk meninjau dosis terlewat.
void showOverdueSheet(
  BuildContext context,
  List<Slot> overdue,
  List<DoseLog> logs,
  List<Supply> supplies,
  Prefs prefs,
) {
  HapticFeedback.mediumImpact();
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  Widget headerRow(BuildContext ctx, {bool showClose = false}) => Row(
        children: [
          iconBadge(LucideIcons.triangleAlert, C.coral,
              size: 36, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Missed Doses'),
                  style: display(22, weight: FontWeight.w700),
                ),
                Text(
                  tr('Review and catch up on pending doses'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (showClose)
            IconButton(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(LucideIcons.x, size: 20),
              tooltip: tr('Close'),
            ),
        ],
      );

  if (isWide) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: C.deepCard,
              borderRadius: BorderRadius.circular(R.modal),
              border: Border.all(
                color: C.lavender.withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerRow(ctx, showClose: true),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in overdue)
                        SlotTile(
                            s: s, logs: logs, supplies: supplies, prefs: prefs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: C.deepCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: C.lavender.withValues(alpha: 0.24),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ListView(
          controller: scroll,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            headerRow(ctx),
            const SizedBox(height: 18),
            for (final s in overdue)
              SlotTile(s: s, logs: logs, supplies: supplies, prefs: prefs),
          ],
        ),
      ),
    ),
  );
}
