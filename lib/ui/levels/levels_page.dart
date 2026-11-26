part of '../levels.dart';

class LevelsPage extends ConsumerWidget {
  const LevelsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labs = <Lab>[...(ref.watch(labsProvider).value ?? <Lab>[])]
      ..sort((a, b) => a.at.compareTo(b.at));
    final ths = ref.watch(therapiesProvider).value ?? <Therapy>[];
    // Hormon yang punya terapi dengan profil simulasi (injeksi atau oral), termasuk komponen sekunder obat kombinasi.
    final simIds = <String>{
      for (final t in ths) ...[
        if (pkOf(t.pk) != null) t.hormoneId,
        if (pkOf(t.secondaryPk) != null && t.secondaryHormoneId != null)
          t.secondaryHormoneId!,
      ]
    };
    final byH = <String, List<Lab>>{};
    for (final l in labs) {
      (byH[l.hormoneId] ??= []).add(l);
    }
    // Hormon yang hanya memiliki hasil lab (tanpa simulasi PK aktif)
    final labOnlyHormones = byH.keys.where((h) => !simIds.contains(h)).toList();

    final isWide = context.isWide;
    final addLabBtn = FilledButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        showSheet(context, const LabSheet());
      },
      icon: const Icon(LucideIcons.plus, size: 20),
      label: Text(tr('Add Lab Result'),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: C.peony,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        elevation: 2,
        shadowColor: C.peony.withValues(alpha: 0.35),
      ),
    );
    final insightsBtn = OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const InsightsPage()));
      },
      icon: const Icon(LucideIcons.activity, size: 20),
      label: Text(tr('Insights'), maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: C.lavender,
        backgroundColor: C.midnight.withValues(alpha: 0.55),
        side: BorderSide(
          color: C.lavender.withValues(alpha: 0.28),
          width: 1.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    );
    final guideBtn = switch (guideById('peak_trough')) {
      final guide? => IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ArticlePage(article: guide),
              ),
            );
          },
          icon: const Icon(LucideIcons.bookOpen, size: 22),
          color: C.iconDefault,
          tooltip: tr('Peak, Trough & Labs Guide'),
        ),
      null => null,
    };

    return ListView(
      padding: context.pagePadding(top: 12, bottom: 32),
      children: [
        AdaptivePageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Judul (+ aksi inline di layar lebar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(tr('Levels'),
                          style: display(isWide ? 36 : 40)),
                    ),
                  ),
                  if (guideBtn != null) guideBtn,
                  if (isWide) ...[
                    const SizedBox(width: 8),
                    insightsBtn,
                    const SizedBox(width: 10),
                    addLabBtn,
                  ],
                ],
              ),
              if (!isWide) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: addLabBtn),
                    const SizedBox(width: 10),
                    Expanded(child: insightsBtn),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // 3. Konten Utama / Empty State
              if (byH.isEmpty && simIds.isEmpty)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          iconBadge(LucideIcons.activity, Pastel.sky,
                              size: 56, iconSize: 28),
                          const SizedBox(height: 16),
                          Text(tr('No level data yet'), style: display(26)),
                          const SizedBox(height: 8),
                          Text(
                            tr('Log a dose or add your first blood test result to view hormone curves.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Pastel.mist.withValues(alpha: 0.85),
                                fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          pillButton(
                            tr('Add Lab Result'),
                            () {
                              HapticFeedback.lightImpact();
                              showSheet(context, const LabSheet());
                            },
                            icon: LucideIcons.plus,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                if (computeTroughLabReminder(
                  ths,
                  ref.watch(logsProvider).value ?? const <DoseLog>[],
                  labs,
                  ref.watch(prefsProvider).value ?? const Prefs(),
                )
                    case final reminder?) ...[
                  _TroughReminderCard(reminder: reminder),
                  const SizedBox(height: 14),
                ],
                // Kurva simulasi untuk hormon aktif (side-by-side di desktop bila >= 2 hormon)
                if (simIds.isNotEmpty) ...[
                  AdaptiveGrid(
                    compactColumns: 1,
                    mediumColumns: 1,
                    expandedColumns: simIds.length >= 2 ? 2 : 1,
                    minColumnWidth: 400,
                    children: [
                      for (final h in simIds) LevelPanel(h, compact: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Marker lab tersendiri tanpa simulasi PK (misalnya Prolaktin, LH, FSH)
                if (labOnlyHormones.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 0, 10),
                    child: Text(
                      tr('Blood Tests & Lab Markers'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  AdaptiveGrid(
                    compactColumns: 1,
                    mediumColumns: 2,
                    expandedColumns: 2,
                    minColumnWidth: 300,
                    children: [
                      for (final h in labOnlyHormones)
                        _LevelCard(hormoneId: h, labs: byH[h]!),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.hormoneId, required this.labs});
  final String hormoneId;
  final List<Lab> labs;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = presetOf(hormoneId), last = labs.last;
    final u =
        (ref.watch(prefsProvider).value ?? const Prefs()).unitOf(hormoneId);
    final f = p.units[u] ?? 1.0;
    final prev = labs.length > 1 ? labs[labs.length - 2] : null;
    final delta = prev == null || prev.base == 0
        ? null
        : (last.base - prev.base) / prev.base * 100;
    final recent = labs.length > 6 ? labs.sublist(labs.length - 6) : labs;
    final band = ref.watch(targetsProvider).value?[hormoneId];
    final hColor = hormoneColor(hormoneId);
    Widget? status;
    if (band != null) {
      final inRange = last.base >= band[0] && last.base <= band[1];
      final color = inRange ? Pastel.mint : C.amber;
      status = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Text(
          inRange
              ? tr('In range')
              : (last.base < band[0] ? tr('Below target') : tr('Above target')),
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
        ),
      );
    }
    return Semantics(
      button: true,
      label: '${p.name}, ${last.prefix}${fmt(last.base / f)} $u',
      child: Container(
        decoration: cardBox(context, radius: R.card),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(R.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(R.card),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HormonePage(hormoneId)));
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
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
                                      color: hColor.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('Lab result, {0}', [_date(last.at)]),
                          style: tabular(TextStyle(
                              fontSize: 12,
                              color: Pastel.mist.withValues(alpha: 0.85))),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        gap(8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(TextSpan(
                              text: '${last.prefix}${fmt(last.base / f)}',
                              style: tabular(display(36, color: Colors.white)),
                              children: [
                                TextSpan(
                                    text: ' $u',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Pastel.cream.withValues(alpha: 0.88),
                                        fontWeight: FontWeight.w500)),
                              ])),
                        ),
                        if (delta != null) ...[
                          gap(4),
                          Text(
                            tr('{0} {1}% from previous test', [
                              delta >= 0 ? '↑' : '↓',
                              delta.abs().toStringAsFixed(0)
                            ]),
                            style: tabular(TextStyle(
                                fontSize: 11.5,
                                color: Pastel.mist.withValues(alpha: 0.90),
                                fontWeight: FontWeight.w500)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (status != null) status,
                      ]),
                ),
                const SizedBox(width: 12),
                SizedBox(
                    width: 100,
                    height: 60,
                    child: _spark([for (final l in recent) l.base], hColor)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _TroughReminderCard extends ConsumerStatefulWidget {
  const _TroughReminderCard({required this.reminder});

  final TroughLabReminder reminder;

  @override
  ConsumerState<_TroughReminderCard> createState() =>
      _TroughReminderCardState();
}

class _TroughReminderCardState extends ConsumerState<_TroughReminderCard> {
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _loadScheduled();
  }

  Future<void> _loadScheduled() async {
    try {
      final at = await AppNotifier.instance.getScheduledTroughReminder();
      if (mounted) setState(() => _scheduledAt = at);
    } catch (_) {}
  }

  Future<void> _toggleReminder(Slot slot) async {
    HapticFeedback.selectionClick();
    if (_scheduledAt != null) {
      await AppNotifier.instance.cancelTroughLabReminder();
      if (mounted) setState(() => _scheduledAt = null);
      return;
    }
    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    final at = await AppNotifier.instance.scheduleTroughLabReminder(
      slot: slot,
      prefs: prefs,
    );
    if (mounted) setState(() => _scheduledAt = at);
  }

  Future<void> _pickNextLabDate() async {
    HapticFeedback.selectionClick();
    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    final now = DateTime.now();
    final initial = prefs.nextLabDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) {
      return;
    }
    await ref
        .read(repoProvider)
        ?.setPrefs(prefs.copy(nextLabDate: DateUtils.dateOnly(picked)));
  }

  Future<void> _clearNextLabDate() async {
    HapticFeedback.selectionClick();
    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    await ref.read(repoProvider)?.setPrefs(prefs.copy(clearNextLabDate: true));
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final slot = reminder.nextTroughSlot;
    final df = DateFormat('d MMM y', L10n.code);
    final String routineText;
    if (reminder.isCustomDate && reminder.nextRoutineLabDate != null) {
      final days = reminder.daysUntilTarget ?? 0;
      final countdown = days == 0
          ? tr('Scheduled today')
          : (days > 0
              ? tr('In {0} {0?day|days}', [days])
              : tr('{0} {0?day|days} overdue', [days.abs()]));
      routineText = tr('Next bloodwork: {0} ({1})', [
        df.format(reminder.nextRoutineLabDate!),
        countdown,
      ]);
    } else if (reminder.daysSinceLastLab == null) {
      routineText = tr(
          'No bloodwork logged yet — aim to test at trough after 4–8 weeks on a steady routine.');
    } else if (reminder.isDue) {
      routineText = tr(
          'Last bloodwork was {0} {0?day|days} ago — consider a routine 3-month check-in.',
          [reminder.daysSinceLastLab!]);
    } else {
      routineText = tr(
          'Last bloodwork: {0} {0?day|days} ago • Next 3-month check: {1}',
          [
            reminder.daysSinceLastLab!,
            df.format(reminder.nextRoutineLabDate!),
          ]);
    }

    final daysBadge = reminder.daysUntilTarget;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBadge(
            LucideIcons.flaskConical,
            reminder.isDue ? C.coral : Pastel.mint,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('Trough & Bloodwork Timing'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (daysBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (reminder.isDue ? C.coral : Pastel.mint)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (reminder.isDue ? C.coral : Pastel.mint)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          daysBadge <= 0
                              ? (daysBadge == 0
                                  ? tr('Today')
                                  : tr('{0}d due', [daysBadge.abs()]))
                              : tr('In {0}d', [daysBadge]),
                          style: tabular(TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: reminder.isDue ? C.coral : Pastel.mint,
                          )),
                        ),
                      ),
                    ],
                  ],
                ),
                if (slot != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    tr('Best trough blood-draw window: right before {0} on {1}',
                        [
                          slot.t.name,
                          DateFormat('EEE, d MMM • HH:mm', L10n.code)
                              .format(slot.at),
                        ]),
                    style: tabular(const TextStyle(
                      fontSize: 12,
                      color: C.lavender,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    )),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  routineText,
                  style: tabular(TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.82),
                    height: 1.35,
                  )),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (slot != null)
                      OutlinedButton.icon(
                        onPressed: () => _toggleReminder(slot),
                        icon: Icon(
                          _scheduledAt != null
                              ? LucideIcons.bellRing
                              : LucideIcons.bellPlus,
                          size: 15,
                        ),
                        label: Text(
                          _scheduledAt != null
                              ? tr('Trough reminder set')
                              : tr('Remind me 2h before trough'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _scheduledAt != null ? Pastel.mint : C.lavender,
                          side: BorderSide(
                            color: (_scheduledAt != null
                                    ? Pastel.mint
                                    : C.lavender)
                                .withValues(alpha: 0.45),
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _pickNextLabDate,
                      icon: const Icon(LucideIcons.calendarDays, size: 15),
                      label: Text(
                        reminder.isCustomDate
                            ? tr('Change lab date')
                            : tr('Set lab date'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.lavender,
                        side: BorderSide(
                          color: C.lavender.withValues(alpha: 0.4),
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (reminder.isCustomDate)
                      IconButton(
                        onPressed: _clearNextLabDate,
                        icon: const Icon(LucideIcons.x, size: 16),
                        color: C.iconDefault,
                        tooltip: tr('Clear lab date'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
