part of '../levels.dart';

/// Hasil lab baru, atau ubah [initial]. "Simpan dan tambah" menyimpan lalu lanjut ke hormon berikutnya
/// dengan tanggal dan catatan yang sama, supaya satu tes darah bisa diisi berurutan.
class LabSheet extends ConsumerStatefulWidget {
  const LabSheet({super.key, this.initial});
  final Lab? initial;
  @override
  ConsumerState<LabSheet> createState() => _LabSheetState();
}

class _LabSheetState extends ConsumerState<LabSheet> {
  late var h = presetOf(widget.initial?.hormoneId ?? 'estradiol');
  late String? unit = widget.initial?.unit;
  late String? cmp = widget.initial?.cmp;
  late final value = TextEditingController(
      text: widget.initial == null ? '' : fmt(widget.initial!.value));
  late final note = TextEditingController(text: widget.initial?.note ?? '');
  late DateTime at = widget.initial?.at ?? DateTime.now();

  @override
  void dispose() {
    value.dispose();
    note.dispose();
    super.dispose();
  }

  void _save({bool again = false}) {
    final v = parseNum(value.text);
    if (v == null || !v.isFinite || v < 0) return;
    HapticFeedback.lightImpact();
    final lab = Lab(
        id: widget.initial?.id ?? '',
        hormoneId: h.id,
        at: at,
        value: v,
        unit: unit ?? h.base,
        note: note.text.trim(),
        cmp: cmp);
    final repo = ref.read(repoProvider);
    if (widget.initial != null) {
      repo?.updateLab(lab);
    } else {
      repo?.addLab(lab);
    }
    if (again && widget.initial == null) {
      final saved = h.name, i = presets.indexOf(h);
      setState(() {
        h = presets[(i + 1) % presets.length];
        unit = null;
        cmp = null;
        value.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('{0} saved. Enter the next hormone.', [saved]))));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = unit ?? h.base;
    final editing = widget.initial != null;
    final parsedVal = parseNum(value.text);
    final showEquivalents =
        parsedVal != null && parsedVal.isFinite && parsedVal > 0 && h.units.length > 1;
    final currentFactor = h.units[u] ?? 1.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(
            child: Text(editing ? tr('Edit lab result') : tr('New lab result'),
                style: display(28)),
          ),
          FilledButton.tonalIcon(
            onPressed: _save,
            icon: const Icon(LucideIcons.check, size: 16),
            label: Text(editing ? tr('Save') : tr('Save')),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      gap(16),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final p in presets)
          ChoiceChip(
            label: Text(p.name),
            selected: h == p,
            onSelected: editing
                ? null
                : (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      h = p;
                      unit = null;
                    });
                  },
          ),
      ]),
      gap(12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final (code, label) in const [
            (null, '='),
            ('<', '<'),
            ('>', '>'),
          ]) ...[
            ChoiceChip(
              label: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              selected: cmp == code,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => cmp = code);
              },
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
                controller: value,
                onChanged: (_) => setState(() {}),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(labelText: tr('Value'))),
          ),
        ],
      ),
      gap(8),
      Wrap(spacing: 8, children: [
        for (final k in h.units.keys)
          ChoiceChip(
            label: Text(k),
            selected: u == k,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              setState(() => unit = k);
            },
          ),
      ]),
      if (showEquivalents) ...[
        gap(10),
        Text(
          tr('Converted equivalents:'),
          style: TextStyle(
              fontSize: 11.5, color: Pastel.mist.withValues(alpha: 0.78)),
        ),
        gap(4),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final other in h.units.keys)
            if (other != u)
              ActionChip(
                avatar: const Icon(LucideIcons.arrowLeftRight,
                    size: 14, color: C.lavender),
                label: Text(
                    '${fmt(parsedVal * (currentFactor / (h.units[other] ?? 1.0)))} $other'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final nextVal =
                      parsedVal * (currentFactor / (h.units[other] ?? 1.0));
                  setState(() {
                    value.text = fmt(nextVal);
                    unit = other;
                  });
                },
              ),
        ]),
      ],
      gap(10),
      OutlinedButton.icon(
        onPressed: () async {
          HapticFeedback.selectionClick();
          final d = await showDatePicker(
              context: context,
              initialDate: at,
              firstDate: DateTime(2000),
              lastDate: DateTime.now());
          if (d != null) setState(() => at = d);
        },
        icon: const Icon(LucideIcons.calendar, size: 18),
        label: Text(tr('Test date: {0}', [_date(at)])),
      ),
      gap(10),
      TextField(
          controller: note,
          decoration: InputDecoration(labelText: tr('Note (optional)'))),
      gap(20),
      Row(children: [
        if (editing)
          TextButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              if (!await confirm(context, tr('Delete this lab result?')) ||
                  !context.mounted) {
                return;
              }
              ref.read(repoProvider)?.deleteLab(widget.initial!.id);
              Navigator.pop(context);
            },
            icon: const Icon(LucideIcons.trash2),
            label: Text(tr('Delete')),
          ),
        Expanded(
            child: pillButton(
                editing ? tr('Save changes') : tr('Save'), () => _save())),
      ]),
      if (!editing)
        Center(
            child: TextButton(
                onPressed: () => _save(again: true),
                child: Text(tr('Save and add another hormone')))),
    ]);
  }
}
