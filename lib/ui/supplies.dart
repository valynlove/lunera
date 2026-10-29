import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';

class SuppliesPage extends ConsumerWidget {
  const SuppliesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <Supply>[...(ref.watch(suppliesProvider).value ?? <Supply>[])]..sort((a, b) => a.name.compareTo(b.name));
    final meds = items.where((s) => !s.generic).toList();
    final gens = items.where((s) => s.generic).toList();
    Widget head(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 0, 10),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      Row(children: [
        Expanded(child: Text('Stok', style: display(40))),
        pillButton('Tambah', () => showSheet(context, const SupplySheet()), icon: Icons.add_rounded),
      ]),
      gap(18),
      if (items.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Text('Belum ada stok. Catat obat, spuit, jarum, dan perlengkapan lainnya di sini.')),
      if (meds.isNotEmpty) ...[head('Obat'), for (final s in meds) _MedCard(s)],
      if (gens.isNotEmpty) ...[gap(8), head('Perlengkapan'), for (final s in gens) _GenericCard(s)],
    ]);
  }
}

class _MedCard extends ConsumerWidget {
  const _MedCard(this.s);
  final Supply s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expired = s.expiry != null && s.expiry!.isBefore(DateTime.now());
    final low = s.low;
    final color = expired ? C.peony : (low ? C.amber : C.lagoon);
    final repo = ref.read(repoProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => showSheet(context, SupplySheet(initial: s)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(s.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                IconButton.filledTonal(onPressed: () => repo?.adjustSupply(s.id, -1), icon: const Icon(Icons.remove_rounded)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${fmt(s.qty)} ${s.unitLabel}', style: display(20))),
                IconButton.filledTonal(onPressed: () => repo?.adjustSupply(s.id, 1), icon: const Icon(Icons.add_rounded)),
              ]),
              gap(14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: s.initial <= 0 ? 0 : (s.qty / s.initial).clamp(0.0, 1.0),
                  minHeight: 10,
                  color: color,
                  backgroundColor: color.withValues(alpha: .18),
                ),
              ),
              gap(10),
              Text(low ? '${s.doses} dosis tersisa, segera isi ulang' : '${s.doses} dosis tersisa'),
              if (s.expiry != null)
                Text('${expired ? 'Kedaluwarsa sejak' : 'Kedaluwarsa'} ${DateFormat('d MMM y', 'id').format(s.expiry!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: expired ? C.peony : null)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GenericCard extends ConsumerWidget {
  const _GenericCard(this.s);
  final Supply s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final low = s.low;
    final repo = ref.read(repoProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => showSheet(context, SupplySheet(initial: s)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
            child: Row(children: [
              Icon(genericTypes[s.gtype]?.$2 ?? Icons.inventory_2_rounded, color: low ? C.amber : C.lagoon),
              const SizedBox(width: 14),
              Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700))),
              IconButton.filledTonal(onPressed: () => repo?.adjustSupply(s.id, -1), icon: const Icon(Icons.remove_rounded)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(fmt(s.qty), style: display(20, color: low ? C.amber : null))),
              IconButton.filledTonal(onPressed: () => repo?.adjustSupply(s.id, 1), icon: const Icon(Icons.add_rounded)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Stok baru, atau ubah [initial].
class SupplySheet extends ConsumerStatefulWidget {
  const SupplySheet({super.key, this.initial});
  final Supply? initial;
  @override
  ConsumerState<SupplySheet> createState() => _SupplySheetState();
}

class _SupplySheetState extends ConsumerState<SupplySheet> {
  late bool generic = widget.initial?.generic ?? false;
  late String gtype = widget.initial?.gtype ?? 'syringe';
  late final name = TextEditingController(text: widget.initial?.name ?? '');
  late final qty = TextEditingController(text: widget.initial == null ? '' : fmt(widget.initial!.qty));
  late final per = TextEditingController(text: fmt(widget.initial?.perDose ?? 1));
  late final label = TextEditingController(text: widget.initial?.unitLabel ?? 'vial');
  late final dpu = TextEditingController(text: widget.initial?.dosePerUnit == null ? '' : fmt(widget.initial!.dosePerUnit!));
  late DateTime? expiry = widget.initial?.expiry;

  void _save() {
    final q = parseNum(qty.text);
    if (q == null || q < 0) return;
    final repo = ref.read(repoProvider);
    final old = widget.initial;
    Supply s;
    if (generic) {
      final typed = name.text.trim();
      s = Supply(
        id: old?.id ?? '',
        name: typed.isEmpty ? genericTypes[gtype]!.$1 : typed,
        qty: q,
        initial: old == null ? q : (q > old.initial ? q : old.initial),
        kind: 'generic',
        gtype: gtype,
      );
    } else {
      final p = parseNum(per.text);
      if (name.text.trim().isEmpty || p == null || p <= 0) return;
      s = Supply(
        id: old?.id ?? '',
        name: name.text.trim(),
        qty: q,
        initial: old == null ? q : (q > old.initial ? q : old.initial),
        perDose: p,
        unitLabel: label.text.trim().isEmpty ? 'buah' : label.text.trim(),
        expiry: expiry,
        dosePerUnit: parseNum(dpu.text),
      );
    }
    if (old == null) {
      repo?.addSupply(s);
    } else {
      repo?.updateSupply(s);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Hapus stok ini?') || !mounted) return;
    ref.read(repoProvider)?.deleteSupply(widget.initial!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? 'Ubah stok' : 'Stok baru', style: display(28)),
      gap(16),
      if (!editing)
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Obat'), selected: !generic, onSelected: (_) => setState(() => generic = false)),
          ChoiceChip(label: const Text('Perlengkapan'), selected: generic, onSelected: (_) => setState(() => generic = true)),
        ]),
      gap(12),
      if (generic) ...[
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in genericTypes.entries)
            ChoiceChip(avatar: Icon(e.value.$2, size: 16), label: Text(e.value.$1), selected: gtype == e.key, onSelected: (_) => setState(() => gtype = e.key)),
        ]),
        gap(10),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama (opsional)')),
        gap(10),
        TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Jumlah')),
      ] else ...[
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama (mis. Estradiol valerat 40 mg/mL)')),
        gap(10),
        Row(children: [
          Expanded(child: TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Jumlah'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: label, decoration: const InputDecoration(labelText: 'Satuan (vial, mL, pil)'))),
        ]),
        gap(10),
        TextField(controller: per, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Terpakai per dosis (satuan di atas)')),
        gap(10),
        TextField(
          controller: dpu,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Kadar: mg per satuan (opsional)', helperText: 'Mis. 40 untuk 40 mg/mL. Jika diisi, pemakaian dihitung dari dosis (mg).'),
        ),
        gap(10),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: expiry ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
            if (d != null) setState(() => expiry = d);
          },
          icon: const Icon(Icons.event_rounded, size: 18),
          label: Text(expiry == null ? 'Tanggal kedaluwarsa (opsional)' : DateFormat('d MMM y', 'id').format(expiry!)),
        ),
      ],
      gap(20),
      Row(children: [
        if (editing) TextButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Hapus')),
        Expanded(child: pillButton(editing ? 'Simpan perubahan' : 'Simpan stok', _save)),
      ]),
    ]);
  }
}
