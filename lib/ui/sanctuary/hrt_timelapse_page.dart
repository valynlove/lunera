import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../companion_avatar.dart';
import '../responsive.dart';

/// Therapy pathway options for the HRT Time-Lapse Visual explorer.
enum TimelapsePath {
  feminizing,
  masculinizing;

  String get prefix => this == feminizing ? 'mtf' : 'ftm';

  String get label =>
      this == feminizing ? tr('Feminizing (MtF)') : tr('Masculinizing (FtM)');

  Color get accent => this == feminizing ? C.rose : C.violet;
}

class _TimelapseStage {
  const _TimelapseStage({
    required this.index,
    required this.timeframe,
    required this.title,
    required this.summary,
    required this.highlights,
    required this.companionMood,
    required this.companionNote,
  });

  final int index;
  final String timeframe;
  final String title;
  final String summary;
  final List<String> highlights;
  final CompanionMood companionMood;
  final String companionNote;

  String assetPath(TimelapsePath path) =>
      'assets/images/timelapse/${path.prefix}_stage_$index.png';
}

const _mtfStages = <_TimelapseStage>[
  _TimelapseStage(
    index: 0,
    timeframe: 'Day 1',
    title: 'Baseline',
    summary:
        'Your starting point before or right at the beginning of feminizing therapy.',
    highlights: [
      'A calm moment to note your baseline mood, measurements, and goals.',
      'Everyone starts from a different place — progress is personal, not a race.',
    ],
    companionMood: CompanionMood.wave,
    companionNote:
        'Take a gentle breath. Every journey starts with a single quiet step.',
  ),
  _TimelapseStage(
    index: 1,
    timeframe: '1–3 Mo',
    title: 'Early Spark',
    summary:
        'Subtle internal and surface shifts often begin during the first few months.',
    highlights: [
      'Skin may gradually feel softer and less oily.',
      'Emotional sensitivity and mood shifts can become more noticeable.',
      'Early chest tenderness or budding may begin.',
    ],
    companionMood: CompanionMood.care,
    companionNote:
        'Small changes count too — even when they are mostly felt before they are seen.',
  ),
  _TimelapseStage(
    index: 2,
    timeframe: '3–6 Mo',
    title: 'Softening Contours',
    summary:
        'Visible body and facial transitions typically start becoming easier to notice.',
    highlights: [
      'Subcutaneous fat gradually softens facial and cheek contours.',
      'Body hair growth may slow and become finer over time.',
      'Ongoing breast development continues at its own steady pace.',
    ],
    companionMood: CompanionMood.happy,
    companionNote:
        'Remember to stay hydrated and keep up with regular lab check-ins.',
  ),
  _TimelapseStage(
    index: 3,
    timeframe: '6–12 Mo',
    title: 'Deepening Bloom',
    summary:
        'Body composition and fat redistribution patterns become more established.',
    highlights: [
      'Fat redistribution toward hips, thighs, and glutes becomes clearer.',
      'Muscle mass in the upper body may gradually decrease.',
      'Skin texture and facial softness continue maturing.',
    ],
    companionMood: CompanionMood.cheer,
    companionNote:
        'Half a year to a full year is a big milestone — be kind to your pace.',
  ),
  _TimelapseStage(
    index: 4,
    timeframe: '12–24+ Mo',
    title: 'Steady Horizon',
    summary:
        'Long-term feminizing effects continue refining over two to three years and beyond.',
    highlights: [
      'Breast development and fat distribution continue maturing gradually.',
      'Overall silhouette and skin feel settle into a steady rhythm.',
      'Routine maintenance, labs, and self-care remain your anchor.',
    ],
    companionMood: CompanionMood.love,
    companionNote:
        'Every phase is your own. Celebrate how far you have walked.',
  ),
];

