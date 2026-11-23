import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../guides_data.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo.dart';
import '../schedule.dart';
import '../sim.dart';
import '../theme.dart';
import 'article_page.dart';
import 'insights.dart';
import 'journal.dart' show moodColor;
import '../l10n.dart';

part 'levels/levels_page.dart';
part 'levels/level_panel.dart';
part 'levels/hormone_page.dart';
part 'levels/lab_sheet.dart';

String _date(DateTime d) => DateFormat('d MMM y', L10n.code).format(d);

Widget _spark(List<double> ys, [Color? color]) => LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])
          ],
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: color ?? C.peony,
          barWidth: 3,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (color ?? C.peony).withValues(alpha: .24),
                (color ?? C.peony).withValues(alpha: .02),
              ],
            ),
          ),
        ),
      ],
    ));
