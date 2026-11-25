import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../repo.dart';
import '../../sanctuary_data.dart';
import '../../theme.dart';
import '../../voice_pitch.dart';
import '../../workout_coach.dart';
import '../companion_avatar.dart';
import 'moonlight_lantern_page.dart';
import 'safety_quiz_page.dart';
import 'starlight_breath_page.dart';
import 'voice_pitch_page.dart';
import 'workout_page.dart';

/// Calm hub for Lunera's gentle mini-experiences:
/// Starlight Ripples & Breath, Safety & Dosing Sense, Moonlight Lantern,
/// and the unlockable Voice Pitch Studio easter egg.
class SanctuaryPage extends StatefulWidget {
  const SanctuaryPage({super.key});

  @override
  State<SanctuaryPage> createState() => _SanctuaryPageState();
}

class _SanctuaryPageState extends State<SanctuaryPage> {
  LanternState _state = const LanternState();
  bool _voiceUnlocked = false;
  int _workoutSessionsThisMonth = 0;
  Repo? _repo;
  StreamSubscription<List<VoiceTestResult>>? _voiceSub;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = maybeRepoFrom(context);
    if (identical(repo, _repo)) return;
    _repo = repo;
    _voiceSub?.cancel();
    _voiceSub = repo?.voiceResults().listen(_onRemoteVoiceResults);
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    super.dispose();
  }

  Future<void> _onRemoteVoiceResults(List<VoiceTestResult> remote) async {
    try {
      final repo = _repo;
      await VoiceStore.reconcileWithRemote(
        remote,
        uploadMissing: repo?.saveVoiceResult,
      );
      final voiceUnlocked = await VoiceStore.isUnlocked();
      if (!mounted) return;
      if (voiceUnlocked != _voiceUnlocked) {
        setState(() => _voiceUnlocked = voiceUnlocked);
      }
    } catch (_) {
      // Offline/auth transient error: keep current Sanctuary card state.
    }
  }

  Future<void> _loadState() async {
    try {
      final loaded = await SanctuaryStore.load();
      final voiceUnlocked = await VoiceStore.isUnlocked();
      final workoutState = await WorkoutController.loadDirect(_repo?.uid);
      final now = DateTime.now();
      final monthCount = workoutState.logs
          .where((l) => l.at.year == now.year && l.at.month == now.month)
          .length;
      if (!mounted) return;
      setState(() {
        _state = loaded;
        _voiceUnlocked = voiceUnlocked;
        _workoutSessionsThisMonth = monthCount;
      });
    } catch (_) {
      // Non-critical visual summary; keep default state on storage errors.
    }
  }

  Future<void> _open(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await _loadState();
  }

  @override
  Widget build(BuildContext context) {
    final canLight = _state.canLightToday();
    final quizMeta = _state.quizBest > 0
        ? tr('Best: {0}/5', [_state.quizBest])
        : tr('5 quick questions');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: tr('Back'),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tr('Twilight Sanctuary'),
                    style: display(34),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            gap(8),
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              child: Row(
                children: [
                  const CompanionAvatar(
                    mood: CompanionMood.care,
                    size: 74,
                    glowColor: C.magenta,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('Gentle breathing, safety practice, and a quiet light — always at your own pace.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Pastel.mist.withValues(alpha: 0.84),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            gap(20),
            _SanctuaryCard(
              icon: LucideIcons.wind,
              accent: C.lavender,
              title: tr('Starlight Ripples & Breath'),
              subtitle: tr(
                  'Tap ripples and follow a slow 4-4-6 breath to ease tension'),
              badgeText: tr('No score • Calming'),
              onTap: () => _open(const StarlightBreathPage()),
            ),
            gap(14),
            _SanctuaryCard(
              icon: LucideIcons.shieldCheck,
              accent: C.rose,
              title: tr('Safety & Dosing Sense'),
              subtitle: tr(
                  '5-question practice on dosing math, labs, and safe care'),
              badgeText: quizMeta,
              onTap: () => _open(const SafetyQuizPage()),
            ),
            gap(14),
            _SanctuaryCard(
              icon: LucideIcons.sparkles,
              accent: C.coral,
              title: tr('Moonlight Lantern'),
              subtitle: tr(
                  'Light a quiet spark each day you visit — never wilts if you rest'),
              badgeText: tr('{0} {0?spark|sparks}', [_state.sparks]),
              showMintDot: canLight,
              onTap: () => _open(const MoonlightLanternPage()),
            ),
            gap(14),
            _SanctuaryCard(
              icon: LucideIcons.dumbbell,
              accent: Pastel.mint,
              title: tr('Movement Coach'),
              subtitle: tr(
                  'HRT-aware personal trainer with 2-pose guides & guilt-free pacing'),
              badgeText: _workoutSessionsThisMonth > 0
                  ? tr('{0} {0?session|sessions} this month',
                      [_workoutSessionsThisMonth])
                  : tr('No streaks • Adaptive'),
              onTap: () => _open(const WorkoutCoachPage()),
            ),
            if (_voiceUnlocked) ...[
              gap(14),
              _SanctuaryCard(
                icon: LucideIcons.mic,
                accent: C.violet,
                title: tr('Voice Pitch Studio'),
                subtitle: tr(
                    'Gentle voice warm-up, reading prompts & live pitch category check'),
                badgeText: tr('Optional • On-device'),
                onTap: () => _open(const VoicePitchPage()),
              ),
            ],
            gap(22),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.heartHandshake,
                    size: 18,
                    color: Pastel.mint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('No timers, leaderboards, or penalties here. Step in whenever you need a calm minute or a quick safety refresher.'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Pastel.mist.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SanctuaryCard extends StatelessWidget {
  const _SanctuaryCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
    this.showMintDot = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;
  final bool showMintDot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconBadge(icon, accent, size: 46, iconSize: 23),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                gap(4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Pastel.mist.withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
                gap(10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.32)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showMintDot) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Pastel.mint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: C.iconDefault,
          ),
        ],
      ),
    );
  }
}
