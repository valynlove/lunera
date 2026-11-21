part of '../levels.dart';

class HormonePage extends ConsumerWidget {
  const HormonePage(this.hormoneId, {super.key});
  final String hormoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = presetOf(hormoneId);
    final labs = (ref.watch(labsProvider).value ?? <Lab>[])
        .where((l) => l.hormoneId == hormoneId)
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final band = ref.watch(targetsProvider).value?[hormoneId];
    final u =
        (ref.watch(prefsProvider).value ?? const Prefs()).unitOf(hormoneId);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.arrowLeft),
            ),
            Expanded(child: Text(p.name, style: display(32))),
            IconButton.filledTonal(
              tooltip: tr('Set target'),
              onPressed: () {
                HapticFeedback.lightImpact();
                _target(context, ref, p, u, band);
              },
              icon: const Icon(LucideIcons.flag),
            ),
          ]),
          gap(8),
          Text(
              tr('Chart in {0} (change in Settings). The green area is the target you set with your doctor.',
                  [u]),
              style: Theme.of(context).textTheme.bodySmall),
          gap(16),
          LevelPanel(hormoneId),
          gap(20),
          if (labs.isNotEmpty) ...[
            Text(tr('Lab Results History'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            gap(10),
            Container(
              decoration: cardBox(context, radius: 20),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: labs.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: Colors.white.withValues(alpha: 0.08)),
                itemBuilder: (context, i) {
                  final l = labs[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showSheet(context, LabSheet(initial: l));
                    },
                    title: Text('${l.prefix}${fmt(l.value)} ${l.unit}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white)),
                    subtitle: Text(
                      _date(l.at) +
                          (l.note == null || l.note!.isEmpty
                              ? ''
                              : '\n${l.note}'),
                      style: TextStyle(
                          color: Pastel.mist.withValues(alpha: 0.85),
                          fontSize: 12),
                    ),
                    trailing: const Icon(LucideIcons.pencil,
                        size: 18, color: Pastel.lilac),
                  );
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _target(BuildContext c, WidgetRef ref, HormonePreset p, String u,
      List<double>? band) async {
    final f = p.units[u] ?? 1.0;
    final lo =
        TextEditingController(text: band == null ? '' : fmt(band[0] / f));
    final hi =
        TextEditingController(text: band == null ? '' : fmt(band[1] / f));
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: Text(tr('{0} target ({1})', [p.name, u])),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: lo,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: tr('Lower limit'))),
          gap(8),
          TextField(
              controller: hi,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: tr('Upper limit'))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(tr('Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(tr('Save target'))),
        ],
      ),
    );
    final a = parseNum(lo.text), b = parseNum(hi.text);
    if (ok == true && a != null && b != null) {
      ref
          .read(repoProvider)
          ?.setTarget(p.id, math.min(a, b) * f, math.max(a, b) * f);
    }
  }
}
