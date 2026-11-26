import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../sanctuary_data.dart';
import '../schedule.dart';
import '../theme.dart';
import '../widget_sync.dart';
import 'companion_avatar.dart';

/// 60-second gentle daily check-in flow combining mood, hydration, and 3 calm breaths.
class DailyCheckInSheet extends ConsumerStatefulWidget {
  const DailyCheckInSheet({super.key});

  @override
  ConsumerState<DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

class _DailyCheckInSheetState extends ConsumerState<DailyCheckInSheet> {
  int _step = 0; // 0: mood & symptoms, 1: hydration & dose check, 2: 3 breaths
  String? _mood;
  final Set<String> _symptoms = <String>{};
  int _waterCups = 0;
  int _breathsDone = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  Future<void> _loadWater() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final cups = sp.getString('cmp_hydration_date') == todayStr
          ? (sp.getInt('cmp_hydration_cups') ?? 0)
          : 0;
      if (mounted) {
        setState(() => _waterCups = cups);
      }
    } catch (_) {}
  }

  Future<void> _addWaterCup() async {
    HapticFeedback.lightImpact();
    final next = _waterCups + 1;
    setState(() => _waterCups = next);
    try {
      final sp = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await sp.setString('cmp_hydration_date', todayStr);
      await sp.setInt('cmp_hydration_cups', next);
      final pats = sp.getInt('cmp_pats_count') ?? 0;
      await WidgetSync.syncCompanionStats(pats: pats, waterCups: next);
    } catch (_) {}
  }

  Future<void> _completeRitual() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    if (_mood != null || _symptoms.isNotEmpty) {
      final entry = JournalEntry(
        id: '',
        at: DateTime.now(),
        mood: _mood,
        symptoms: _symptoms.toList(),
      );
      ref.read(repoProvider)?.addJournal(entry);
    }

    try {
      final sp = await SharedPreferences.getInstance();
      final nextPats = (sp.getInt('cmp_pats_count') ?? 0) + 2;
      await sp.setInt('cmp_pats_count', nextPats);
      await SanctuaryStore.lightTodaySpark();
      await WidgetSync.syncCompanionStats(
        pats: nextPats,
        waterCups: _waterCups,
      );
    } catch (_) {}

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('Daily check-in complete ✨ Bond +2 with your companion.'),
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ths = ref.watch(therapiesProvider).valueOrNull ?? const <Therapy>[];
    final logs = ref.watch(logsProvider).valueOrNull ?? const <DoseLog>[];
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final today = logicalToday(prefs);
    final pendingToday = [
      for (final s in buildSlots(ths, logs, prefs, back: 1, ahead: 1))
        if (s.pending && sameDay(s.at, today)) s,
    ];

    final quickSymptoms = symptomPresets.entries.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const CompanionAvatar(
              mood: CompanionMood.care,
              size: 54,
              glowColor: C.lavender,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('60-Second Daily Ritual'),
                    style: display(24, color: Colors.white),
                  ),
                  Text(
                    tr('Step {0} of 3', [_step + 1]),
                    style: tabular(const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: C.lavender,
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
        gap(12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3.0,
            minHeight: 5,
            backgroundColor: C.midnight,
            valueColor: const AlwaysStoppedAnimation<Color>(Pastel.mint),
          ),
        ),
        gap(16),
        if (_step == 0) ...[
          Text(
            tr('How does your body and mind feel right now?'),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in moods.entries)
                ChoiceChip(
                  avatar: Icon(m.value.$2, size: 16),
                  label: Text(tr(m.value.$1)),
                  selected: _mood == m.key,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _mood = _mood == m.key ? null : m.key);
                  },
                ),
            ],
          ),
          gap(14),
          Text(
            tr('Anything to note quietly? (optional)'),
            style: TextStyle(
              fontSize: 12.5,
              color: Pastel.mist.withValues(alpha: 0.8),
            ),
          ),
          gap(8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final sym in quickSymptoms)
                FilterChip(
                  avatar: Icon(sym.value.$2, size: 14),
                  label: Text(tr(sym.value.$1),
                      style: const TextStyle(fontSize: 11.5)),
                  selected: _symptoms.contains(sym.key),
                  onSelected: (sel) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (sel) {
                        _symptoms.add(sym.key);
                      } else {
                        _symptoms.remove(sym.key);
                      }
                    });
                  },
                ),
            ],
          ),
        ] else if (_step == 1) ...[
          Text(
            tr('Hydration & today\'s rhythm'),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          gap(10),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                iconBadge(LucideIcons.droplet, Pastel.sky,
                    size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Water today: {0} / 8', [_waterCups]),
                        style: tabular(const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        tr('Even one small sip supports circulation and comfort.'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Pastel.mist.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _addWaterCup,
                  child: const Text('+1'),
                ),
              ],
            ),
          ),
          gap(10),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                iconBadge(
                  pendingToday.isEmpty ? LucideIcons.check : LucideIcons.pill,
                  pendingToday.isEmpty ? Pastel.mint : C.coral,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pendingToday.isEmpty
                        ? tr('All scheduled doses for today are handled.')
                        : tr('{0} {0?dose|doses} still pending today.',
                            [pendingToday.length]),
                    style: tabular(const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            tr('Take 3 gentle breaths to close'),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          gap(8),
          Text(
            tr('Drop your shoulders, unclench your jaw, and tap each star as you exhale slowly.'),
            style: TextStyle(
              fontSize: 12.5,
              color: Pastel.mist.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
          gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Semantics(
                  button: true,
                  label: tr('Breath {0}', [i + 1]),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (_breathsDone < i + 1) {
                          _breathsDone = i + 1;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _breathsDone
                            ? Pastel.mint.withValues(alpha: 0.20)
                            : C.midnight,
                        border: Border.all(
                          color: i < _breathsDone
                              ? Pastel.mint
                              : C.lavender.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        i < _breathsDone
                            ? LucideIcons.check
                            : LucideIcons.wind,
                        color: i < _breathsDone ? Pastel.mint : C.lavender,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          gap(14),
          Center(
            child: Text(
              _breathsDone >= 3
                  ? tr('You are safe here. Take today at your own pace ✨')
                  : tr('{0} / 3 breaths', [_breathsDone]),
              textAlign: TextAlign.center,
              style: tabular(TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _breathsDone >= 3 ? Pastel.mint : C.lavender,
              )),
            ),
          ),
        ],
        gap(20),
        Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _step--);
                  },
                  child: Text(tr('Back')),
                ),
              ),
            if (_step > 0) const SizedBox(width: 10),
            Expanded(
              child: pillButton(
                _step < 2 ? tr('Next') : tr('Complete Ritual'),
                _step < 2
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _step++);
                      }
                    : _completeRitual,
                icon: _step < 2 ? LucideIcons.chevronRight : LucideIcons.sparkles,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
