import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cycle_insights.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';

/// Compact clinical/pharmacy summary card with editable allergy & clinic notes and 1-tap copy.
class CareCardSheet extends ConsumerStatefulWidget {
  const CareCardSheet({super.key});

  @override
  ConsumerState<CareCardSheet> createState() => _CareCardSheetState();
}

class _CareCardSheetState extends ConsumerState<CareCardSheet> {
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _clinicCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _allergiesCtrl = TextEditingController();
    _clinicCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _clinicCtrl.dispose();
    super.dispose();
  }

  void _syncOnce(Prefs prefs) {
    if (_initialized) {
      return;
    }
    _allergiesCtrl.text = prefs.careAllergies;
    _clinicCtrl.text = prefs.careClinicInfo;
    _initialized = true;
  }

  Future<void> _saveNotes() async {
    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    await ref.read(repoProvider)?.setPrefs(
          prefs.copy(
            careAllergies: _allergiesCtrl.text.trim(),
            careClinicInfo: _clinicCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final therapies =
        ref.watch(therapiesProvider).valueOrNull ?? const <Therapy>[];
    final labs = ref.watch(labsProvider).valueOrNull ?? const <Lab>[];
    final targets =
        ref.watch(targetsProvider).valueOrNull ?? const <String, List<double>>{};
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    _syncOnce(prefs);

    final latestByH = <String, Lab>{};
    final sortedLabs = [...labs]..sort((a, b) => b.at.compareTo(a.at));
    for (final l in sortedLabs) {
      latestByH.putIfAbsent(l.hormoneId, () => l);
    }
    final df = DateFormat('d MMM y', L10n.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            iconBadge(LucideIcons.heartPulse, C.rose),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Quick Clinic Care Card'),
                    style: display(24, color: Colors.white),
                  ),
                  Text(
                    tr('Fast summary for clinic visits, labs, or pharmacy refills.'),
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
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Active Regimen'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.lavender),
              ),
              gap(6),
              if (therapies.isEmpty)
                Text(
                  tr('No active therapies added yet.'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Pastel.mist.withValues(alpha: 0.75),
                  ),
                )
              else
                for (final t in therapies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${t.name} — ${fmt(t.dose)} ${t.doseUnit} (${routeOf(t.route).label}, ${scheduleText(t)})',
                      style: tabular(const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white,
                        height: 1.35,
                      )),
                    ),
                  ),
              gap(10),
              Text(
                tr('Latest Lab Results'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.lavender),
              ),
              gap(6),
              if (latestByH.isEmpty)
                Text(
                  tr('No lab results recorded'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Pastel.mist.withValues(alpha: 0.75),
                  ),
                )
              else
                for (final entry in latestByH.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Builder(builder: (_) {
                      final p = presetOf(entry.key);
                      final l = entry.value;
                      final u = prefs.unitOf(entry.key);
                      final f = p.units[u] ?? 1.0;
                      return Text(
                        '• ${p.name}: ${l.prefix}${fmt(l.base / f)} $u (${df.format(l.at)})',
                        style: tabular(const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white,
                        )),
                      );
                    }),
                  ),
            ],
          ),
        ),
        gap(12),
        TextField(
          controller: _allergiesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: tr('Allergies & Sensitivities'),
            hintText: tr('e.g. Sesame oil sensitivity, latex-free...'),
          ),
        ),
        gap(10),
        TextField(
          controller: _clinicCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: tr('Clinic & Pharmacy'),
            hintText: tr('Doctor name, clinic phone, or preferred pharmacy...'),
          ),
        ),
        gap(16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await _saveNotes();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('Care card notes saved.'))),
                  );
                },
                icon: const Icon(LucideIcons.check, size: 17),
                label: Text(tr('Save Notes')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: pillButton(
                tr('Copy Clinic Summary'),
                () async {
                  HapticFeedback.lightImpact();
                  await _saveNotes();
                  final summary = formatQuickCareCard(
                    therapies: therapies,
                    labs: labs,
                    targets: targets,
                    prefs: prefs.copy(
                      careAllergies: _allergiesCtrl.text.trim(),
                      careClinicInfo: _clinicCtrl.text.trim(),
                    ),
                  );
                  await Clipboard.setData(ClipboardData(text: summary));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(tr('Care card summary copied to clipboard.'))),
                  );
                },
                icon: LucideIcons.copy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
