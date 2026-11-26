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
import '../widget_sync.dart';
import 'companion_avatar.dart';
import 'daily_checkin_sheet.dart';
import 'guides_page.dart';
import 'sanctuary/starlight_breath_page.dart';

/// Provider holding whether the ambient companion card is dismissed for the current session.
final ambientCompanionDismissedProvider = StateProvider<bool>((ref) => false);

/// Returns the companion bond tier for a given affection (`pats`) count.
({int level, String title, int? nextAt}) companionBondTier(int pats) {
  if (pats < 5) {
    return (level: 1, title: 'Stardust Pal', nextAt: 5);
  }
  if (pats < 20) {
    return (level: 2, title: 'Moonbeam Friend', nextAt: 20);
  }
  if (pats < 50) {
    return (level: 3, title: 'Twilight Bestie', nextAt: 50);
  }
  if (pats < 100) {
    return (level: 4, title: 'Celestial Confidante', nextAt: 100);
  }
  return (level: 5, title: 'Eternal Dusk Soulmate', nextAt: null);
}

Color companionTierGlowColor(int level, Color fallback) => switch (level) {
      2 => Pastel.sky,
      3 => C.lavender,
      4 => C.rose,
      5 => C.coral,
      _ => fallback,
    };

const List<(int level, String title, String perk)> companionBondPerks = [
  (1, 'Stardust Pal', 'Daily status check-ins, water tracker & comforting hugs'),
  (2, 'Moonbeam Friend', 'Unlocks Moonbeam affirmations & soft azure aura'),
  (3, 'Twilight Bestie', 'Unlocks Twilight reflections & lavender sanctuary halo'),
  (4, 'Celestial Confidante', 'Unlocks Confidante encouragement & twilight rose glow'),
  (5, 'Eternal Dusk Soulmate', 'Unlocks all soulful keepsake notes & starlight cream aura'),
];

const Map<int, List<String>> _tierUnlockedAffirmations = {
  2: [
    'Moonbeams never rush to cross the sky—neither do you.',
    'Thank you for checking in with yourself like a true friend.',
  ],
  3: [
    'Through every twilight phase, I am right beside you.',
    'Your consistency—even on quiet days—deserves gentle praise.',
  ],
  4: [
    'You know your rhythm better each month. Trust your quiet wisdom.',
    'Whatever today asks of you, you do not carry it alone.',
  ],
  5: [
    'Eternal Dusk Soulmate: every phase you walk is luminous and yours.',
    'From your first step to today, thank you for letting me keep watch with you.',
  ],
};

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
  CompanionMood.shy,
  CompanionMood.laugh,
];

/// Interactive care tips surfaced on tap, 100% offline-first.
const List<(CompanionMood, String)> companionCareTips = [
  (
    CompanionMood.explain,
    'Rotating injection sites gives local tissue time to settle and recover comfortably.',
  ),
  (
    CompanionMood.think,
    'Staying gently hydrated helps circulation and eases post-dose fatigue.',
  ),
  (
    CompanionMood.ponder,
    'Trough days before your next dose can feel slower—plan lighter tasks when needed.',
  ),
  (
    CompanionMood.explain,
    'Testing labs right before your next scheduled dose helps capture true trough levels.',
  ),
  (
    CompanionMood.care,
    'Warmth and steady breathing before an injection can ease tension in the muscle.',
  ),
  (
    CompanionMood.think,
    'Even 5 minutes of quiet rest counts as caring for your body rhythm.',
  ),
];

/// Playful cozy lines using expressive companion moods.
const List<(CompanionMood, String)> companionSmileLines = [
  (
    CompanionMood.wink,
    'Plot twist: you are doing much better than your inner critic thinks.',
  ),
  (
    CompanionMood.laugh,
    'Certified stardust reminder: surviving today already earns full marks.',
  ),
  (
    CompanionMood.shy,
    'If anyone asks who your biggest fan is... well, I am right here.',
  ),
  (
    CompanionMood.confused,
    'Wait—did you drink water today, or only iced coffee again?',
  ),
  (
    CompanionMood.ponder,
    'Fun fact: even the moon takes a whole month to cycle through its phases.',
  ),
];

