import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import '../models.dart';
import '../schedule.dart';
import '../theme.dart';
import 'companion_avatar.dart';

/// Provider holding whether the ambient companion card is dismissed for the current session.
final ambientCompanionDismissedProvider = StateProvider<bool>((ref) => false);

/// Evaluated contextual status of the companion.
class AmbientCompanionStatus {
  final CompanionMood mood;
  final String headline;
  final String subtext;
  final Color glowColor;
  final String tag;

  const AmbientCompanionStatus({
    required this.mood,
    required this.headline,
    required this.subtext,
    this.glowColor = C.aurora,
    this.tag = 'general',
  });
}

/// Curated affirmations that cycle on tap, validating the user's personal journey.
const List<String> companionAffirmations = [
  'Every phase of your journey is entirely your own.',
  'Rest is not a detour; it is part of the path.',
  'You are honoring yourself with every gentle choice.',
  'Small steady steps weave the deepest changes.',
  'Be proud of showing up for yourself today.',
  'Take a deep, slow breath. You are safe here.',
  'Honor where you are in this very moment.',
];

const List<CompanionMood> companionAffirmationMoods = [
  CompanionMood.cheer,
  CompanionMood.love,
  CompanionMood.wink,
  CompanionMood.happy,
  CompanionMood.calm,
];

/// Pure function evaluating the companion's mood and contextual message based on
/// local time, recent doses, and upcoming slots.
AmbientCompanionStatus evaluateAmbientCompanion({
  required DateTime now,
  required List<DoseLog> logs,
  required List<Slot> slots,
  required List<Therapy> therapies,
}) {
  // 1. Upcoming Imminent Dose (pending slot within the next 2 hours or up to 30 mins late)
  final pendingSlots = slots.where((s) => s.pending).toList();
  final imminentSlot = pendingSlots.where((s) {
    final diff = s.at.difference(now);
    return diff.inMinutes >= -30 && diff.inHours <= 2;
  }).firstOrNull;

  if (imminentSlot != null) {
    return AmbientCompanionStatus(
      mood: CompanionMood.remind,
      headline: tr('Gentle Horizon'),
      subtext: tr('Your upcoming dose ({0}) is approaching quietly.',
          [imminentSlot.t.name]),
      glowColor: C.lavender,
      tag: 'upcoming_dose',
    );
  }

  // 2. Post-Dose Recovery (injection within 24h, oral/other within 4h)
  final recentLogs = [...logs]..sort((a, b) => b.at.compareTo(a.at));
  final lastRecent = recentLogs.where((l) => !l.skipped).firstOrNull;
  if (lastRecent != null) {
    final elapsedHours = now.difference(lastRecent.at).inHours;
    final therapy =
        therapies.where((t) => t.id == lastRecent.therapyId).firstOrNull;
    final isInj = therapy?.route == 'inj';
    final maxRecoveryHours = isInj ? 24 : 4;
    if (elapsedHours >= 0 && elapsedHours < maxRecoveryHours) {
      return AmbientCompanionStatus(
        mood: CompanionMood.care,
        headline: isInj ? tr('Gentle Post-Care') : tr('Nurturing Rhythm'),
        subtext: isInj
            ? tr('Injected recently. Take rest, stay hydrated, and be gentle with yourself.')
            : tr('Recent dose logged. Take today at your own peaceful pace.'),
        glowColor: C.peony,
        tag: 'post_dose',
      );
    }
  }

  // 3. Time-of-Day Context
  final hour = now.hour;
  if (hour >= 23 || hour < 5) {
    return AmbientCompanionStatus(
      mood: CompanionMood.sleepy,
      headline: tr('Quiet Night'),
      subtext: tr('Rest your mind. The stars will keep watch until dawn.'),
      glowColor: C.indigo,
      tag: 'night',
    );
  } else if (hour >= 5 && hour < 11) {
    return AmbientCompanionStatus(
      mood: CompanionMood.wave,
      headline: tr('Morning Light'),
      subtext: tr(
          'A new day begins. Remember to breathe and move at your own serene pace.'),
      glowColor: C.aurora,
      tag: 'morning',
    );
  } else if (hour >= 11 && hour < 17) {
    return AmbientCompanionStatus(
      mood: CompanionMood.cheer,
      headline: tr('Radiant Afternoon'),
      subtext: tr(
          'Take a quiet moment to stretch and appreciate how far you have come.'),
      glowColor: C.coral,
      tag: 'afternoon',
    );
  } else {
    // 17 <= hour < 23
    return AmbientCompanionStatus(
      mood: CompanionMood.calm,
      headline: tr('Evening Serenity'),
      subtext: tr('Twilight settles in. Unwind and let go of today\'s rush.'),
      glowColor: C.lavender,
      tag: 'evening',
    );
  }
}

