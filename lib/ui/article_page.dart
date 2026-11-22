import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guides_data.dart';
import '../l10n.dart';
import '../theme.dart';
import '../voice_pitch.dart';
import 'insights.dart';
import 'levels.dart';
import 'sanctuary/voice_pitch_page.dart';
import 'security_page.dart';
import 'site_map.dart';

const _kGuidesReadKey = 'guides.read_ids';

/// Direct full-screen reader page for a single [GuideArticle].
class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.article});

  final GuideArticle article;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  int _voiceTapCount = 0;
  bool _voiceUnlocked = false;

  @override
  void initState() {
    super.initState();
    _markRead();
    if (widget.article.id == 'voice_training') {
      _loadVoiceUnlock();
    }
  }

  Future<void> _loadVoiceUnlock() async {
    try {
      final unlocked = await VoiceStore.isUnlocked();
      if (!mounted) return;
      setState(() => _voiceUnlocked = unlocked);
    } catch (_) {
      // Ignore storage read errors gracefully.
    }
  }

  Future<void> _handleVoiceEasterEggTap() async {
    if (_voiceUnlocked) {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const VoicePitchPage()),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final next = _voiceTapCount + 1;
    if (next >= 5) {
      await VoiceStore.setUnlocked(true);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _voiceTapCount = 5;
        _voiceUnlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Voice Pitch Studio unlocked in Twilight Sanctuary.')),
        ),
      );
    } else {
      setState(() => _voiceTapCount = next);
    }
  }

  Future<void> _markRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kGuidesReadKey) ?? const <String>[];
      if (!list.contains(widget.article.id)) {
        await prefs.setStringList(
            _kGuidesReadKey, [...list, widget.article.id]);
      }
    } catch (_) {
      // Non-critical read badge persistence; ignore storage errors.
    }
  }

  void _runAction(BuildContext context, GuideActionType action) {
    HapticFeedback.lightImpact();
    switch (action) {
      case GuideActionType.siteMap:
        showSheet(context, const SiteRotationSheet());
        break;
      case GuideActionType.addLab:
        showSheet(context, const LabSheet());
        break;
      case GuideActionType.security:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SecurityPage()),
        );
        break;
      case GuideActionType.insights:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
        );
        break;
      case GuideActionType.none:
        break;
    }
  }

  (String, IconData)? _actionMeta(GuideActionType action) {
    switch (action) {
      case GuideActionType.siteMap:
        return (tr('Open Injection Site Map'), LucideIcons.bandage);
      case GuideActionType.addLab:
        return (tr('Log Lab Result'), LucideIcons.flaskConical);
      case GuideActionType.security:
        return (tr('Open Security Settings'), LucideIcons.shieldCheck);
      case GuideActionType.insights:
        return (tr('Open Insights'), LucideIcons.activity);
      case GuideActionType.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final accent = article.category.color;
    final actionMeta = _actionMeta(article.action);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: tr('Back'),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(article.category.icon, size: 13, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        article.category.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  tr('{0} min read', [article.readMinutes]),
                  style: TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            gap(14),
            Text(article.title, style: display(30, color: Colors.white)),
            gap(8),
            Text(
              article.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Pastel.mist.withValues(alpha: 0.88),
                height: 1.45,
              ),
            ),
            gap(18),

            // Key Takeaways Card
            AppCard(
              highlight: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles,
                          size: 17, color: C.lavender),
                      const SizedBox(width: 8),
                      Text(
                        tr('Key takeaways'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.lavender,
                        ),
                      ),
                    ],
                  ),
                  gap(10),
                  for (var i = 0; i < article.takeaways.length; i++) ...[
                    _BulletRow(
                      text: article.takeaways[i],
                      dotColor: accent,
                    ),
                    if (i < article.takeaways.length - 1) gap(8),
                  ],
                ],
              ),
            ),
            gap(20),

            // Article Sections
            for (final section in article.sections) ...[
              Text(
                section.heading,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              gap(8),
              for (final p in section.paragraphs) ...[
                Text(
                  p,
                  style: TextStyle(
                    fontSize: 14,
                    color: Pastel.mist.withValues(alpha: 0.92),
                    height: 1.55,
                  ),
                ),
                gap(10),
              ],
              if (section.bullets.isNotEmpty) ...[
                for (final b in section.bullets) ...[
                  _BulletRow(text: b, dotColor: accent),
                  gap(8),
                ],
              ],
              if (section.callout != null) ...[
                gap(4),
                _CalloutBox(callout: section.callout!),
                gap(12),
              ],
              gap(14),
            ],

            // Contextual Shortcut Button
            if (actionMeta != null) ...[
              pillButton(
                actionMeta.$1,
                () => _runAction(context, article.action),
                icon: actionMeta.$2,
                color: C.aurora,
              ),
              gap(20),
            ],

            if (article.id == 'voice_training') ...[
              _VoiceEasterEggCard(
                unlocked: _voiceUnlocked,
                onTap: _handleVoiceEasterEggTap,
              ),
              gap(20),
            ],

            // Medical Disclaimer & References
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.info,
                          size: 16, color: C.iconDefault),
                      const SizedBox(width: 8),
                      Text(
                        tr('Medical Disclaimer'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  gap(6),
                  Text(
                    tr('This guide provides general educational and harm-reduction information only. It is not a prescription or substitute for individualized medical care.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Pastel.mist.withValues(alpha: 0.80),
                      height: 1.45,
                    ),
                  ),
                  if (article.references.isNotEmpty) ...[
                    gap(12),
                    const Divider(height: 1),
                    gap(12),
                    Text(
                      tr('Trusted references'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: C.lavender,
                      ),
                    ),
                    gap(6),
                    for (final refItem in article.references) ...[
                      Text(
                        '• $refItem',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Pastel.mist.withValues(alpha: 0.74),
                          height: 1.4,
                        ),
                      ),
                      gap(3),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.dotColor});

  final String text;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: Pastel.mist.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalloutBox extends StatelessWidget {
  const _CalloutBox({required this.callout});

  final GuideCallout callout;

  @override
  Widget build(BuildContext context) {
    final isWarning = callout.type == GuideCalloutType.warning;
    final accent = isWarning ? C.coral : Pastel.mint;
    final icon = isWarning ? LucideIcons.triangleAlert : LucideIcons.lightbulb;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callout.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                gap(4),
                Text(
                  callout.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: Pastel.mist.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceEasterEggCard extends StatelessWidget {
  const _VoiceEasterEggCard({
    required this.unlocked,
    required this.onTap,
  });

  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlight: unlocked,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          iconBadge(
            LucideIcons.mic,
            unlocked ? Pastel.mint : C.violet,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked
                      ? tr('Open Voice Pitch Studio')
                      : tr('Voice Resonance & Pacing Studio'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                gap(4),
                Text(
                  unlocked
                      ? tr('Voice Pitch Studio unlocked in Twilight Sanctuary.')
                      : tr('Tap 5 times to unlock the optional Voice Pitch Studio in Twilight Sanctuary.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.80),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            unlocked ? LucideIcons.chevronRight : LucideIcons.sparkles,
            size: 18,
            color: unlocked ? Pastel.mint : C.iconDefault,
          ),
        ],
      ),
    );
  }
}