const _ftmStages = <_TimelapseStage>[
  _TimelapseStage(
    index: 0,
    timeframe: 'Day 1',
    title: 'Baseline',
    summary:
        'Your starting point before or right at the beginning of masculinizing therapy.',
    highlights: [
      'A calm moment to record your baseline voice pitch, measurements, and goals.',
      'Every body responds on its own timeline — there is no single pace.',
    ],
    companionMood: CompanionMood.wave,
    companionNote:
        'Take a gentle breath. Every journey starts with a single quiet step.',
  ),
  _TimelapseStage(
    index: 1,
    timeframe: '1–3 Mo',
    title: 'First Shift',
    summary:
        'Early skin, energy, and vocal sensations often appear in the opening months.',
    highlights: [
      'Skin may become slightly thicker or oilier; gentle skincare helps.',
      'Throat scratchiness or subtle vocal heaviness can signal early voice shifts.',
      'Energy levels and appetite may feel different.',
    ],
    companionMood: CompanionMood.care,
    companionNote:
        'Early vocal changes can feel subtle at first — rest your voice when it feels tired.',
  ),
  _TimelapseStage(
    index: 2,
    timeframe: '3–6 Mo',
    title: 'Emerging Definition',
    summary:
        'Voice deepening and early facial or body hair changes often pick up here.',
    highlights: [
      'Voice pitch typically begins dropping more noticeably.',
      'Fine facial hair ("peach fuzz") and body hair may start darkening.',
      'Muscle tone and shoulder/upper-body definition begin responding.',
    ],
    companionMood: CompanionMood.happy,
    companionNote:
        'You can pair this phase with Voice Pitch Studio whenever you feel curious.',
  ),
  _TimelapseStage(
    index: 3,
    timeframe: '6–12 Mo',
    title: 'Steady Strength',
    summary:
        'Voice, muscle composition, and hair growth continue maturing steadily.',
    highlights: [
      'Voice deepens further and begins stabilizing into a new range.',
      'Facial and body hair continue filling in gradually.',
      'Fat redistribution away from hips toward the midsection progresses.',
    ],
    companionMood: CompanionMood.cheer,
    companionNote:
        'Half a year to a full year is a big milestone — keep honoring your routine.',
  ),
  _TimelapseStage(
    index: 4,
    timeframe: '12–24+ Mo',
    title: 'Grounded Horizon',
    summary:
        'Long-term masculinizing features continue developing over several years.',
    highlights: [
      'Facial hair and jawline definition continue maturing over years 2–5.',
      'Muscle mass and body fat distribution settle into a steady pattern.',
      'Regular lab monitoring keeps your therapy safe and balanced.',
    ],
    companionMood: CompanionMood.love,
    companionNote:
        'Every phase is your own. Celebrate how far you have walked.',
  ),
];

/// Interactive HRT Time-Lapse Visual explorer inside Twilight Sanctuary.
/// Uses transparent stage sprites when available and renders a calm placeholder
/// canvas until custom illustrations are added.
class HrtTimelapsePage extends StatefulWidget {
  const HrtTimelapsePage({super.key});

  @override
  State<HrtTimelapsePage> createState() => _HrtTimelapsePageState();
}

class _HrtTimelapsePageState extends State<HrtTimelapsePage> {
  TimelapsePath _path = TimelapsePath.feminizing;
  int _stageIndex = 0;

  List<_TimelapseStage> get _stages =>
      _path == TimelapsePath.feminizing ? _mtfStages : _ftmStages;

  void _selectPath(TimelapsePath path) {
    if (_path == path) return;
    HapticFeedback.selectionClick();
    setState(() => _path = path);
  }

