import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../theme.dart';

/// Window-first responsive breakpoints following Material 3 & HIG adaptive layout classes.
enum WindowSizeClass { compact, medium, expanded }

const double kCompactMaxWidth = 600.0;
const double kMediumMaxWidth = 840.0;
const double kSplitMinWidth = 880.0;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  WindowSizeClass get windowSizeClass {
    final w = screenWidth;
    if (w < kCompactMaxWidth) return WindowSizeClass.compact;
    if (w < kMediumMaxWidth) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  bool get isCompact => windowSizeClass == WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;
  bool get isWide => screenWidth >= kCompactMaxWidth;

  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  Duration animDuration(Duration normal) =>
      reduceMotion ? Duration.zero : normal;

  double get pagePaddingH {
    final w = screenWidth;
    if (w < 360) return 16;
    if (w < kCompactMaxWidth) return 20;
    if (w < kMediumMaxWidth) return 24;
    return 32;
  }

  EdgeInsets pagePadding({double top = 16, double bottom = 32}) {
    final h = pagePaddingH;
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }

  double get maxContentWidth {
    switch (windowSizeClass) {
      case WindowSizeClass.compact:
        return double.infinity;
      case WindowSizeClass.medium:
        return 960;
      case WindowSizeClass.expanded:
        return 1180;
    }
  }
}

/// Centers content cleanly on medium and expanded windows while staying edge-to-edge on phones.
class AdaptivePageFrame extends StatelessWidget {
  const AdaptivePageFrame({
    super.key,
    required this.child,
    this.maxWidth,
    this.reading = false,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final bool reading;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedMax =
        maxWidth ?? (reading ? 760.0 : context.maxContentWidth);
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMax),
        child: content,
      ),
    );
  }
}

/// Responsive grid built from Column + Rows so dynamic-height cards reflow cleanly at large text sizes.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 1,
    this.mediumColumns = 2,
    this.expandedColumns = 2,
    this.spacing = 14,
    this.runSpacing = 14,
    this.minColumnWidth = 280,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final double spacing;
  final double runSpacing;
  final double minColumnWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desired = switch (context.windowSizeClass) {
          WindowSizeClass.compact => compactColumns,
          WindowSizeClass.medium => mediumColumns,
          WindowSizeClass.expanded => expandedColumns,
        };
        final maxFitting =
            ((width + spacing) / (minColumnWidth + spacing)).floor().clamp(1, 6);
        final cols = desired.clamp(1, maxFitting).clamp(1, children.length);

        if (cols <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final rowChildren = <Widget>[];
          for (var c = 0; c < cols; c++) {
            if (c > 0) rowChildren.add(SizedBox(width: spacing));
            final idx = i + c;
            rowChildren.add(
              Expanded(
                child: idx < children.length
                    ? children[idx]
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Two-pane split on wide canvases that gracefully stacks into a single column when narrow.
class AdaptiveSplitView extends StatelessWidget {
  const AdaptiveSplitView({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 7,
    this.secondaryFlex = 5,
    this.gap = 24,
    this.minWidth = kSplitMinWidth,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double gap;
  final double minWidth;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Expanded(flex: primaryFlex, child: primary),
              SizedBox(width: gap),
              Expanded(flex: secondaryFlex, child: secondary),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            SizedBox(height: gap * 0.75),
            secondary,
          ],
        );
      },
    );
  }
}

/// Consistent page header with semantic heading, 48x48 back button, and responsive trailing actions.
class AdaptivePageHeader extends StatelessWidget {
  const AdaptivePageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final titleWidget = Semantics(
      header: true,
      child: Text(
        title,
        style: display(
          compact ? 32 : 36,
          color: Colors.white,
          weight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null) ...[
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onBack!();
                },
                icon: const Icon(LucideIcons.arrowLeft),
                tooltip: tr('Back'),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(child: titleWidget),
            if (actions.isNotEmpty && !compact) ...[
              const SizedBox(width: 12),
              Flexible(
                flex: 0,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
        if (actions.isNotEmpty && compact) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          subtitle!,
        ],
      ],
    );
  }
}
