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
          UpdateCheckerService.checkAndNotify(ref, context: context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notifySyncProvider); // jadwalkan ulang pengingat saat data berubah
    ref.watch(widgetSyncProvider); // perbarui widget layar utama
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
        body: Column(children: [
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
            color: dark ? C.deepCard : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFD6B277).withValues(alpha: dark ? 0.38 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? const Color(0xFF060412) : Colors.black12).withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
              if (dark)
                BoxShadow(
                  color: C.peony.withValues(alpha: 0.14),
                  blurRadius: 28,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Celestial Emblem
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      C.peony.withValues(alpha: 0.28),
                      const Color(0xFFF1BA79).withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFD6B277).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: C.peony.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: dark ? const Color(0xFFF1BA79) : C.peony,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Title
              Text(
                tr('Exit {0}?', [appName]),
                textAlign: TextAlign.center,
                style: display(22, color: dark ? Colors.white : C.midnight, weight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              // Subtitle
              Text(
                tr('Are you sure you want to exit the application?'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: (dark ? Colors.white : C.midnight).withValues(alpha: 0.75),
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
                        backgroundColor: dark ? const Color(0xFF282057).withValues(alpha: 0.35) : Colors.grey.shade50,
                        side: BorderSide(
                          color: (dark ? Colors.white : C.midnight).withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        tr('Cancel'),
                        style: TextStyle(
                          color: dark ? Colors.white70 : C.midnight,
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
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: Text(
                        tr('Exit'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: C.peony,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: C.peony.withValues(alpha: 0.5),
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
    ('assets/icons/nav_levels.png', Icons.insights_rounded, 'Levels'),
    ('assets/icons/nav_calendar.png', Icons.calendar_month_rounded, 'Calendar'),
    ('assets/icons/nav_home.png', Icons.auto_awesome_rounded, 'Home'),
    ('assets/icons/nav_supplies.png', Icons.inventory_2_rounded, 'Supplies'),
    ('assets/icons/nav_more.png', Icons.grid_view_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final i = currentIndex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B1544).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFD6B277).withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF070516).withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: C.amber.withValues(alpha: 0.12),
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
                    child: InkResponse(
                      onTap: () => onTap(k),
                      radius: 36,
                      child: Transform.translate(
                        offset: const Offset(0, -8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: i == k ? 1.08 : 0.94,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: i == k
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: C.amber.withValues(alpha: 0.40),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: C.peony.withValues(alpha: 0.28),
                                            blurRadius: 20,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Center(
                                  child: Image.asset(
                                    _items[k].$1,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => CustomPaint(
                                      size: const Size(24, 24),
                                      painter: CompassStarPainter(
                                        color: i == k ? Pastel.cream : C.amber,
                                        glow: i == k,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              tr(_items[k].$3),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: i == k ? FontWeight.w800 : FontWeight.w600,
                                color: i == k ? Pastel.cream : fg.withValues(alpha: .75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: InkResponse(
                      onTap: () => onTap(k),
                      radius: 36,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42,
                              height: 28,
                              decoration: BoxDecoration(
                                color: i == k ? C.peony.withValues(alpha: .22) : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: i == k
                                    ? Border.all(color: const Color(0xFFD6B277).withValues(alpha: .50), width: 1.0)
                                    : null,
                                boxShadow: i == k
                                    ? [
                                        BoxShadow(
                                          color: C.peony.withValues(alpha: .25),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Opacity(
                                  opacity: i == k ? 1.0 : 0.65,
                                  child: Image.asset(
                                    _items[k].$1,
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      _items[k].$2,
                                      size: 20,
                                      color: i == k ? C.peony : fg.withValues(alpha: .6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              tr(_items[k].$3),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: i == k ? FontWeight.w700 : FontWeight.w500,
                                color: i == k ? Pastel.cream : fg.withValues(alpha: .6),
                              ),
                            ),
                          ],
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
