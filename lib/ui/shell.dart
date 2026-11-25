import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n.dart';
import '../lock.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import '../update_checker.dart';
import '../widget_sync.dart';
import 'calendar.dart';
import 'home.dart';
import 'levels.dart';
import 'more.dart';
import 'responsive.dart';
import 'sanctuary/workout_page.dart';
import 'sheets.dart';
import 'supplies.dart';

class _NavDest {
  const _NavDest(this.tabIndex, this.icon, this.labelKey, this.shortcutHint);
  final int tabIndex;
  final IconData icon;
  final String labelKey;
  final String shortcutHint;
}

const List<_NavDest> _compactNavOrder = [
  _NavDest(0, LucideIcons.activity, 'Levels', 'Alt+2'),
  _NavDest(1, LucideIcons.calendar, 'Calendar', 'Alt+3'),
  _NavDest(2, LucideIcons.house, 'Home', 'Alt+1'),
  _NavDest(3, LucideIcons.package, 'Supplies', 'Alt+4'),
  _NavDest(4, LucideIcons.layoutGrid, 'More', 'Alt+5'),
];

const List<_NavDest> _wideNavOrder = [
  _NavDest(2, LucideIcons.house, 'Home', 'Alt+1'),
  _NavDest(0, LucideIcons.activity, 'Levels', 'Alt+2'),
  _NavDest(1, LucideIcons.calendar, 'Calendar', 'Alt+3'),
  _NavDest(3, LucideIcons.package, 'Supplies', 'Alt+4'),
  _NavDest(4, LucideIcons.layoutGrid, 'More', 'Alt+5'),
];

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  final GlobalKey _stackKey = GlobalKey();
  bool _openingQuickDose = false;
  bool _openingWorkoutWidget = false;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    AppNotifier.pendingQuickDose.addListener(_onQuickDosePending);
    WidgetSync.pendingWorkoutAction.addListener(_onWorkoutActionPending);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
        _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
      } catch (_) {}
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppNotifier.instance.supported) {
        final prefs = ref.read(prefsProvider).value;
        if (prefs == null || prefs.notify) {
          AppNotifier.instance.requestPermission();
        }
      }
      _tryOpenQuickDose();
      _tryOpenWorkoutWidget();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && (!Lock.instance.state.value.enabled || Lock.instance.sessionUnlocked)) {
          UpdateCheckerService.checkAndNotify(ref, context: context);
        }
      });
    });
  }

  @override
  void dispose() {
    AppNotifier.pendingQuickDose.removeListener(_onQuickDosePending);
    WidgetSync.pendingWorkoutAction.removeListener(_onWorkoutActionPending);
    _widgetClickSub?.cancel();
    super.dispose();
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || uri.host != 'workout') return;
    final action = uri.path == '/start' ? 'start' : 'coach';
    WidgetSync.pendingWorkoutAction.value = action;
  }

  void _onWorkoutActionPending() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpenWorkoutWidget());
  }

  Future<void> _tryOpenWorkoutWidget() async {
    if (!mounted || _openingWorkoutWidget) return;
    final action = WidgetSync.pendingWorkoutAction.value;
    if (action == null) return;
    WidgetSync.pendingWorkoutAction.value = null;
    _openingWorkoutWidget = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkoutCoachPage(autoStartToday: action == 'start'),
        ),
      );
    } finally {
      _openingWorkoutWidget = false;
    }
  }

  void _onQuickDosePending() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpenQuickDose());
  }

  Future<void> _tryOpenQuickDose() async {
    if (!mounted || _openingQuickDose) return;
    final pending = AppNotifier.pendingQuickDose.value;
    if (pending == null) return;

    final ths = ref.read(therapiesProvider).value;
    final logs = ref.read(logsProvider).value;
    final supplies = ref.read(suppliesProvider).value;
    final prefs = ref.read(prefsProvider).value;
    if (ths == null || logs == null || supplies == null || prefs == null) {
      return;
    }

    AppNotifier.pendingQuickDose.value = null;
    final therapy = ths.where((t) => t.id == pending.$1).firstOrNull;
    if (therapy == null) return;

    final slots = buildSlots([therapy], logs, prefs, back: 3, ahead: 2);
    final matchingSlot = slots
        .where((s) => slotKey(s.at) == pending.$2 && s.pending)
        .firstOrNull;
    final descLogs = [...logs]..sort((a, b) => b.at.compareTo(a.at));
    final suggested =
        therapy.adm.places ? suggestPlace(prefs, descLogs, therapy.id) : '';

    _openingQuickDose = true;
    try {
      await showSheet(
        context,
        DoseSheet(
          t: therapy,
          slot: matchingSlot,
          supplies: supplies,
          prefs: prefs,
          suggested: suggested,
        ),
      );
    } finally {
      _openingQuickDose = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notifySyncProvider); // jadwalkan ulang pengingat saat data berubah
    ref.watch(widgetSyncProvider); // perbarui widget layar utama
    ref.listen<AsyncValue<List<Therapy>>>(
      therapiesProvider,
      (_, __) => _tryOpenQuickDose(),
    );
    final i = ref.watch(tabProvider);
    final sizeClass = context.windowSizeClass;

    void selectTab(int k) {
      if (k != i) {
        HapticFeedback.selectionClick();
        ref.read(tabProvider.notifier).state = k;
      }
    }

    void openAddTherapy() {
      HapticFeedback.lightImpact();
      final supplies = ref.read(suppliesProvider).value ?? const <Supply>[];
      showSheet(context, TherapySheet(supplies: supplies));
    }

    final pageStack = SafeArea(
      bottom: sizeClass != WindowSizeClass.compact,
      child: KeyedSubtree(
        key: _stackKey,
        child: IndexedStack(
          index: i,
          children: const [
            LevelsPage(),
            CalendarPage(),
            HomePage(),
            SuppliesPage(),
            MorePage(),
          ],
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
            selectTab(2),
        const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
            selectTab(0),
        const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () =>
            selectTab(1),
        const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () =>
            selectTab(3),
        const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () =>
            selectTab(4),
      },
      child: Focus(
        autofocus: false,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (i != 2) {
              ref.read(tabProvider.notifier).state = 2;
              return;
            }
            final shouldExit = await _showExitDialog(context);
            if (shouldExit && context.mounted) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: switch (sizeClass) {
              WindowSizeClass.compact => Column(
                  children: [
                    Expanded(child: pageStack),
                    _CompactBottomNav(
                      key: const ValueKey('nav_bottom'),
                      currentIndex: i,
                      onTap: selectTab,
                    ),
                  ],
                ),
              WindowSizeClass.medium => Row(
                  children: [
                    _NavigationRailChrome(
                      key: const ValueKey('nav_rail'),
                      currentIndex: i,
                      onTap: selectTab,
                    ),
                    Expanded(child: pageStack),
                  ],
                ),
              WindowSizeClass.expanded => Row(
                  children: [
                    _DesktopSidebarChrome(
                      key: const ValueKey('nav_sidebar'),
                      currentIndex: i,
                      onTap: selectTab,
                      onAddTherapy: openAddTherapy,
                    ),
                    Expanded(child: pageStack),
                  ],
                ),
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted widgets
// ---------------------------------------------------------------------------

Future<bool> _showExitDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => const _ExitDialog(),
  ) ?? false;
}

class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
          decoration: BoxDecoration(
            color: C.deepCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: C.lavender.withValues(alpha: dark ? 0.28 : 0.20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? C.voidBg : Colors.black12).withValues(alpha: 0.50),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
              if (dark)
                BoxShadow(
                  color: C.aurora.withValues(alpha: 0.16),
                  blurRadius: 28,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Soft Ambient Emblem
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      C.aurora.withValues(alpha: 0.28),
                      C.magenta.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: C.lavender.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: C.aurora.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.power,
                    color: dark ? C.coral : C.aurora,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Title
              Text(
                tr('Exit {0}?', [appName]),
                textAlign: TextAlign.center,
                style: display(24, color: dark ? Colors.white : C.midnight),
              ),
              const SizedBox(height: 10),
              // Subtitle
              Text(
                tr('Are you sure you want to exit the application?'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: (dark ? C.mist : C.midnight).withValues(alpha: 0.80),
                ),
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: dark ? C.nebula.withValues(alpha: 0.42) : Colors.grey.shade50,
                        side: BorderSide(
                          color: (dark ? C.lavender : C.midnight).withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        tr('Cancel'),
                        style: TextStyle(
                          color: dark ? C.mist : C.midnight,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: Text(
                        tr('Exit'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: C.aurora,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: C.aurora.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBottomNav extends StatelessWidget {
  const _CompactBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final i = currentIndex;
    final animDur = context.animDuration(const Duration(milliseconds: 200));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.screenWidth < 360 ? 10 : 16,
          4,
          context.screenWidth < 360 ? 10 : 16,
          8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: C.midnight.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: C.lavender.withValues(alpha: 0.20),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: C.voidBg.withValues(alpha: 0.56),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (final dest in _compactNavOrder)
                Expanded(
                  child: _CompactNavTile(
                    dest: dest,
                    selected: i == dest.tabIndex,
                    isCenterHome: dest.tabIndex == 2,
                    duration: animDur,
                    onTap: () => onTap(dest.tabIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactNavTile extends StatelessWidget {
  const _CompactNavTile({
    required this.dest,
    required this.selected,
    required this.isCenterHome,
    required this.duration,
    required this.onTap,
  });

  final _NavDest dest;
  final bool selected;
  final bool isCenterHome;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = tr(dest.labelKey);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          hoverColor: C.lavender.withValues(alpha: 0.06),
          focusColor: C.violet.withValues(alpha: 0.16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: isCenterHome ? 44 : 46,
                    height: isCenterHome ? 34 : 30,
                    decoration: BoxDecoration(
                      shape: isCenterHome ? BoxShape.rectangle : BoxShape.rectangle,
                      gradient: selected && isCenterHome
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [C.aurora, C.magenta],
                            )
                          : null,
                      color: selected && !isCenterHome
                          ? C.aurora.withValues(alpha: 0.22)
                          : (!selected && isCenterHome
                              ? C.deepCard.withValues(alpha: 0.85)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(isCenterHome ? 17 : 15),
                      border: selected
                          ? Border.all(
                              color: isCenterHome
                                  ? C.lavender.withValues(alpha: 0.50)
                                  : C.violet.withValues(alpha: 0.45),
                              width: 1.0,
                            )
                          : (isCenterHome
                              ? Border.all(
                                  color: C.lavender.withValues(alpha: 0.18),
                                  width: 1.0,
                                )
                              : null),
                    ),
                    child: Center(
                      child: Icon(
                        dest.icon,
                        size: isCenterHome ? 21 : 20,
                        color: selected
                            ? (isCenterHome ? Colors.white : C.iconActive)
                            : C.iconDefault,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? C.iconActive : C.iconDefault,
                        letterSpacing: 0.1,
                      ),
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

class _NavigationRailChrome extends StatelessWidget {
  const _NavigationRailChrome({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final animDur = context.animDuration(const Duration(milliseconds: 200));

    return SafeArea(
      right: false,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: C.midnight.withValues(alpha: 0.94),
          border: Border(
            right: BorderSide(
              color: C.lavender.withValues(alpha: 0.14),
              width: 1.0,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            const MoonLogo(size: 32),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final dest in _wideNavOrder) ...[
                      _RailDestinationTile(
                        dest: dest,
                        selected: currentIndex == dest.tabIndex,
                        duration: animDur,
                        onTap: () => onTap(dest.tabIndex),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailDestinationTile extends StatelessWidget {
  const _RailDestinationTile({
    required this.dest,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final _NavDest dest;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = tr(dest.labelKey);
    return Tooltip(
      message: '$label (${dest.shortcutHint})',
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            hoverColor: C.lavender.withValues(alpha: 0.06),
            focusColor: C.violet.withValues(alpha: 0.16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? C.aurora.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: selected
                      ? Border.all(
                          color: C.violet.withValues(alpha: 0.45),
                          width: 1.0,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dest.icon,
                      size: 21,
                      color: selected ? C.iconActive : C.iconDefault,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? C.iconActive : C.iconDefault,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebarChrome extends StatelessWidget {
  const _DesktopSidebarChrome({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTherapy,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTherapy;

  @override
  Widget build(BuildContext context) {
    final animDur = context.animDuration(const Duration(milliseconds: 200));

    return SafeArea(
      right: false,
      child: Container(
        width: 244,
        decoration: BoxDecoration(
          color: C.midnight.withValues(alpha: 0.94),
          border: Border(
            right: BorderSide(
              color: C.lavender.withValues(alpha: 0.14),
              width: 1.0,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(height: 30),
                  const SizedBox(height: 6),
                  Text(
                    tr(tagline),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Pastel.mist.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final dest in _wideNavOrder) ...[
                      _SidebarDestinationTile(
                        dest: dest,
                        selected: currentIndex == dest.tabIndex,
                        duration: animDur,
                        onTap: () => onTap(dest.tabIndex),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: C.lavender.withValues(alpha: 0.14), height: 1),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAddTherapy,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                tr('Add therapy'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.lavender,
                backgroundColor: C.deepCard.withValues(alpha: 0.75),
                side: BorderSide(color: C.lavender.withValues(alpha: 0.24)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alt+1–5',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: C.iconDefault.withValues(alpha: 0.65),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarDestinationTile extends StatelessWidget {
  const _SidebarDestinationTile({
    required this.dest,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final _NavDest dest;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = tr(dest.labelKey);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          hoverColor: C.lavender.withValues(alpha: 0.06),
          focusColor: C.violet.withValues(alpha: 0.16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? C.aurora.withValues(alpha: 0.20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? C.violet.withValues(alpha: 0.45)
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: duration,
                    width: 3,
                    height: selected ? 18 : 0,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected ? C.lavender : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Icon(
                    dest.icon,
                    size: 20,
                    color: selected ? C.iconActive : C.iconDefault,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : C.mist.withValues(alpha: 0.85),
                      ),
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
