import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications.dart';
import '../theme.dart';
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
  Widget build(BuildContext context) {
    ref.watch(notifySyncProvider); // jadwalkan ulang pengingat saat data berubah
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barColor = dark ? C.deepCard : Colors.white;
    final fgColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
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
    );
  }
}
