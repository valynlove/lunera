import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../guides_data.dart';
import '../../l10n.dart';
import '../../sanctuary_data.dart';
import '../../theme.dart';
import '../article_page.dart';

/// Supportive 5-question practice round covering dosing math, labs, and safe care.
class SafetyQuizPage extends StatefulWidget {
  const SafetyQuizPage({super.key, this.questions});

  final List<SafetyQuizQuestion>? questions;

  @override
  State<SafetyQuizPage> createState() => _SafetyQuizPageState();
}

class _SafetyQuizPageState extends State<SafetyQuizPage> {
  late List<SafetyQuizQuestion> _round;
  int _index = 0;
  int? _selectedOption;
  int _score = 0;
  bool _finished = false;
  int? _bestScore;

  @override
  void initState() {
    super.initState();
    _round = widget.questions != null && widget.questions!.isNotEmpty
        ? List<SafetyQuizQuestion>.from(widget.questions!)
        : pickQuizRound(count: 5);
  }

  void _chooseOption(int optionIdx) {
    if (_selectedOption != null) return;
    final q = _round[_index];
    final correct = optionIdx == q.correctIndex;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOption = optionIdx;
      if (correct) _score++;
    });
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    if (_index + 1 < _round.length) {
      setState(() {
        _index++;
        _selectedOption = null;
      });
      return;
    }
    var best = _score;
    try {
      best = await SanctuaryStore.recordQuizScore(_score);
    } catch (_) {
      // Ignore storage failures when completing a practice round.
    }
    if (!mounted) return;
    setState(() {
      _finished = true;
      _bestScore = best;
    });
  }

  void _restartRound() {
    HapticFeedback.selectionClick();
    setState(() {
      _round = widget.questions != null && widget.questions!.isNotEmpty
          ? List<SafetyQuizQuestion>.from(widget.questions!)
          : pickQuizRound(count: 5);
      _index = 0;
      _selectedOption = null;
      _score = 0;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _finished ? _buildSummary(context) : _buildQuestion(context),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final q = _round[_index];
    final total = _round.length;
    final answered = _selectedOption != null;
    final relatedGuide =
        q.relatedGuideId == null ? null : guideById(q.relatedGuideId!);

    return ListView(
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
                tr('Safety & Dosing Sense'),
                style: display(26),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              tr('Question {0} of {1}', [_index + 1, total]),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Pastel.mist.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
        gap(10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (_index + 1) / total,
            minHeight: 6,
            color: C.aurora,
            backgroundColor: C.lavender.withValues(alpha: 0.14),
          ),
        ),
        gap(18),
        AppCard(
          highlight: true,
          padding: const EdgeInsets.all(18),
          child: Text(
            q.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
        gap(14),
        for (var i = 0; i < q.options.length; i++) ...[
          _OptionTile(
            label: q.options[i],
            answered: answered,
            isSelected: _selectedOption == i,
            isCorrect: i == q.correctIndex,
            onTap: () => _chooseOption(i),
          ),
          if (i < q.options.length - 1) gap(10),
        ],
        if (answered) ...[
          gap(16),
          _ExplanationBox(
            isRight: _selectedOption == q.correctIndex,
            explanation: q.explanation,
            guide: relatedGuide,
            onOpenGuide: relatedGuide == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ArticlePage(article: relatedGuide),
                      ),
                    );
                  },
          ),
          gap(16),
          pillButton(
            _index + 1 < total ? tr('Next question') : tr('See summary'),
            _next,
            icon: LucideIcons.chevronRight,
            color: C.aurora,
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final total = _round.length;
    final String heading;
    final String note;
    if (_score == total) {
      heading = tr('Great safety instincts!');
      note = tr(
          'You nailed every safety and dosing check this round. Keep carrying that calm confidence.');
    } else if (_score >= 3) {
      heading = tr('Solid awareness!');
      note = tr(
          'You have a strong grasp of the essentials. Revisit any explanation or guide anytime you want a refresher.');
    } else {
      heading = tr('Every practice builds confidence');
      note = tr(
          'No pressure at all—these calculations and timing rules take a little practice. The guides are always right here offline.');
    }

    return ListView(
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
                tr('Round Complete'),
                style: display(30),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        gap(20),
        AppCard(
          highlight: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              iconBadge(LucideIcons.shieldCheck, Pastel.mint,
                  size: 56, iconSize: 28),
              gap(14),
              Text(
                '$_score / $total',
                style: display(44, color: Colors.white),
              ),
              if (_bestScore != null) ...[
                gap(4),
                Text(
                  tr('Personal best: {0}/5', [_bestScore!]),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: C.lavender,
                  ),
                ),
              ],
              gap(14),
              Text(
                heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              gap(8),
              Text(
                note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Pastel.mist.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        gap(20),
        pillButton(
          tr('Play another round'),
          _restartRound,
          icon: LucideIcons.rotateCcw,
          color: C.aurora,
        ),
        gap(10),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: C.lavender,
            side: BorderSide(color: C.lavender.withValues(alpha: 0.30)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(tr('Back to Sanctuary')),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.answered,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  final String label;
  final bool answered;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color border = C.lavender.withValues(alpha: 0.18);
    Color fill = C.deepCard.withValues(alpha: 0.88);
    IconData? trailing;
    Color trailingColor = Pastel.mint;

    if (answered) {
      if (isCorrect) {
        border = Pastel.mint.withValues(alpha: 0.72);
        fill = Pastel.mint.withValues(alpha: 0.12);
        trailing = LucideIcons.check;
        trailingColor = Pastel.mint;
      } else if (isSelected) {
        border = C.coral.withValues(alpha: 0.72);
        fill = C.coral.withValues(alpha: 0.12);
        trailing = LucideIcons.info;
        trailingColor = C.coral;
      }
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: border, width: answered && (isCorrect || isSelected) ? 1.3 : 1.0),
    );

    return Material(
      color: fill,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: answered ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(
                      alpha: answered && !isCorrect && !isSelected ? 0.65 : 1.0,
                    ),
                    height: 1.35,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                Icon(trailing, size: 18, color: trailingColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  const _ExplanationBox({
    required this.isRight,
    required this.explanation,
    required this.guide,
    required this.onOpenGuide,
  });

  final bool isRight;
  final String explanation;
  final GuideArticle? guide;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final accent = isRight ? Pastel.mint : C.coral;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRight ? tr('Nice work!') : tr('Good to know'),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          gap(6),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 13.5,
              color: Pastel.mist.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          if (guide != null && onOpenGuide != null) ...[
            gap(8),
            TextButton.icon(
              onPressed: onOpenGuide,
              icon: const Icon(LucideIcons.bookOpen, size: 16),
              label: Text(tr('Read related guide')),
              style: TextButton.styleFrom(
                foregroundColor: C.lavender,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
