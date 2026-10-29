import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n.dart';
import '../lock.dart';
import '../notifications.dart';
import '../repo.dart';
import '../theme.dart';
import '../update_checker.dart';
import '../widget_sync.dart';
import 'calendar.dart';
import 'home.dart';
import 'levels.dart';
import 'more.dart';
import 'supplies.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar'),
    (Icons.show_chart_rounded, Icons.show_chart_rounded, 'Levels'),
    (Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Supplies'),
    (Icons.grid_view_rounded, Icons.grid_view_outlined, 'More'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(userProvider).value?.uid;
      if (uid != null) {
        Lock.instance.syncWithCloud(uid);
      }
      if (AppNotifier.instance.supported) {
        final prefs = ref.read(prefsProvider).value;
        if (prefs == null || prefs.notify) {
          AppNotifier.instance.requestPermission();
        }
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          UpdateCheckerService.checkAndPromptUpdate(context, silentIfUpToDate: true);
        }
      });
    });
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? C.deepCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.peony.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.exit_to_app_rounded,
            color: C.peony,
            size: 32,
          ),
        ),
        title: Text(
          context.tr('Exit {name}?', {'name': appName}),
          textAlign: TextAlign.center,
          style: display(20, color: dark ? Colors.white : C.midnight, weight: FontWeight.w700),
        ),
        content: Text(
          context.tr('Are you sure you want to exit the application?'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: (dark ? Colors.white : C.midnight).withValues(alpha: 0.75),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              side: BorderSide(color: (dark ? Colors.white : C.midnight).withValues(alpha: 0.2)),
            ),
            child: Text(
              context.tr('Cancel'),
              style: TextStyle(
                color: dark ? Colors.white70 : C.midnight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: C.peony,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            ),
            child: Text(
              context.tr('Exit'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notifySyncProvider); // jadwalkan ulang pengingat saat data berubah
    ref.watch(widgetSyncProvider); // perbarui widget layar utama
    final i = ref.watch(tabProvider);
    final theme = Theme.of(context), dark = theme.brightness == Brightness.dark;
    final fg = theme.colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (i != 0) {
          ref.read(tabProvider.notifier).state = 0;
          return;
        }
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Column(children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: i,
                children: const [HomePage(), CalendarPage(), LevelsPage(), SuppliesPage(), MorePage()],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: dark ? Border(top: BorderSide(color: Colors.white.withValues(alpha: .07))) : null,
              boxShadow: dark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF6B5CE0).withValues(alpha: .10),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Row(children: [
                  for (var k = 0; k < _items.length; k++)
                    Expanded(
                      child: InkResponse(
                        onTap: () => ref.read(tabProvider.notifier).state = k,
                        radius: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 30,
                              decoration: BoxDecoration(
                                color: i == k ? C.peony.withValues(alpha: .16) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                i == k ? _items[k].$1 : _items[k].$2,
                                size: 24,
                                color: i == k ? C.peony : fg.withValues(alpha: .6),
                              ),
                            ),
                            gap(2),
                            Text(
                              context.tr(_items[k].$3),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == k ? FontWeight.w700 : FontWeight.w500,
                                color: i == k ? C.peony : fg.withValues(alpha: .6),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
