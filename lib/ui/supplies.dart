import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import '../l10n.dart';
import 'pickup_assistant_sheet.dart';
import 'responsive.dart';

class SuppliesPage extends ConsumerWidget {
  const SuppliesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <Supply>[...(ref.watch(suppliesProvider).value ?? <Supply>[])]
      ..sort((a, b) => a.name.compareTo(b.name));
    final ths = items.isEmpty
        ? const <Therapy>[]
        : (ref.watch(therapiesProvider).valueOrNull ?? const <Therapy>[]);
    final meds = items.where((s) => !s.generic).toList();
    final gens = items.where((s) => s.generic).toList();
    final lowCount = items.where((s) => s.low).length;

    final forecasts = {for (final s in items) s.id: estimateSupplyForecast(s, ths)};
    final criticalCount = forecasts.values.where((f) => f != null && (f.urgency == RefillUrgency.critical || f.urgency == RefillUrgency.depleted)).length;
    final reorderSoonCount = forecasts.values.where((f) => f != null && f.urgency == RefillUrgency.reorderSoon).length;

    final bannerColor = criticalCount > 0
        ? C.coral
        : (reorderSoonCount > 0 || lowCount > 0 ? C.amber : C.peony);
    final bannerIcon = criticalCount > 0
        ? LucideIcons.alertTriangle
        : (reorderSoonCount > 0
            ? LucideIcons.truck
            : (lowCount > 0 ? LucideIcons.package : LucideIcons.truck));
    final bannerTitle = criticalCount > 0
        ? tr('{0} {0?item needs|items need} urgent reorder', [criticalCount])
        : (reorderSoonCount > 0
            ? tr('Refill window approaching for {0} {0?item|items}', [reorderSoonCount])
            : (lowCount > 0
                ? tr('{0} {0?item is|items are} running low', [lowCount])
                : tr('Discreet Shipping & Pickup Assistant')));
    final bannerSubtitle = criticalCount > 0
        ? tr('Stock is under 7 days. Plan your reorder now to prevent gaps in therapy.')
        : (reorderSoonCount > 0
            ? tr('Recommended reorder date approaching within the next 7–14 days.')
            : (lowCount > 0
                ? tr('Generate a discreet "Hold at Agent" delivery order template.')
                : tr('Generate "Hold at Agent" delivery templates to prevent packages arriving at family home.')));
    Widget head(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 0, 10),
        child: Text(s,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)));
    final isWide = context.isWide;
    final addSupplyBtn = FilledButton.icon(
      onPressed: () => showSheet(context, const SupplySheet()),
      icon: const Icon(LucideIcons.plus, size: 20),
      label: Text(tr('Add Supply'),
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
    final pickupBtn = OutlinedButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PickupAssistantSheet(),
      ),
      icon: const Icon(LucideIcons.truck, size: 20),
      label: Text(tr('Pickup Assistant'),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: C.lavender,
        backgroundColor: C.midnight.withValues(alpha: 0.55),
        side: BorderSide(
          color: C.lavender.withValues(alpha: 0.28),
          width: 1.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
    );

    return ListView(
      padding: context.pagePadding(top: 12, bottom: 32),
      children: [
        AdaptivePageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(tr('Supplies'),
                          style: display(isWide ? 36 : 40)),
                    ),
                  ),
                  if (isWide) ...[
                    pickupBtn,
                    const SizedBox(width: 10),
                    addSupplyBtn,
                  ],
                ],
              ),
              if (!isWide) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: addSupplyBtn),
                    const SizedBox(width: 10),
                    Expanded(child: pickupBtn),
                  ],
                ),
              ],
              gap(18),
              if (items.isEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(tr(
                        'No supplies yet. Track medication, syringes, needles, and other supplies here.')))
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: bannerColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bannerIcon,
                        color: bannerColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bannerTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bannerSubtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const PickupAssistantSheet(),
                        ),
                        child: Text(tr('Open')),
                      ),
                    ],
                  ),
                ),
              if (meds.isNotEmpty) ...[
                head(tr('Medication')),
                AdaptiveGrid(
                  compactColumns: 1,
                  mediumColumns: 2,
                  expandedColumns: 2,
                  minColumnWidth: 320,
                  children: [for (final s in meds) _MedCard(s)],
                ),
              ],
              if (gens.isNotEmpty) ...[
                gap(14),
                head(tr('Equipment')),
                AdaptiveGrid(
                  compactColumns: 1,
                  mediumColumns: 2,
                  expandedColumns: 2,
                  minColumnWidth: 320,
                  children: [for (final s in gens) _GenericCard(s)],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Widget _forecastChip(BuildContext context, SupplyForecast f) {
  final (color, icon, text) = switch (f.urgency) {
    RefillUrgency.depleted => (
      C.peony,
      LucideIcons.circleAlert,
      tr('Depleted • Reorder immediately'),
    ),
    RefillUrgency.critical => (
      C.coral,
      LucideIcons.alertTriangle,
      tr('Order now • Depletes on {0}',
          [DateFormat('d MMM', L10n.code).format(f.runOutDate)]),
    ),
    RefillUrgency.reorderSoon => (
      C.amber,
      LucideIcons.truck,
      tr('Reorder by {0} ({1}-day buffer)', [
        DateFormat('d MMM', L10n.code).format(f.reorderDate),
        f.bufferDays,
      ]),
    ),
    RefillUrgency.healthy => (
      C.lagoon,
      LucideIcons.calendarCheck,
      f.daysLeft >= 14
          ? tr('Est. ~{0} {0?week|weeks} left (until {1})', [
              (f.daysLeft / 7).round(),
              DateFormat('d MMM y', L10n.code).format(f.runOutDate),
            ])
          : tr('Est. ~{0} {0?day|days} left (until {1})', [
              f.daysLeft,
              DateFormat('d MMM y', L10n.code).format(f.runOutDate),
            ]),
    ),
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.5, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
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
    final ths = ref.watch(therapiesProvider).value ?? const <Therapy>[];
    final forecast = estimateSupplyForecast(s, ths);
    return Container(
      decoration: cardBox(context, radius: R.card),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(R.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.card),
          onTap: () => showSheet(context, SupplySheet(initial: s)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(s.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
                IconButton.filledTonal(
                    tooltip: tr('Decrease quantity'),
                    onPressed: () => repo?.adjustSupply(s.id, -1),
                    icon: const Icon(LucideIcons.minus)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${fmt(s.qty)} ${s.unitLabel}',
                        style: tabular(display(20)))),
                IconButton.filledTonal(
                    tooltip: tr('Increase quantity'),
                    onPressed: () => repo?.adjustSupply(s.id, 1),
                    icon: const Icon(LucideIcons.plus)),
              ]),
              gap(14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value:
                      s.initial <= 0 ? 0 : (s.qty / s.initial).clamp(0.0, 1.0),
                  minHeight: 10,
                  color: color,
                  backgroundColor: color.withValues(alpha: .18),
                ),
              ),
              gap(10),
              Text(
                low
                    ? tr('{0} {0?dose|doses} left, restock soon', [s.doses])
                    : tr('{0} {0?dose|doses} left', [s.doses]),
                style: tabular(const TextStyle()),
              ),
              if (forecast != null) ...[
                gap(6),
                _forecastChip(context, forecast),
              ],
              if (s.expiry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      tr(expired ? 'Expired since {0}' : 'Expires {0}',
                          [DateFormat('d MMM y', L10n.code).format(s.expiry!)]),
                      style: tabular(Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: expired ? C.peony : null) ??
                          const TextStyle())),
                ),
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
    final ths = ref.watch(therapiesProvider).value ?? const <Therapy>[];
    final forecast = estimateSupplyForecast(s, ths);
    return Container(
      decoration: cardBox(context, radius: R.card),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(R.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.card),
          onTap: () => showSheet(context, SupplySheet(initial: s)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            child: Row(children: [
              Icon(genericTypes[s.gtype]?.$2 ?? LucideIcons.package,
                  color: low ? C.amber : C.lagoon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (forecast != null) ...[
                      const SizedBox(height: 4),
                      _forecastChip(context, forecast),
                    ],
                  ],
                ),
              ),
              IconButton.filledTonal(
                  tooltip: tr('Decrease quantity'),
                  onPressed: () => repo?.adjustSupply(s.id, -1),
                  icon: const Icon(LucideIcons.minus)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(fmt(s.qty),
                      style: tabular(display(20, color: low ? C.amber : null)))),
              IconButton.filledTonal(
                  tooltip: tr('Increase quantity'),
                  onPressed: () => repo?.adjustSupply(s.id, 1),
                  icon: const Icon(LucideIcons.plus)),
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
  late final qty = TextEditingController(
      text: widget.initial == null ? '' : fmt(widget.initial!.qty));
  late final per =
      TextEditingController(text: fmt(widget.initial?.perDose ?? 1));
  late final label =
      TextEditingController(text: widget.initial?.unitLabel ?? 'vial');
  late final dpu = TextEditingController(
      text: widget.initial?.dosePerUnit == null
          ? ''
          : fmt(widget.initial!.dosePerUnit!));
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
        name: typed.isEmpty ? tr(genericTypes[gtype]!.$1) : typed,
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
    if (!await confirm(context, tr('Delete this supply?')) || !mounted) return;
    ref.read(repoProvider)?.deleteSupply(widget.initial!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(editing ? tr('Edit supply') : tr('New supply'), style: display(28)),
      gap(16),
      if (!editing)
        Wrap(spacing: 8, children: [
          ChoiceChip(
              label: Text(tr('Medication')),
              selected: !generic,
              onSelected: (_) => setState(() => generic = false)),
          ChoiceChip(
              label: Text(tr('Equipment')),
              selected: generic,
              onSelected: (_) => setState(() => generic = true)),
        ]),
      gap(12),
      if (generic) ...[
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in genericTypes.entries)
            ChoiceChip(
                avatar: Icon(e.value.$2, size: 16),
                label: Text(tr(e.value.$1)),
                selected: gtype == e.key,
                onSelected: (_) => setState(() => gtype = e.key)),
        ]),
        gap(10),
        TextField(
            controller: name,
            decoration: InputDecoration(labelText: tr('Name (optional)'))),
        gap(10),
        TextField(
            controller: qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: tr('Quantity'))),
      ] else ...[
        TextField(
            controller: name,
            decoration: InputDecoration(
                labelText: tr('Name (e.g. Estradiol valerate 40 mg/mL)'))),
        gap(10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: tr('Quantity')))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: label,
                  decoration:
                      InputDecoration(labelText: tr('Unit (vial, mL, pill)')))),
        ]),
        gap(10),
        TextField(
            controller: per,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(labelText: tr('Used per dose (unit above)'))),
        gap(10),
        TextField(
          controller: dpu,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: tr('Strength: mg per unit (optional)'),
              helperText: tr(
                  'E.g. 40 for 40 mg/mL. If filled in, usage is calculated from the dose (mg).')),
        ),
        gap(10),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: expiry ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100));
            if (d != null) setState(() => expiry = d);
          },
          icon: const Icon(LucideIcons.calendarDays, size: 18),
          label: Text(expiry == null
              ? tr('Expiry date (optional)')
              : DateFormat('d MMM y', L10n.code).format(expiry!)),
        ),
      ],
      gap(20),
      Row(children: [
        if (editing)
          TextButton.icon(
              onPressed: _delete,
              icon: const Icon(LucideIcons.trash2),
              label: Text(tr('Delete'))),
        Expanded(
            child: pillButton(
                editing ? tr('Save changes') : tr('Save supply'), _save)),
      ]),
    ]);
  }
}
