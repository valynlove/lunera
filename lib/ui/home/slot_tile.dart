import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../schedule.dart';
import '../../theme.dart';
import '../sheets.dart';
import 'dose_card.dart';

class SlotTile extends ConsumerWidget {
  const SlotTile(
      {super.key,
      required this.s,
      required this.logs,
      required this.supplies,
      required this.prefs});
  final Slot s;
  final List<DoseLog> logs;
  final List<Supply> supplies;
  final Prefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = s.t, fg = Theme.of(context).colorScheme.onSurface;
    final late = s.status == 'overdue' || s.status == 'late';
    final label = sameDay(s.at, logicalToday(prefs))
        ? DateFormat('HH:mm').format(s.at)
        : DateFormat('EEE d MMM, HH:mm', L10n.code).format(s.at);
    void open() {
      HapticFeedback.lightImpact();
      showSheet(
        context,
        DoseSheet(
          t: t,
          slot: s.taken ? null : s,
          edit: s.taken ? s.log : null,
          supplies: supplies,
          prefs: prefs,
          suggested: suggestPlace(prefs, logs, t.id),
        ),
      );
    }

    Future<void> undoSkip() async {
      HapticFeedback.mediumImpact();
      if (await confirm(context, tr('Undo "skip" for this dose?'),
          ok: tr('Undo'))) {
        ref.read(repoProvider)?.deleteLog(s.log!, {});
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardBox(context, radius: 22).copyWith(
        border: late && s.pending
            ? Border.all(color: C.peony.withValues(alpha: .5), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          onTap: s.skipped ? undoSkip : open,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          leading: Icon(s.skipped ? LucideIcons.skipForward : t.adm.icon,
              color: s.taken
                  ? C.lagoon
                  : (s.skipped
                      ? fg.withValues(alpha: .45)
                      : (late ? C.peony : fg))),
          title: Text(t.name,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: s.skipped ? fg.withValues(alpha: .7) : Colors.white)),
          subtitle: Text(
            s.skipped
                ? tr('Skipped, scheduled {0}', [label])
                : '$label, ${fmt(t.dose)} ${t.doseUnit}',
            style: TextStyle(
                color: Pastel.mist.withValues(alpha: 0.85), fontSize: 12),
          ),
          trailing: s.taken
              ? Icon(LucideIcons.circleCheckBig, color: C.lagoon)
              : s.skipped
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: tr('Skip'),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          skipSlot(context, ref, s);
                        },
                        icon: const Icon(LucideIcons.skipForward),
                      ),
                      FilledButton.tonal(
                        onPressed: open,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(tr('Log')),
                      ),
                    ]),
        ),
      ),
    );
  }
}