/// Calm grounding prompts for anxious or overwhelmed moments.
const List<(CompanionMood, String)> companionCalmLines = [
  (
    CompanionMood.calm,
    'Inhale softly for 4, hold for 4, exhale for 6. Let your shoulders drop.',
  ),
  (
    CompanionMood.care,
    'Name 3 quiet things you can see right now. You only have to handle this minute.',
  ),
  (
    CompanionMood.calm,
    'Unclench your jaw, soften your hands, and take one slow breath with me.',
  ),
];

/// Comforting lines shown on long-press Quiet Hug.
const List<String> companionQuietHugLines = [
  'No rush, no pressure. Take a gentle breath right here.',
  'You do not have to earn rest. I am keeping watch with you.',
  'Whatever today feels like, you are allowed to take it slowly.',
];

const List<(CompanionMood, String)> _pokeDayReactions = [
  (
    CompanionMood.shocked,
    'Whoa, easy there! You startled my stardust.',
  ),
  (
    CompanionMood.shy,
    'Hehe... alright, you have my undivided attention.',
  ),
  (
    CompanionMood.facepalm,
    'I knew you were going to poke me again, did I not?',
  ),
  (
    CompanionMood.laugh,
    'Okay, okay—you really know how to brighten a quiet moment.',
  ),
];

const List<(CompanionMood, String)> _pokeNightReactions = [
  (
    CompanionMood.sleepy,
    'Mmm... five more minutes under the starlight?',
  ),
  (
    CompanionMood.annoyed,
    'Hey, nocturnal tapping is against twilight regulations!',
  ),
  (
    CompanionMood.laugh,
    'Alright, I am awake. Hope you are winding down gently too.',
  ),
];

