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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // 1. Header Judul
        Row(
          children: [
            Expanded(child: Text(tr('Levels'), style: display(40))),
            if (guideById('peak_trough') case final guide?)
              IconButton(
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
          ],
        ),
        const SizedBox(height: 14),

        // 2. Baris Aksi Seimbang
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
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
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                  elevation: 2,
                  shadowColor: C.peony.withValues(alpha: 0.35),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InsightsPage()));
                },
                icon: const Icon(LucideIcons.activity, size: 20),
                label: Text(tr('Insights'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.lavender,
                  backgroundColor: C.midnight.withValues(alpha: 0.55),
                  side: BorderSide(
                    color: C.lavender.withValues(alpha: 0.28),
                    width: 1.1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3. Konten Utama / Empty State
        if (byH.isEmpty && simIds.isEmpty)
          Padding(
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
                      color: Pastel.mist.withValues(alpha: 0.85), fontSize: 13),
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
          )
        else ...[
          // Kurva simulasi untuk hormon aktif (dengan ringkasan lab terintegrasi)
          for (final h in simIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: LevelPanel(h, compact: true),
            ),

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
            for (final h in labOnlyHormones)
              _LevelCard(hormoneId: h, labs: byH[h]!),
          ],
        ],
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
                        style: TextStyle(
                            fontSize: 12,
                            color: Pastel.mist.withValues(alpha: 0.85)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      gap(8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(TextSpan(
                            text: '${last.prefix}${fmt(last.base / f)}',
                            style: display(36, color: Colors.white),
                            children: [
                              TextSpan(
                                  text: ' $u',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Pastel.cream.withValues(alpha: 0.88),
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
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Pastel.mist.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w500),
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
    );
  }
}
