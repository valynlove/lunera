import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import '../travel_shift.dart';

const List<double> _utcOffsets = [
  -11.0,
  -10.0,
  -9.0,
  -8.0,
  -7.0,
  -6.0,
  -5.0,
  -4.0,
  -3.0,
  -2.0,
  -1.0,
  0.0,
  1.0,
  2.0,
  3.0,
  3.5,
  4.0,
  5.0,
  5.5,
  6.0,
  7.0,
  8.0,
  9.0,
  9.5,
  10.0,
  11.0,
  12.0,
];

/// Offline calculator for gradually shifting hormone dose times across time zones.
class TravelShiftSheet extends ConsumerStatefulWidget {
  const TravelShiftSheet({super.key});

  @override
  ConsumerState<TravelShiftSheet> createState() => _TravelShiftSheetState();
}

class _TravelShiftSheetState extends ConsumerState<TravelShiftSheet> {
  String? _selectedTherapyId;
  String _customTime = '08:00';
  late double _originOffset;
  double _destOffset = 9.0;
  double _maxShiftHours = 2.0;
  DateTime _departureDate = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    final localHours = DateTime.now().timeZoneOffset.inMinutes / 60.0;
    _originOffset = _utcOffsets.reduce((a, b) =>
        (a - localHours).abs() <= (b - localHours).abs() ? a : b);
    if ((_originOffset - _destOffset).abs() < 0.1) {
      _destOffset = _originOffset >= 0 ? 0.0 : 7.0;
    }
  }

  Future<void> _pickCustomTime() async {
    final parts = _customTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _customTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _departureDate = DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final therapies = (ref.watch(therapiesProvider).valueOrNull ?? <Therapy>[])
        .where((t) => !t.asNeeded && t.times.isNotEmpty)
        .toList();
    final selectedTherapy =
        therapies.where((t) => t.id == _selectedTherapyId).firstOrNull ??
            therapies.firstOrNull;
    final baseTime =
        selectedTherapy != null ? selectedTherapy.times.first : _customTime;
    final intervalDays =
        selectedTherapy != null && !selectedTherapy.daily ? cycleOf(selectedTherapy) : 1;

    final steps = computeTimezoneShiftPlan(
      baseTimeHHmm: baseTime,
      originUtcOffsetHours: _originOffset,
      destUtcOffsetHours: _destOffset,
      departureDate: _departureDate,
      maxShiftHoursPerDay: _maxShiftHours,
      intervalDays: intervalDays,
    );

    final df = DateFormat('EEE, d MMM', L10n.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            iconBadge(LucideIcons.globe, Pastel.sky),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Travel & Timezone Helper'),
                    style: display(24, color: Colors.white),
                  ),
                  Text(
                    tr('Shift dose times gradually across time zones without drops or overlap.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Pastel.mist.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        gap(16),
        if (therapies.isNotEmpty) ...[
          Text(
            tr('Therapy'),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: C.lavender),
          ),
          gap(6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final t in therapies)
                ChoiceChip(
                  label: Text('${t.name} (${t.times.first})',
                      style: tabular(const TextStyle(fontSize: 12))),
                  selected: selectedTherapy?.id == t.id,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTherapyId = t.id);
                  },
                ),
            ],
          ),
        ] else
          OutlinedButton.icon(
            onPressed: _pickCustomTime,
            icon: const Icon(LucideIcons.clockAlert, size: 17),
            label: Text(
              tr('Usual dose time: {0}', [_customTime]),
              style: tabular(const TextStyle()),
            ),
          ),
        gap(14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<double>(
                initialValue: _originOffset,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('Origin zone')),
                items: [
                  for (final off in _utcOffsets)
                    DropdownMenuItem(
                      value: off,
                      child: Text(formatUtcOffset(off),
                          style: tabular(const TextStyle(fontSize: 13))),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _originOffset = v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<double>(
                initialValue: _destOffset,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('Destination zone')),
                items: [
                  for (final off in _utcOffsets)
                    DropdownMenuItem(
                      value: off,
                      child: Text(formatUtcOffset(off),
                          style: tabular(const TextStyle(fontSize: 13))),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _destOffset = v);
                },
              ),
            ),
          ],
        ),
        gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDepartureDate,
              icon: const Icon(LucideIcons.calendarDays, size: 16),
              label: Text(
                tr('Arrival: {0}', [df.format(_departureDate)]),
                style: tabular(const TextStyle(fontSize: 12)),
              ),
            ),
            for (final pace in const [1.0, 2.0, 3.0])
              ChoiceChip(
                label: Text(
                  tr('{0}h / step', [pace.round()]),
                  style: tabular(const TextStyle(fontSize: 12)),
                ),
                selected: _maxShiftHours == pace,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _maxShiftHours = pace);
                },
              ),
          ],
        ),
        gap(16),
        Text(
          tr('Suggested Transition Plan'),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: C.lavender),
        ),
        gap(8),
        for (final step in steps)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: C.midnight.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: step.remainingShiftMinutes == 0
                    ? Pastel.mint.withValues(alpha: 0.4)
                    : C.lavender.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (step.remainingShiftMinutes == 0
                            ? Pastel.mint
                            : C.aurora)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    step.timeHHmm,
                    style: tabular(TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: step.remainingShiftMinutes == 0
                          ? Pastel.mint
                          : Colors.white,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        df.format(step.date),
                        style: tabular(const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                      ),
                      Text(
                        step.note,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Pastel.mist.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        gap(10),
        pillButton(
          tr('Copy Transition Plan'),
          () {
            HapticFeedback.lightImpact();
            final lines = [
              'Lunera — ${tr('Travel & Timezone Helper')}',
              if (selectedTherapy != null) selectedTherapy.name,
              '${formatUtcOffset(_originOffset)} → ${formatUtcOffset(_destOffset)}',
              '',
              for (final s in steps)
                '${df.format(s.date)} • ${s.timeHHmm} — ${s.note}',
            ].join('\n');
            Clipboard.setData(ClipboardData(text: lines));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('Transition plan copied to clipboard.'))),
            );
          },
          icon: LucideIcons.copy,
        ),
      ],
    );
  }
}
