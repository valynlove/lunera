import 'package:flutter/material.dart' show Color, IconData;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'l10n.dart';
import 'theme.dart';

part 'guides/guides_basics.dart';
part 'guides/guides_labs_safety.dart';
part 'guides/guides_care.dart';

/// Top-level educational pillars for Lunera's Care & HRT Guides.
enum GuideCategory { basics, labs, safety, care }

extension GuideCategoryMeta on GuideCategory {
  String get label {
    switch (this) {
      case GuideCategory.basics:
        return tr('Basics & Regimens');
      case GuideCategory.labs:
        return tr('Labs & Levels');
      case GuideCategory.safety:
        return tr('Safety & Harm Reduction');
      case GuideCategory.care:
        return tr('Body, Mind & Care');
    }
  }

  String get shortLabel {
    switch (this) {
      case GuideCategory.basics:
        return tr('Basics');
      case GuideCategory.labs:
        return tr('Labs');
      case GuideCategory.safety:
        return tr('Safety');
      case GuideCategory.care:
        return tr('Body & Mind');
    }
  }

  IconData get icon {
    switch (this) {
      case GuideCategory.basics:
        return LucideIcons.pill;
      case GuideCategory.labs:
        return LucideIcons.activity;
      case GuideCategory.safety:
        return LucideIcons.shieldCheck;
      case GuideCategory.care:
        return LucideIcons.heartHandshake;
    }
  }

  Color get color {
    switch (this) {
      case GuideCategory.basics:
        return C.lavender;
      case GuideCategory.labs:
        return C.rose;
      case GuideCategory.safety:
        return C.coral;
      case GuideCategory.care:
        return Pastel.mint;
    }
  }
}

/// Visual emphasis style for inline guidance callouts inside an article.
enum GuideCalloutType { tip, warning }

/// Contextual shortcut button shown at the bottom of relevant articles.
enum GuideActionType { none, siteMap, addLab, security, insights }

class GuideCallout {
  const GuideCallout({
    required this.type,
    required this.titleEn,
    required this.titleId,
    required this.bodyEn,
    required this.bodyId,
  });

  final GuideCalloutType type;
  final String titleEn;
  final String titleId;
  final String bodyEn;
  final String bodyId;

  String get title => L10n.code == 'id' ? titleId : titleEn;
  String get body => L10n.code == 'id' ? bodyId : bodyEn;
}

class GuideSection {
  const GuideSection({
    required this.headingEn,
    required this.headingId,
    this.paragraphsEn = const [],
    this.paragraphsId = const [],
    this.bulletsEn = const [],
    this.bulletsId = const [],
    this.callout,
  });

  final String headingEn;
  final String headingId;
  final List<String> paragraphsEn;
  final List<String> paragraphsId;
  final List<String> bulletsEn;
  final List<String> bulletsId;
  final GuideCallout? callout;

  String get heading => L10n.code == 'id' ? headingId : headingEn;
  List<String> get paragraphs =>
      L10n.code == 'id' ? paragraphsId : paragraphsEn;
  List<String> get bullets => L10n.code == 'id' ? bulletsId : bulletsEn;
}

class GuideArticle {
  const GuideArticle({
    required this.id,
    required this.category,
    this.isStartHere = false,
    required this.readMinutes,
    required this.icon,
    required this.titleEn,
    required this.titleId,
    required this.subtitleEn,
    required this.subtitleId,
    required this.takeawaysEn,
    required this.takeawaysId,
    required this.sections,
    required this.references,
    this.action = GuideActionType.none,
  });

  final String id;
  final GuideCategory category;
  final bool isStartHere;
  final int readMinutes;
  final IconData icon;
  final String titleEn;
  final String titleId;
  final String subtitleEn;
  final String subtitleId;
  final List<String> takeawaysEn;
  final List<String> takeawaysId;
  final List<GuideSection> sections;
  final List<String> references;
  final GuideActionType action;

  String get title => L10n.code == 'id' ? titleId : titleEn;
  String get subtitle => L10n.code == 'id' ? subtitleId : subtitleEn;
  List<String> get takeaways => L10n.code == 'id' ? takeawaysId : takeawaysEn;
}

/// Complete offline-first curated Care & HRT Guides library.
const List<GuideArticle> guideArticles = [
  ..._guidesBasics,
  ..._guidesLabsAndSafety,
  ..._guidesCare,
];

/// Returns the matching guide article for [id], or null if not found.
GuideArticle? guideById(String id) {
  for (final article in guideArticles) {
    if (article.id == id) return article;
  }
  return null;
}