enum _CompanionMode {
  status,
  affirmation,
  quietHug,
  poke,
  topicCalm,
  topicTip,
  topicSmile,
}

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
            ? tr(
                'Injected recently. Take rest, stay hydrated, and be gentle with yourself.')
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
  static const int _waterTarget = 8;

  _CompanionMode _mode = _CompanionMode.status;
  int _affirmationIndex = 0;
  int _topicIndex = 0;
  int _hugIndex = 0;
  int _pokeIndex = 0;
  int _rapidTapCount = 0;
  int _pats = 0;
  int _waterCups = 0;
  DateTime? _lastTapAt;

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
      final pats = prefs.getInt('cmp_pats_count') ?? 0;
      final savedWaterDate = prefs.getString('cmp_hydration_date');
      final water = savedWaterDate == todayStr
          ? (prefs.getInt('cmp_hydration_cups') ?? 0)
          : 0;
      if (mounted) {
        if (saved == todayStr) {
          ref.read(ambientCompanionDismissedProvider.notifier).state = true;
        }
        setState(() {
          _pats = pats;
          _waterCups = water;
        });
      }
    } catch (_) {}
  }

  Future<void> _recordPat() async {
    final prevLevel = companionBondTier(_pats).level;
    final nextPats = _pats + 1;
    final nextTier = companionBondTier(nextPats);
    setState(() => _pats = nextPats);
    if (nextTier.level > prevLevel && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ ${tr('Bond Level {0}: {1}', [
                  nextTier.level,
                  tr(nextTier.title)
                ])}',
          ),
        ),
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cmp_pats_count', nextPats);
    } catch (_) {}
    await WidgetSync.syncCompanionStats(pats: nextPats, waterCups: _waterCups);
  }

  Future<void> _logWaterCup({bool reset = false}) async {
    HapticFeedback.lightImpact();
    final nextWater = reset ? 0 : _waterCups + 1;
    setState(() => _waterCups = nextWater);
    if (!reset && nextWater == _waterTarget && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('💧 ${tr('Hydration goal reached! Your body thanks you.')}'),
        ),
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('cmp_hydration_date', todayStr);
      await prefs.setInt('cmp_hydration_cups', nextWater);
    } catch (_) {}
    await WidgetSync.syncCompanionStats(pats: _pats, waterCups: nextWater);
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
    final now = DateTime.now();
    final isRapid = _lastTapAt != null &&
        now.difference(_lastTapAt!) <= const Duration(milliseconds: 1200);
    _lastTapAt = now;
    _rapidTapCount = isRapid ? _rapidTapCount + 1 : 1;

    setState(() {
      if (_rapidTapCount >= 4) {
        if (_mode == _CompanionMode.poke) {
          _pokeIndex++;
        } else {
          _mode = _CompanionMode.poke;
          _pokeIndex = 0;
        }
        return;
      }

      if (_mode == _CompanionMode.affirmation) {
        _affirmationIndex =
            (_affirmationIndex + 1) % companionAffirmations.length;
      } else if (_mode == _CompanionMode.topicCalm) {
        _topicIndex = (_topicIndex + 1) % companionCalmLines.length;
      } else if (_mode == _CompanionMode.topicTip) {
        _topicIndex = (_topicIndex + 1) % companionCareTips.length;
      } else if (_mode == _CompanionMode.topicSmile) {
        _topicIndex = (_topicIndex + 1) % companionSmileLines.length;
      } else {
        _mode = _CompanionMode.affirmation;
      }
    });
    _recordPat();
  }

  void _triggerQuietHug() {
    HapticFeedback.mediumImpact();
    _rapidTapCount = 0;
    setState(() {
      if (_mode == _CompanionMode.quietHug) {
        _hugIndex = (_hugIndex + 1) % companionQuietHugLines.length;
      } else {
        _mode = _CompanionMode.quietHug;
      }
    });
    _recordPat();
  }

  void _selectTopic(_CompanionMode topicMode) {
    HapticFeedback.selectionClick();
    _rapidTapCount = 0;
    setState(() {
      if (_mode == topicMode) {
        _topicIndex++;
      } else {
        _mode = topicMode;
        _topicIndex = 0;
      }
    });
  }

  void _resetToStatus() {
    HapticFeedback.selectionClick();
    _rapidTapCount = 0;
    setState(() {
      _mode = _CompanionMode.status;
    });
  }

  ({
    CompanionMood mood,
    String title,
    String message,
    Color glowColor,
    String hintText,
    IconData hintIcon,
  }) _resolvePresentation(AmbientCompanionStatus status) {
    final tier = companionBondTier(_pats);
    final affirmationsPool = <String>[
      ...companionAffirmations,
      for (final e in _tierUnlockedAffirmations.entries)
        if (tier.level >= e.key) ...e.value,
    ];

    switch (_mode) {
      case _CompanionMode.status:
        return (
          mood: status.mood,
          title: status.headline,
          message: status.subtext,
          glowColor: companionTierGlowColor(tier.level, status.glowColor),
          hintText: tr('Tap for gentle thought'),
          hintIcon: LucideIcons.heartHandshake,
        );
      case _CompanionMode.affirmation:
        return (
          mood: companionAffirmationMoods[
              _affirmationIndex % companionAffirmationMoods.length],
          title: tier.level >= 2 ? tr(tier.title) : tr('Gentle Thought'),
          message: tr(affirmationsPool[_affirmationIndex % affirmationsPool.length]),
          glowColor: companionTierGlowColor(tier.level, C.peony),
          hintText: tr('Tap for another thought'),
          hintIcon: LucideIcons.sparkles,
        );
      case _CompanionMode.quietHug:
        return (
          mood: CompanionMood.love,
          title: tr('Quiet Hug'),
          message: tr(companionQuietHugLines[
              _hugIndex % companionQuietHugLines.length]),
          glowColor: C.peony,
          hintText: tr('Holding space with you'),
          hintIcon: LucideIcons.heart,
        );
      case _CompanionMode.poke:
        final pool =
            status.tag == 'night' ? _pokeNightReactions : _pokeDayReactions;
        final item = pool[_pokeIndex % pool.length];
        return (
          mood: item.$1,
          title: tr('Playful Moment'),
          message: tr(item.$2),
          glowColor: C.coral,
          hintText: tr('Tap again or reset above'),
          hintIcon: LucideIcons.sparkles,
        );
      case _CompanionMode.topicCalm:
        final item =
            companionCalmLines[_topicIndex % companionCalmLines.length];
        return (
          mood: item.$1,
          title: tr('Steady Breath'),
          message: tr(item.$2),
          glowColor: C.lavender,
          hintText: tr('Tap for another calming cue'),
          hintIcon: LucideIcons.wind,
        );
      case _CompanionMode.topicTip:
        final item = companionCareTips[_topicIndex % companionCareTips.length];
        return (
          mood: item.$1,
          title: tr('Gentle Care Tip'),
          message: tr(item.$2),
          glowColor: Pastel.mint,
          hintText: tr('Tap for another tip'),
          hintIcon: LucideIcons.lightbulb,
        );
      case _CompanionMode.topicSmile:
        final item =
            companionSmileLines[_topicIndex % companionSmileLines.length];
        return (
          mood: item.$1,
          title: tr('Light Moment'),
          message: tr(item.$2),
          glowColor: C.coral,
          hintText: tr('Tap for another smile'),
          hintIcon: LucideIcons.smile,
        );
    }
  }

  Future<void> _openDailyRitual() async {
    HapticFeedback.selectionClick();
    final completed = await showSheet<bool>(context, const DailyCheckInSheet());
    if (completed == true && mounted) {
      await _checkDismissedState();
    }
  }

  void _openBondPerksSheet() {
    HapticFeedback.selectionClick();
    final tier = companionBondTier(_pats);
    showSheet<void>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CompanionAvatar(
                mood: CompanionMood.love,
                size: 56,
                glowColor: companionTierGlowColor(tier.level, C.peony),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(tier.title),
                      style: display(24, color: Colors.white),
                    ),
                    Text(
                      tier.nextAt != null
                          ? tr('♥ {0} • Next tier at {1}', [_pats, tier.nextAt!])
                          : tr('♥ {0} • Highest bond tier reached', [_pats]),
                      style: tabular(const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: C.lavender,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          gap(16),
          for (final item in companionBondPerks) ...[
            Builder(builder: (_) {
              final unlocked = tier.level >= item.$1;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.midnight.withValues(alpha: unlocked ? 0.8 : 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked
                        ? Pastel.mint.withValues(alpha: 0.4)
                        : C.lavender.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      unlocked ? LucideIcons.check : LucideIcons.moon,
                      size: 16,
                      color: unlocked ? Pastel.mint : C.iconDefault,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Bond Level {0}: {1}', [item.$1, tr(item.$2)]),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: unlocked
                                  ? Colors.white
                                  : Pastel.mist.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            tr(item.$3),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Pastel.mist
                                  .withValues(alpha: unlocked ? 0.82 : 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          gap(10),
          pillButton(
            tr('Start 60s Daily Ritual'),
            () {
              Navigator.pop(context);
              _openDailyRitual();
            },
            icon: LucideIcons.sparkles,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDismissed = ref.watch(ambientCompanionDismissedProvider);
    if (isDismissed) {
      return const SizedBox.shrink();
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || isTestEnv;
    final status = evaluateAmbientCompanion(
      now: widget.now,
      logs: widget.logs,
      slots: widget.slots,
      therapies: widget.therapies,
    );

    final view = _resolvePresentation(status);
    final currentMood = view.mood;
    final currentTitle = view.title;
    final currentMessage = view.message;
    final glowColor = view.glowColor;
    final isInteractiveMode = _mode != _CompanionMode.status;

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
            onLongPress: _triggerQuietHug,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Companion Avatar with ambient halo and long-press hug
                      GestureDetector(
                        onLongPress: _triggerQuietHug,
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey('avatar_${currentMood.name}'),
                            child: CompanionAvatar(
                              mood: currentMood,
                              size: 76,
                              glowColor: glowColor,
                              showGlow: true,
                              enablePulse: true,
                            ),
                          ),
                        ),
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
                                      key: ValueKey(
                                          'ambient_title_$currentTitle'),
                                      style: display(15.5,
                                          weight: FontWeight.w700,
                                          color:
                                              dark ? Colors.white : C.midnight),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (isInteractiveMode) ...[
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
                                key: ValueKey(
                                    'ambient_msg_${_mode.name}_$_affirmationIndex$_topicIndex$_hugIndex$_pokeIndex'),
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
                                  view.hintIcon,
                                  size: 11,
                                  color: glowColor.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    view.hintText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: glowColor.withValues(alpha: 0.90),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _CompanionTopicChip(
                        icon: LucideIcons.wind,
                        label: tr('Calm me'),
                        selected: _mode == _CompanionMode.topicCalm,
                        accent: C.lavender,
                        onTap: () => _selectTopic(_CompanionMode.topicCalm),
                      ),
                      _CompanionTopicChip(
                        icon: LucideIcons.lightbulb,
                        label: tr('Care tip'),
                        selected: _mode == _CompanionMode.topicTip,
                        accent: Pastel.mint,
                        onTap: () => _selectTopic(_CompanionMode.topicTip),
                      ),
                      _CompanionTopicChip(
                        icon: LucideIcons.smile,
                        label: tr('Smile'),
                        selected: _mode == _CompanionMode.topicSmile,
                        accent: C.coral,
                        onTap: () => _selectTopic(_CompanionMode.topicSmile),
                      ),
                      GestureDetector(
                        onLongPress: () => _logWaterCup(reset: true),
                        child: _CompanionTopicChip(
                          icon: LucideIcons.droplet,
                          label: '${tr('Water')} $_waterCups/$_waterTarget',
                          selected: _waterCups >= _waterTarget,
                          accent: Pastel.sky,
                          onTap: _logWaterCup,
                        ),
                      ),
                      _CompanionTopicChip(
                        icon: LucideIcons.heart,
                        label: '$_pats · ${tr(companionBondTier(_pats).title)}',
                        selected: false,
                        accent: C.peony,
                        onTap: _openBondPerksSheet,
                      ),
                      _CompanionTopicChip(
                        icon: LucideIcons.sparkles,
                        label: tr('Daily ritual'),
                        selected: false,
                        accent: C.lavender,
                        onTap: _openDailyRitual,
                      ),
                      if (_mode == _CompanionMode.topicCalm)
                        _CompanionTopicChip(
                          icon: LucideIcons.arrowUpRight,
                          label: tr('Open Breathing'),
                          selected: true,
                          accent: C.aurora,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const StarlightBreathPage(),
                              ),
                            );
                          },
                        ),
                      if (_mode == _CompanionMode.topicTip)
                        _CompanionTopicChip(
                          icon: LucideIcons.bookOpen,
                          label: tr('Read Guides'),
                          selected: true,
                          accent: Pastel.mint,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GuidesPage(),
                              ),
                            );
                          },
                        ),
                    ],
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

class _CompanionTopicChip extends StatelessWidget {
  const _CompanionTopicChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: dark ? 0.22 : 0.16)
                : (dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : C.midnight.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : (dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : C.midnight.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: selected
                    ? accent
                    : (dark
                        ? Pastel.mist.withValues(alpha: 0.8)
                        : C.midnight.withValues(alpha: 0.72)),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? (dark ? Colors.white : C.midnight)
                        : (dark
                            ? Pastel.mist.withValues(alpha: 0.85)
                            : C.midnight.withValues(alpha: 0.78)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
