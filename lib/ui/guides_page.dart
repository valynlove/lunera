import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guides_data.dart';
import '../l10n.dart';
import '../theme.dart';
import 'article_page.dart';
import 'companion_avatar.dart';

const _kGuidesReadKey = 'guides.read_ids';

/// Curated offline-first Care & HRT Guides library with direct shortcut cards.
class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key, this.initialCategory});

  final GuideCategory? initialCategory;

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> {
  late GuideCategory? _filter = widget.initialCategory;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Set<String> _readIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadReadIds();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesQuery(GuideArticle a, String q) {
    if (a.title.toLowerCase().contains(q) ||
        a.subtitle.toLowerCase().contains(q) ||
        a.category.label.toLowerCase().contains(q)) {
      return true;
    }
    for (final s in a.sections) {
      if (s.heading.toLowerCase().contains(q) ||
          s.paragraphs.any((p) => p.toLowerCase().contains(q)) ||
          s.bullets.any((b) => b.toLowerCase().contains(q))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kGuidesReadKey) ?? const <String>[];
      if (!mounted) return;
      setState(() => _readIds = list.toSet());
    } catch (_) {
      // Non-critical visual indicator; ignore storage read errors.
    }
  }

  Future<void> _openArticle(GuideArticle article) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArticlePage(article: article)),
    );
    await _loadReadIds();
  }

  @override
  Widget build(BuildContext context) {
    final startArticle = guideArticles.where((a) => a.isStartHere).firstOrNull;
    final q = _query.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;
    final showPinnedStart = !hasQuery && _filter == null && startArticle != null;

    final filtered = [
      for (final a in guideArticles)
        if ((hasQuery || (_filter == null ? !a.isStartHere : a.category == _filter)) &&
            (_filter == null || a.category == _filter) &&
            (!hasQuery || _matchesQuery(a, q)))
          a,
    ];

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
                    tr('Care & HRT Guides'),
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
                    mood: CompanionMood.explain,
                    size: 74,
                    glowColor: C.lavender,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('Calm, evidence-informed guides for every path — whether doctor-guided or independent.'),
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
            gap(14),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: tr('Search guides, topics, or keywords...'),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: hasQuery
                    ? IconButton(
                        tooltip: tr('Clear search'),
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
            gap(12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: tr('All'),
                    selected: _filter == null,
                    color: C.lavender,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final cat in GuideCategory.values) ...[
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: cat.shortLabel,
                      selected: _filter == cat,
                      color: cat.color,
                      onTap: () => setState(() => _filter = cat),
                    ),
                  ],
                ],
              ),
            ),
            if (showPinnedStart) ...[
              gap(16),
              _StartHereCard(
                article: startArticle,
                isRead: _readIds.contains(startArticle.id),
                onTap: () => _openArticle(startArticle),
              ),
            ],
            gap(16),
            if (filtered.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CompanionAvatar(
                      mood: CompanionMood.confused,
                      size: 76,
                      glowColor: C.lavender,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tr('No guides match your search.'),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Pastel.mist.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
              builder: (context, constraints) {
                final twoCols = constraints.maxWidth >= 720;
                if (!twoCols) {
                  return Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        _GuideShortcutCard(
                          article: filtered[i],
                          isRead: _readIds.contains(filtered[i].id),
                          onTap: () => _openArticle(filtered[i]),
                        ),
                        if (i < filtered.length - 1) gap(12),
                      ],
                    ],
                  );
                }
                const spacing = 12.0;
                final cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final article in filtered)
                      SizedBox(
                        width: cardWidth,
                        child: _GuideShortcutCard(
                          article: article,
                          isRead: _readIds.contains(article.id),
                          onTap: () => _openArticle(article),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : Pastel.mist.withValues(alpha: 0.85),
      ),
      selectedColor: color.withValues(alpha: 0.28),
      backgroundColor: C.deepCard.withValues(alpha: 0.82),
      side: BorderSide(
        color: selected
            ? color.withValues(alpha: 0.65)
            : C.lavender.withValues(alpha: 0.16),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

class _StartHereCard extends StatelessWidget {
  const _StartHereCard({
    required this.article,
    required this.isRead,
    required this.onTap,
  });

  final GuideArticle article;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: C.coral.withValues(alpha: 0.45), width: 1.2),
    );

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            C.nebula.withValues(alpha: 0.94),
            C.deepCard.withValues(alpha: 0.96),
          ],
        ),
        shape: shape,
        shadows: [
          BoxShadow(
            color: C.coral.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: C.coral.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: C.coral.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.compass,
                              size: 13, color: C.coral),
                          const SizedBox(width: 5),
                          Text(
                            tr('Start here'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: C.coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tr('{0} min read', [article.readMinutes]),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRead) ...[
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.check,
                          size: 15, color: Pastel.mint),
                    ],
                  ],
                ),
                gap(12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          gap(4),
                          Text(
                            article.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Pastel.mist.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: C.iconActive,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideShortcutCard extends StatelessWidget {
  const _GuideShortcutCard({
    required this.article,
    required this.isRead,
    required this.onTap,
  });

  final GuideArticle article;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = article.category.color;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconBadge(article.icon, accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                gap(4),
                Text(
                  article.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Pastel.mist.withValues(alpha: 0.82),
                    height: 1.3,
                  ),
                ),
                gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        article.category.shortLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                    Text(
                      tr('{0} min read', [article.readMinutes]),
                      style: TextStyle(
                        fontSize: 11,
                        color: Pastel.mist.withValues(alpha: 0.72),
                      ),
                    ),
                    if (isRead)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check,
                              size: 13, color: Pastel.mint),
                          const SizedBox(width: 3),
                          Text(
                            tr('Read'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Pastel.mint,
                            ),
                          ),
                        ],
                      ),
                  ],
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