  void _selectStage(int index) {
    final clamped = index.clamp(0, _stages.length - 1);
    if (_stageIndex == clamped) return;
    HapticFeedback.selectionClick();
    setState(() => _stageIndex = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stageIndex];
    final accent = _path.accent;

    return Scaffold(
      body: SafeArea(
        child: AdaptivePageFrame(
          reading: true,
          child: ListView(
            padding: context.pagePadding(top: 12, bottom: 36),
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
                    tr('HRT Time-Lapse'),
                    style: display(30),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            gap(12),
            _PathToggle(
              selected: _path,
              onSelect: _selectPath,
            ),
            gap(16),
            _TimelapseCanvas(
              path: _path,
              stage: stage,
              accent: accent,
            ),
            gap(14),
            _TimelineScrubber(
              stages: _stages,
              currentIndex: _stageIndex,
              accent: accent,
              onChanged: _selectStage,
            ),
            gap(16),
            _StageDetailsCard(
              stage: stage,
              accent: accent,
            ),
            gap(14),
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              child: Row(
                children: [
                  CompanionAvatar(
                    mood: stage.companionMood,
                    size: 72,
                    glowColor: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(stage.companionNote),
                      style: TextStyle(
                        fontSize: 13,
                        color: Pastel.mist.withValues(alpha: 0.88),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            gap(14),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 17,
                    color: accent.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('General educational reference only. Every body responds at its own pace depending on genetics, dosage, and lab levels.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Pastel.mist.withValues(alpha: 0.76),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _PathToggle extends StatelessWidget {
  const _PathToggle({
    required this.selected,
    required this.onSelect,
  });

  final TimelapsePath selected;
  final ValueChanged<TimelapsePath> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.deepCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.lavender.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: TimelapsePath.values.map((path) {
          final active = path == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(path),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? path.accent.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: active
                      ? Border.all(color: path.accent.withValues(alpha: 0.55))
                      : null,
                ),
                child: Text(
                  path.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? Colors.white
                        : Pastel.mist.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimelapseCanvas extends StatelessWidget {
  const _TimelapseCanvas({
    required this.path,
    required this.stage,
    required this.accent,
  });

  final TimelapsePath path;
  final _TimelapseStage stage;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final asset = stage.assetPath(path);

    return AppCard(
      highlight: true,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 310,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.22),
                    C.aurora.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Image.asset(
              'assets/images/timelapse/portal_frame.png',
              height: 302,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Image.asset(
                  asset,
                  key: ValueKey<String>(asset),
                  height: 228,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => _StagePlaceholder(
                    key: ValueKey<String>('placeholder_$asset'),
                    stage: stage,
                    accent: accent,
                    expectedAssetPath: asset,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: C.voidBg.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  tr(stage.timeframe),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StagePlaceholder extends StatelessWidget {
  const _StagePlaceholder({
    super.key,
    required this.stage,
    required this.accent,
    required this.expectedAssetPath,
  });

  final _TimelapseStage stage;
  final Color accent;
  final String expectedAssetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.nebula.withValues(alpha: 0.55),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            LucideIcons.sparkles,
            size: 42,
            color: accent,
          ),
        ),
        gap(14),
        Text(
          '${tr('Stage')} ${stage.index + 1} • ${tr(stage.title)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        gap(6),
        Text(
          expectedAssetPath,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: Pastel.mist.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _TimelineScrubber extends StatelessWidget {
  const _TimelineScrubber({
    required this.stages,
    required this.currentIndex,
    required this.accent,
    required this.onChanged,
  });

  final List<_TimelapseStage> stages;
  final int currentIndex;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: C.nebula,
              thumbColor: Colors.white,
              overlayColor: accent.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (stages.length - 1).toDouble(),
              divisions: stages.length - 1,
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          Row(
            children: stages.map((stage) {
              final active = stage.index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(stage.index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tr(stage.timeframe),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? accent
                              : Pastel.mist.withValues(alpha: 0.58),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StageDetailsCard extends StatelessWidget {
  const _StageDetailsCard({
    required this.stage,
    required this.accent,
  });

  final _TimelapseStage stage;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(stage.title),
                  style: display(24, color: Colors.white),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  tr(stage.timeframe),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          gap(8),
          Text(
            tr(stage.summary),
            style: TextStyle(
              fontSize: 13.5,
              color: Pastel.mist.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
          gap(12),
          ...stage.highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(item),
                      style: TextStyle(
                        fontSize: 13,
                        color: Pastel.mist.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
