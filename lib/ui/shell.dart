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
import 'sanctuary/workout_page.dart';
import 'sheets.dart';
import 'supplies.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
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

    return PopScope(
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
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
              ),
              _NavBar(
                currentIndex: i,
                onTap: (k) {
                  if (k != i) {
                    HapticFeedback.selectionClick();
                  }
                  ref.read(tabProvider.notifier).state = k;
                },
              ),
            ]),
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

class _NavBar extends StatelessWidget {
  const _NavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (LucideIcons.activity, 'Levels'),
    (LucideIcons.calendar, 'Calendar'),
    (LucideIcons.house, 'Home'),
    (LucideIcons.package, 'Supplies'),
    (LucideIcons.layoutGrid, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final i = currentIndex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Container(
          decoration: BoxDecoration(
            color: C.midnight.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: C.lavender.withValues(alpha: 0.24),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: C.voidBg.withValues(alpha: 0.60),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: C.aurora.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              for (var k = 0; k < _items.length; k++)
                if (k == 2)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == k,
                      label: tr(_items[k].$2),
                      child: InkResponse(
                        onTap: () => onTap(k),
                        radius: 36,
                        child: Transform.translate(
                          offset: const Offset(0, -8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: i == k ? 1.06 : 0.96,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: i == k
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [C.aurora, C.nebula],
                                          )
                                        : null,
                                    color: i == k ? null : C.deepCard,
                                    border: Border.all(
                                      color: i == k
                                          ? C.iconActive.withValues(alpha: 0.65)
                                          : C.iconDefault.withValues(alpha: 0.28),
                                      width: 1.2,
                                    ),
                                    boxShadow: i == k
                                        ? [
                                            BoxShadow(
                                              color: C.aurora.withValues(alpha: 0.42),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _items[k].$1,
                                      size: 24,
                                      color: i == k ? C.iconActive : C.iconDefault,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr(_items[k].$2),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: i == k ? FontWeight.w800 : FontWeight.w600,
                                  color: i == k ? C.iconActive : C.iconDefault,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == k,
                      label: tr(_items[k].$2),
                      child: InkResponse(
                        onTap: () => onTap(k),
                        radius: 32,
                        highlightShape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  width: 48,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: i == k ? C.aurora.withValues(alpha: 0.24) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: i == k
                                        ? Border.all(color: C.violet.withValues(alpha: 0.50), width: 1.0)
                                        : null,
                                    boxShadow: i == k
                                        ? [
                                            BoxShadow(
                                              color: C.aurora.withValues(alpha: 0.22),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _items[k].$1,
                                      size: 22,
                                      color: i == k ? C.iconActive : C.iconDefault,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr(_items[k].$2),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: i == k ? FontWeight.w700 : FontWeight.w500,
                                    color: i == k ? C.iconActive : C.iconDefault,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
