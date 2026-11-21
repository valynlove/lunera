part of '../levels.dart';

/// Grafik satu hormon: kurva perkiraan dari catatan dosis (semua cara pakai yang punya profil)
/// ditambah titik hasil lab dan area target. Satuan mengikuti pengaturan.
class LevelPanel extends ConsumerStatefulWidget {
  const LevelPanel(this.hormoneId, {super.key, this.compact = false});
  final String hormoneId;
  final bool compact;
  @override
  ConsumerState<LevelPanel> createState() => _LevelPanelState();
}

class _LevelPanelState extends ConsumerState<LevelPanel> {
  int? days;
  int off = 0; // geser jendela ke belakang, kelipatan lebar jendela
  bool cal = false;
  bool showMood = true; // penanda suasana hati di bawah grafik
  bool project = false;

  @override
  Widget build(BuildContext context) {
    final p = presetOf(widget.hormoneId);
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface, surface = theme.colorScheme.surface;
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    final logs = ref.watch(logsProvider).value ?? <DoseLog>[];
    final labs = (ref.watch(labsProvider).value ?? <Lab>[])
        .where((l) => l.hormoneId == widget.hormoneId)
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final band = ref.watch(targetsProvider).value?[widget.hormoneId];
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final u = prefs.unitOf(widget.hormoneId);
    final f = p.units[u] ?? 1.0; // nilai tampil = nilai dasar / f
    final intakes = intakesFor(widget.hormoneId, ths, logs);
    final hasSim = intakes.isNotEmpty;
    final projected = project && off == 0
        ? projectedIntakes(widget.hormoneId, ths, logs, prefs)
        : const <Intake>[];

    Widget box(List<Widget> kids) => Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: cardBox(context),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: kids),
        );

    if (!hasSim && labs.isEmpty) {
      return box([
        Text(tr('Estimated {0}', [p.name]),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        gap(8),
        Text(
            tr('Log your first dose on the Home tab to see estimated levels.')),
      ]);
    }

    final (k, nCal) = calibration(intakes, labs);
    final scale = cal && nCal > 0 ? k : 1.0;
    final now = DateTime.now();
    var d = days ?? (hasSim ? (widget.compact ? 30 : 90) : 0);
    if (d == 0 && labs.isEmpty) d = 30;
    final DateTime from, to;
    if (d == 0) {
      from = labs.first.at.subtract(const Duration(days: 1));
      to = (labs.last.at.isAfter(now) ? labs.last.at : now)
          .add(const Duration(days: 1));
    } else {
      final end = now.subtract(Duration(days: off * d));
      from = end.subtract(Duration(days: d));
      to = end.add(Duration(
          days: off == 0 ? (hasSim ? (project ? 60 : 14) : 1) : 1));
    }
    final total = to.difference(from).inMinutes / 1440;
    final sim = simSpots([...intakes, ...projected], from, to,
        scale: scale / f, n: math.max(40, math.min(1200, (total * 8).round())));
    final visibleLabs = [
      for (final l in labs)
        if (!l.at.isBefore(from) && !l.at.isAfter(to)) l,
    ];
    final dots = [
      for (final l in visibleLabs)
        FlSpot(l.at.difference(from).inMinutes / 1440, l.base / f),
    ];
    final bandD = band == null ? null : [band[0] / f, band[1] / f];
    final ys = <double>[
      ...sim.map((s) => s.y),
      ...dots.map((s) => s.y),
      ...?bandD
    ];
    final top = (ys.isEmpty ? 10.0 : ys.reduce(math.max)) * 1.15 + 1;
    final nowX =
        (now.difference(from).inMinutes / 1440).clamp(0.0, total).toDouble();
    final journal = ref.watch(journalProvider).value ?? <JournalEntry>[];
    final moodEntries = [
      for (final e in journal)
        if (e.mood != null && !e.at.isBefore(from) && !e.at.isAfter(to)) e
    ]..sort((a, b) => a.at.compareTo(b.at));
    final moodSpots = [
      for (final e in moodEntries)
        FlSpot(e.at.difference(from).inMinutes / 1440, top * .05)
    ];
    final drawMood = showMood && moodSpots.isNotEmpty;
    final dotBar = dots.isNotEmpty ? (sim.isNotEmpty ? 1 : 0) : -1;
    final moodBar =
        drawMood ? (sim.isNotEmpty ? 1 : 0) + (dots.isNotEmpty ? 1 : 0) : -1;

    final chart = LineChart(LineChartData(
      minX: 0,
      maxX: total,
      minY: 0,
      maxY: top,
      gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: fg.withValues(alpha: .08), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: math.max(total / 4, 1),
            getTitlesWidget: (v, m) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  DateFormat('d MMM', L10n.code)
                      .format(from.add(Duration(minutes: (v * 1440).round()))),
                  style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ),
      rangeAnnotations: bandD == null
          ? null
          : RangeAnnotations(horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                  y1: bandD[0],
                  y2: bandD[1],
                  color: Pastel.mint.withValues(alpha: .12)),
            ]),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) => [
            for (final s in touched)
              LineTooltipItem(
                s.barIndex == moodBar
                    ? tr(moods[moodEntries[s.spotIndex].mood]?.$1 ?? '')
                    : (s.barIndex == dotBar && s.spotIndex < visibleLabs.length
                        ? '${visibleLabs[s.spotIndex].prefix}${fmt(s.y)}'
                        : fmt(s.y)),
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
      extraLinesData: ExtraLinesData(verticalLines: [
        VerticalLine(
            x: nowX,
            color: Pastel.lilac.withValues(alpha: .40),
            strokeWidth: 1.8,
            dashArray: [4, 4]),
      ]),
      lineBarsData: [
        if (sim.isNotEmpty)
          LineChartBarData(
            spots: sim,
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: hormoneColor(widget.hormoneId),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  hormoneColor(widget.hormoneId).withValues(alpha: .24),
                  hormoneColor(widget.hormoneId).withValues(alpha: .01),
                ],
              ),
            ),
          ),
        if (dots.isNotEmpty)
          LineChartBarData(
            spots: dots,
            isCurved: !hasSim,
            preventCurveOverShooting: true,
            color: hormoneColor(widget.hormoneId),
            barWidth: hasSim ? 0 : 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (s, pc, b, i) => FlDotCirclePainter(
                radius: 6,
                color: surface,
                strokeWidth: 3.5,
                strokeColor: hormoneColor(widget.hormoneId),
              ),
            ),
          ),
        if (drawMood)
          LineChartBarData(
            spots: moodSpots,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
                getDotPainter: (s, pc, b, i) => FlDotCirclePainter(
                    radius: 5,
                    color: moodColor(moodEntries[i].mood),
                    strokeWidth: 0)),
          ),
      ],
    ));

    String lvl(double v) => widget.hormoneId == 'progesterone'
        ? (v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(1))
        : (v >= 20 ? '${v.round()}' : fmt(v));
    final est = hasSim ? levelAt(intakes, now) * scale / f : null;
    final estText = est == null ? '' : lvl(est);
    final pt = !widget.compact && hasSim ? peakTrough(sim) : null;
    final lastLab = labs.isNotEmpty ? labs.last : null;
    final hColor = hormoneColor(widget.hormoneId);
    bool? inRange;
    if (band != null && lastLab != null) {
      inRange = lastLab.base >= band[0] && lastLab.base <= band[1];
    }

    if (widget.compact) {
      final sparkPoints = sim.isNotEmpty
          ? [for (final s in sim) s.y]
          : [for (final l in labs) l.base / f];
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: cardBox(context),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HormonePage(widget.hormoneId)));
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: hColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: hColor.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasSim
                              ? tr('Estimated level now')
                              : (lastLab != null
                                  ? tr('Lab result, {0}', [_date(lastLab.at)])
                                  : tr('No recent data')),
                          style: TextStyle(
                            fontSize: 12,
                            color: Pastel.mist.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        gap(8),
                        if (est != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(
                                text: estText,
                                style: display(36, color: Colors.white),
                                children: [
                                  TextSpan(
                                    text: ' $u',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Pastel.cream.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (lastLab != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(
                                text: '${lastLab.prefix}${fmt(lastLab.base / f)}',
                                style: display(36, color: Colors.white),
                                children: [
                                  TextSpan(
                                    text: ' $u',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Pastel.cream.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (lastLab != null && hasSim) ...[
                          const SizedBox(height: 2),
                          Text(
                            tr('Latest lab: {0} {1} ({2})',
                                ['${lastLab.prefix}${fmt(lastLab.base / f)}', u, _date(lastLab.at)]),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Pastel.mist.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (band != null && lastLab != null && inRange != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (inRange ? Pastel.mint : C.amber)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: (inRange ? Pastel.mint : C.amber)
                                    .withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              inRange
                                  ? tr('In range')
                                  : (lastLab.base < band[0]
                                      ? tr('Below target')
                                      : tr('Above target')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: inRange ? Pastel.mint : C.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (sparkPoints.isNotEmpty)
                    SizedBox(
                      width: 100,
                      height: 60,
                      child: _spark(sparkPoints, hColor),
                    )
                  else
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: Pastel.lilac),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return box([
      Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: hColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: hColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasSim ? tr('Estimated {0}', [p.name]) : p.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (band != null && lastLab != null && inRange != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color:
                    (inRange ? Pastel.mint : C.amber).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      (inRange ? Pastel.mint : C.amber).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Text(
                inRange
                    ? tr('In range')
                    : (lastLab.base < band[0]
                        ? tr('Below target')
                        : tr('Above target')),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: inRange ? Pastel.mint : C.amber,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (widget.compact)
            IconButton(
              tooltip: tr('Open details'),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HormonePage(widget.hormoneId)));
              },
              icon: const Icon(LucideIcons.chevronRight,
                  size: 18, color: C.iconActive),
            ),
        ],
      ),
      if (est != null) ...[
        gap(4),
        Text.rich(TextSpan(
            text: estText,
            style: display(38, color: Colors.white),
            children: [
              TextSpan(
                  text: tr(' {0} now', [u]),
                  style: TextStyle(
                      fontSize: 13.5,
                      color: Pastel.cream.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500)),
            ])),
        if (lastLab != null) ...[
          const SizedBox(height: 2),
          Text(
            tr('Latest lab: {0} {1} ({2})',
                ['${lastLab.prefix}${fmt(lastLab.base / f)}', u, _date(lastLab.at)]),
            style: TextStyle(
                fontSize: 11.5,
                color: Pastel.mist.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500),
          ),
        ],
        if (pt != null) ...[
          const SizedBox(height: 2),
          Text(
            tr('Window peak ≈ {0} {1} · trough ≈ {2} {1}',
                [lvl(pt.peak), u, lvl(pt.trough)]),
            style: TextStyle(
                fontSize: 11.5,
                color: Pastel.mist.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500),
          ),
        ],
        gap(10),
      ],
      if (!widget.compact && d != 0)
        Row(children: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => off++);
            },
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          Expanded(
            child: Center(
              child: Text(
                tr('{0} to {1}',
                    [DateFormat('d MMM', L10n.code).format(from), _date(to)]),
                style: TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            onPressed: off > 0
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => off--);
                  }
                : null,
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ]),
      SizedBox(height: widget.compact ? 185 : 280, child: chart),
      gap(12),
      PillTabs<int>(
        items: [
          for (final w in [
            if (!widget.compact) 7,
            30,
            90,
            180,
            365,
            if (!hasSim && labs.isNotEmpty) 0
          ])
            (
              w,
              switch (w) {
                0 => tr('All'),
                7 => tr('1 wk'),
                30 => tr('1 mo'),
                90 => tr('3 mo'),
                180 => tr('6 mo'),
                _ => tr('1 yr')
              }
            ),
        ],
        value: d,
        onChanged: (w) {
          HapticFeedback.selectionClick();
          setState(() {
            days = w;
            off = 0;
          });
        },
      ),
      if (!widget.compact && (hasSim || moodEntries.isNotEmpty)) ...[
        gap(8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          if (hasSim)
            FilterChip(
              avatar: const Icon(LucideIcons.calendarClock, size: 16),
              label: Text(tr('Include upcoming doses')),
              selected: project,
              onSelected: (v) {
                HapticFeedback.selectionClick();
                setState(() => project = v);
              },
            ),
          if (hasSim && nCal > 0)
            FilterChip(
              label: Text(tr('Fit to lab results ({0})', [nCal])),
              selected: cal,
              onSelected: (v) {
                HapticFeedback.selectionClick();
                setState(() => cal = v);
              },
            ),
          if (moodEntries.isNotEmpty)
            FilterChip(
              avatar: const Icon(LucideIcons.smile, size: 16),
              label: Text(tr('Mood')),
              selected: showMood,
              onSelected: (v) {
                HapticFeedback.selectionClick();
                setState(() => showMood = v);
              },
            ),
        ]),
      ],
      gap(10),
      Wrap(
        spacing: 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (hasSim) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                        color: hColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text(tr('estimated'),
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          if (dots.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circle, size: 12, color: hColor),
                const SizedBox(width: 5),
                Text(tr('lab result'),
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          if (bandD != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: Pastel.mint.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text(tr('target'),
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
      if (widget.compact) ...[
        gap(10),
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HormonePage(widget.hormoneId)));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('View lab history & calibrate'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Pastel.lilac)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.arrowRight,
                      size: 13, color: Pastel.lilac),
                ],
              ),
            ),
          ),
        ),
      ] else ...[
        if (hasSim) ...[
          gap(8),
          Text(
            tr('Estimates use an average model, not lab results. Everyone\'s levels differ, and dosing decisions stay with your doctor.'),
            style: TextStyle(
                fontSize: 11, color: Pastel.mist.withValues(alpha: 0.75)),
          ),
          if (project && projected.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tr('Projection assumes upcoming doses are taken as scheduled.'),
              style: TextStyle(
                  fontSize: 11, color: Pastel.mist.withValues(alpha: 0.75)),
            ),
          ],
        ],
        if (drawMood) ...[
          gap(8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (final m in moods.entries)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.circle, size: 10, color: moodColor(m.key)),
                const SizedBox(width: 4),
                Text(tr(m.value.$1),
                    style: TextStyle(
                        fontSize: 11,
                        color: Pastel.mist.withValues(alpha: 0.85))),
              ]),
          ]),
        ],
      ],
    ]);
  }
}
