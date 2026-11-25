import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../sim.dart';
import '../../theme.dart';

/// Perkiraan level hormon 3 hari lalu sampai 4 hari ke depan (jika ada terapi yang bisa disimulasikan).
class WeekCard extends ConsumerWidget {
  const WeekCard({super.key, required this.ths, required this.logs});
  final List<Therapy> ths;
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeHormones = <String>[];
    final hormoneIntakes = <String, List<Intake>>{};
    for (final h in ['estradiol', 'progesterone', 'testosterone']) {
      final xs = intakesFor(h, ths, logs);
      if (xs.isNotEmpty) {
        activeHormones.add(h);
        hormoneIntakes[h] = xs;
      }
    }
    if (activeHormones.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now(),
        from = now.subtract(const Duration(days: 3)),
        to = now.add(const Duration(days: 4));

    final lines = <LineChartBarData>[];
    double maxTop = 1.0;
    final summaryTexts = <String>[];

    for (final h in activeHormones) {
      final intakes = hormoneIntakes[h]!;
      final spots = simSpots(intakes, from, to, n: 56);
      final top = spots.map((e) => e.y).fold<double>(1, math.max);
      if (top > maxTop) maxTop = top;

      final color = hormoneColor(h);
      final p = presetOf(h);
      final nowVal = levelAt(intakes, now);
      final valStr = h == 'progesterone'
          ? (nowVal < 1 ? nowVal.toStringAsFixed(2) : nowVal.toStringAsFixed(1))
          : (nowVal >= 20 ? '${nowVal.round()}' : fmt(nowVal));
      summaryTexts.add('${p.name}: $valStr ${p.base}');

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .22),
                color.withValues(alpha: .01),
              ],
            ),
          ),
        ),
      );
    }

    final top = maxTop * 1.2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: cardBox(context, radius: R.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  iconBadge(LucideIcons.chartLine, C.peony,
                      size: 28, iconSize: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Hormone Trend'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: tr('Levels'),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(tabProvider.notifier).state = 0;
                },
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('Levels'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: C.iconActive,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(LucideIcons.chevronRight,
                            size: 16, color: C.iconActive),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        gap(6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final h in activeHormones)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hormoneColor(h),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    h == 'estradiol'
                        ? 'Estradiol (E2)'
                        : (h == 'progesterone'
                            ? 'Progesterone (P4)'
                            : presetOf(h).name),
                    style: TextStyle(
                      fontSize: 11,
                      color: Pastel.mist.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        gap(8),
        SizedBox(
          height: 100,
          child: LineChart(LineChartData(
            minX: 0,
            maxX: 7,
            minY: 0,
            maxY: top,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            extraLinesData: ExtraLinesData(verticalLines: [
              VerticalLine(
                  x: 3,
                  color: Pastel.lilac.withValues(alpha: .40),
                  strokeWidth: 1.5,
                  dashArray: [4, 4]),
            ]),
            lineBarsData: lines,
          )),
        ),
        gap(4),
        Text(
          summaryTexts.join('  •  '),
          style: tabular(TextStyle(
              fontSize: 11.5,
              color: Pastel.mist.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}
