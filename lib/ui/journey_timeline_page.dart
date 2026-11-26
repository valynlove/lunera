import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../milestones.dart';
import '../models.dart';
import '../moments.dart';
import '../repo.dart';
import '../theme.dart';
import 'responsive.dart';

enum JourneyKind { all, labs, regimen, milestones, moments }

class _JourneyItem {
  const _JourneyItem({
    required this.kind,
    required this.at,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
  });

  final JourneyKind kind;
  final DateTime at;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
}

/// Unified chronological timeline of regimens, bloodwork, milestones, and visual moments.
class JourneyTimelinePage extends ConsumerStatefulWidget {
  const JourneyTimelinePage({super.key});

  @override
  ConsumerState<JourneyTimelinePage> createState() =>
      _JourneyTimelinePageState();
}

class _JourneyTimelinePageState extends ConsumerState<JourneyTimelinePage> {
  JourneyKind _filter = JourneyKind.all;
  List<TransitionMilestone> _milestones = const [];
  bool _loadingMilestones = true;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      final list = await MilestoneStore.loadMilestones();
      if (mounted) {
        setState(() {
          _milestones = list;
          _loadingMilestones = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMilestones = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final therapies =
        ref.watch(therapiesProvider).valueOrNull ?? const <Therapy>[];
    final labs = ref.watch(labsProvider).valueOrNull ?? const <Lab>[];
    final targets =
        ref.watch(targetsProvider).valueOrNull ?? const <String, List<double>>{};
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final moments = ref.watch(momentsProvider);
    final df = DateFormat('d MMM y', L10n.code);

    final items = <_JourneyItem>[
      for (final t in therapies)
        _JourneyItem(
          kind: JourneyKind.regimen,
          at: t.start,
          title: t.name,
          subtitle:
              '${fmt(t.dose)} ${t.doseUnit} · ${routeOf(t.route).label}',
          icon: routeOf(t.route).icon,
          color: Pastel.sky,
          badge: tr('Regimen started'),
        ),
      for (final l in labs)
        _BuilderHelper.labItem(l, prefs, targets),
      for (final m in _milestones)
        _JourneyItem(
          kind: JourneyKind.milestones,
          at: m.at,
          title: m.title,
          subtitle: m.note ?? tr('Personal milestone'),
          icon: LucideIcons.sparkles,
          color: C.coral,
          badge: milestoneTagLabel(m.tag) ?? tr('Milestone'),
        ),
      for (final mo in moments)
        _JourneyItem(
          kind: JourneyKind.moments,
          at: mo.at,
          title: mo.title,
          subtitle: mo.note ?? categoryOfMoment(mo.category).name,
          icon: categoryOfMoment(mo.category).icon,
          color: C.rose,
          badge: tr('Moment'),
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    final filtered = _filter == JourneyKind.all
        ? items
        : items.where((it) => it.kind == _filter).toList();

    final comparisons = _buildLabComparisons(labs, prefs, targets);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: context.pagePadding(top: 12, bottom: 24),
          child: AdaptivePageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdaptivePageHeader(
                  title: tr('Journey Timeline'),
                  onBack: () => Navigator.pop(context),
                ),
                gap(12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in <(JourneyKind, String)>[
                      (JourneyKind.all, tr('All')),
                      (JourneyKind.labs, tr('Labs')),
                      (JourneyKind.regimen, tr('Regimen')),
                      (JourneyKind.milestones, tr('Milestones')),
                      (JourneyKind.moments, tr('Moments')),
                    ])
                      ChoiceChip(
                        label: Text(entry.$2),
                        selected: _filter == entry.$1,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _filter = entry.$1);
                        },
                      ),
                  ],
                ),
                gap(14),
                Expanded(
                  child: _loadingMilestones && items.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? SingleChildScrollView(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: AppCard(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        iconBadge(
                                            LucideIcons.compass, C.lavender,
                                            size: 48, iconSize: 22),
                                        gap(12),
                                        Text(
                                          _filter == JourneyKind.all
                                              ? tr('Your timeline is ready')
                                              : tr(
                                                  'No entries for this filter'),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        gap(6),
                                        Text(
                                          _filter == JourneyKind.all
                                              ? tr('Therapies, blood tests, milestones, and moments will appear here chronologically.')
                                              : tr('Try switching back to All to view your complete journey.'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Pastel.mist
                                                .withValues(alpha: 0.78),
                                          ),
                                        ),
                                        if (_filter != JourneyKind.all) ...[
                                          gap(12),
                                          OutlinedButton(
                                            onPressed: () => setState(() =>
                                                _filter = JourneyKind.all),
                                            child: Text(tr('Show all entries')),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length +
                                  (comparisons.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (comparisons.isNotEmpty && index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: AppCard(
                                      highlight: true,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.trendingUp,
                                                  size: 16,
                                                  color: Pastel.mint),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  tr('Earliest vs. Latest Lab Levels'),
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          gap(10),
                                          for (final c in comparisons)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      c.hormoneName,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: C.lavender,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${c.firstText} → ${c.latestText}',
                                                    style: tabular(TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: c.inRange == true
                                                          ? Pastel.mint
                                                          : Colors.white,
                                                    )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final item = filtered[
                                    comparisons.isNotEmpty ? index - 1 : index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        iconBadge(item.icon, item.color,
                                            size: 38, iconSize: 18),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    df.format(item.at),
                                                    style: tabular(const TextStyle(
                                                      fontSize: 11,
                                                      color: C.iconDefault,
                                                    )),
                                                  ),
                                                ],
                                              ),
                                              gap(3),
                                              Text(
                                                item.subtitle,
                                                style: tabular(TextStyle(
                                                  fontSize: 12.5,
                                                  color: Pastel.mist
                                                      .withValues(alpha: 0.85),
                                                )),
                                              ),
                                              if (item.badge != null) ...[
                                                gap(6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: item.color
                                                        .withValues(alpha: 0.14),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                    border: Border.all(
                                                      color: item.color
                                                          .withValues(
                                                              alpha: 0.35),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.badge!,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: item.color,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuilderHelper {
  static _JourneyItem labItem(
    Lab l,
    Prefs prefs,
    Map<String, List<double>> targets,
  ) {
    final p = presetOf(l.hormoneId);
    final u = prefs.unitOf(l.hormoneId);
    final f = p.units[u] ?? 1.0;
    final band = targets[l.hormoneId];
    String? badge;
    if (band != null && l.cmp == null) {
      badge = (l.base >= band[0] && l.base <= band[1])
          ? tr('In range')
          : (l.base < band[0] ? tr('Below target') : tr('Above target'));
    }
    return _JourneyItem(
      kind: JourneyKind.labs,
      at: l.at,
      title: '${p.name}: ${l.prefix}${fmt(l.base / f)} $u',
      subtitle: l.note?.trim().isNotEmpty == true ? l.note! : tr('Lab result'),
      icon: LucideIcons.flaskConical,
      color: hormoneColor(l.hormoneId),
      badge: badge,
    );
  }
}

class _LabComparison {
  const _LabComparison({
    required this.hormoneName,
    required this.firstText,
    required this.latestText,
    this.inRange,
  });

  final String hormoneName;
  final String firstText;
  final String latestText;
  final bool? inRange;
}

List<_LabComparison> _buildLabComparisons(
  List<Lab> labs,
  Prefs prefs,
  Map<String, List<double>> targets,
) {
  final byH = <String, List<Lab>>{};
  for (final l in labs) {
    (byH[l.hormoneId] ??= []).add(l);
  }
  final out = <_LabComparison>[];
  for (final entry in byH.entries) {
    if (entry.value.length < 2) {
      continue;
    }
    final list = [...entry.value]..sort((a, b) => a.at.compareTo(b.at));
    final first = list.first;
    final last = list.last;
    final p = presetOf(entry.key);
    final u = prefs.unitOf(entry.key);
    final f = p.units[u] ?? 1.0;
    final band = targets[entry.key];
    final inRange = (band != null && last.cmp == null)
        ? (last.base >= band[0] && last.base <= band[1])
        : null;
    out.add(
      _LabComparison(
        hormoneName: p.name,
        firstText: '${first.prefix}${fmt(first.base / f)} $u',
        latestText: '${last.prefix}${fmt(last.base / f)} $u',
        inRange: inRange,
      ),
    );
  }
  return out;
}