/// An ambient micro-presence on Home featuring the Lunera chibi companion.
class AmbientCompanionCard extends ConsumerStatefulWidget {
  const AmbientCompanionCard({
    super.key,
    required this.now,
    required this.logs,
    required this.slots,
    required this.therapies,
  });

  final DateTime now;
  final List<DoseLog> logs;
  final List<Slot> slots;
  final List<Therapy> therapies;

  @override
  ConsumerState<AmbientCompanionCard> createState() =>
      _AmbientCompanionCardState();
}

class _AmbientCompanionCardState extends ConsumerState<AmbientCompanionCard> {
  bool _showingAffirmation = false;
  int _affirmationIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkDismissedState();
  }

  Future<void> _checkDismissedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('ambient_companion_dismissed_date');
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (saved == todayStr && mounted) {
        ref.read(ambientCompanionDismissedProvider.notifier).state = true;
      }
    } catch (_) {}
  }

  Future<void> _dismissForToday() async {
    HapticFeedback.selectionClick();
    ref.read(ambientCompanionDismissedProvider.notifier).state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('ambient_companion_dismissed_date', todayStr);
    } catch (_) {}
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    setState(() {
      if (!_showingAffirmation) {
        _showingAffirmation = true;
      } else {
        _affirmationIndex =
            (_affirmationIndex + 1) % companionAffirmations.length;
      }
    });
  }

  void _resetToStatus() {
    HapticFeedback.selectionClick();
    setState(() {
      _showingAffirmation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDismissed = ref.watch(ambientCompanionDismissedProvider);
    if (isDismissed) {
      return const SizedBox.shrink();
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final status = evaluateAmbientCompanion(
      now: widget.now,
      logs: widget.logs,
      slots: widget.slots,
      therapies: widget.therapies,
    );

    final currentMood = _showingAffirmation
        ? companionAffirmationMoods[
            _affirmationIndex % companionAffirmationMoods.length]
        : status.mood;

    final currentTitle =
        _showingAffirmation ? tr('Gentle Thought') : status.headline;

    final currentMessage = _showingAffirmation
        ? tr(companionAffirmations[_affirmationIndex])
        : status.subtext;

    final glowColor = _showingAffirmation ? C.peony : status.glowColor;

    return Semantics(
      label: '$currentTitle: $currentMessage',
      child: Container(
        decoration: BoxDecoration(
          color: C.deepCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: glowColor.withValues(alpha: dark ? 0.32 : 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (dark ? C.voidBg : Colors.black12).withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
            if (dark)
              BoxShadow(
                color: glowColor.withValues(alpha: 0.12),
                blurRadius: 14,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Companion Avatar with ambient halo
                  CompanionAvatar(
                    mood: currentMood,
                    size: 58,
                    glowColor: glowColor,
                    showGlow: true,
                    enablePulse: true,
                  ),
                  const SizedBox(width: 14),

                  // Content Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                child: Text(
                                  currentTitle,
                                  key: ValueKey('ambient_title_$currentTitle'),
                                  style: display(15.5,
                                      weight: FontWeight.w700,
                                      color:
                                          dark ? Colors.white : C.midnight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (_showingAffirmation) ...[
                              IconButton(
                                icon: const Icon(LucideIcons.rotateCcw,
                                    size: 14, color: Pastel.lilac),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                tooltip: tr('Back to status'),
                                onPressed: _resetToStatus,
                              ),
                            ],
                            IconButton(
                              icon: const Icon(LucideIcons.x,
                                  size: 15, color: C.iconDefault),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              tooltip: tr('Hide for today'),
                              onPressed: _dismissForToday,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          child: Text(
                            currentMessage,
                            key: ValueKey('ambient_msg_${_showingAffirmation}_$_affirmationIndex'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: dark
                                  ? Pastel.mist.withValues(alpha: 0.90)
                                  : C.midnight.withValues(alpha: 0.75),
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _showingAffirmation
                                  ? LucideIcons.sparkles
                                  : LucideIcons.heartHandshake,
                              size: 11,
                              color: glowColor.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _showingAffirmation
                                  ? tr('Tap for another thought')
                                  : tr('Tap for gentle thought'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: glowColor.withValues(alpha: 0.90),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
