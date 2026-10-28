import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications.dart';
import '../repo.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'home.dart';
import 'journal_page.dart';
import 'levels.dart';
import 'timeline_page.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});
  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int i = 0;
  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.calendar_month_rounded, 'Timeline'),
    (Icons.insights_rounded, 'Insights'),
    (Icons.auto_stories_rounded, 'Journal'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
            color: C.lagoon.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.exit_to_app_rounded,
            color: C.lagoon,
            size: 32,
          ),
        ),
        title: Text(
          'Exit Lunera?',
          textAlign: TextAlign.center,
          style: display(20, color: dark ? Colors.white : C.midnight, weight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to close the application?',
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
              'Cancel',
              style: TextStyle(
                color: dark ? Colors.white70 : C.midnight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: C.lagoon,
              foregroundColor: C.midnight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontWeight: FontWeight.w700),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barColor = dark ? C.deepCard : Colors.white;
    final fgColor = Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (i != 0) {
          setState(() => i = 0);
          return;
        }
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: IndexedStack(
            index: i,
            children: const [
              HomePage(),
              TimelinePage(),
              LevelsPage(),
              JournalPage(),
            ],
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: dark ? .4 : .08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var k = 0; k < _items.length; k++)
                        GestureDetector(
                          onTap: () => setState(() => i = k),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(horizontal: i == k ? 16 : 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: i == k ? C.lavender : Colors.transparent,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _items[k].$1,
                                  size: 20,
                                  color: i == k ? C.midnight : fgColor.withValues(alpha: .6),
                                ),
                                if (i == k) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _items[k].$2,
                                    style: const TextStyle(
                                      color: C.midnight,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
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
      ]),
    ),
  );
}
}
