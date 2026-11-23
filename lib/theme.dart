import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n.dart';

const appName = 'Lunera';
const tagline = 'Every Phase, Your Own.';

/// Eternal Dusk color tokens combining Midnight Aurora with Vice City Sunset warmth.
class C {
  static const voidBg = Color(0xFF090817); // Deepest obsidian void
  static const midnight = Color(0xFF11102B); // Primary nocturnal midnight canvas
  static const nebula = Color(0xFF292052); // Elevated cosmic plum surface
  static const aurora = Color(0xFF8065E8); // Primary electric aurora violet
  static const violet = Color(0xFFA58BFF); // Luminous violet highlight
  static const lavender = Color(0xFFC7B8FF); // Soft lavender rim & accent
  static const magenta = Color(0xFFD76ABF); // Dusk sunset magenta
  static const rose = Color(0xFFF09ABF); // Warm twilight rose
  static const coral = Color(0xFFF2A17C); // Horizon sunset coral

  // Semantic & legacy design token aliases mapped cleanly to Eternal Dusk
  static const deepCard = Color(0xFF171436); // Layered dark card surface
  static const surface = deepCard;
  static const ink = voidBg;
  static const deep = midnight;
  static const indigo = nebula;
  static const mist = Color(0xFFECE8FF); // High-contrast lavender-tinted white
  static const amber = coral;
  static const gold = coral;
  static const moonlight = lavender;

  // Functional UI icon tokens (Lucide outline system)
  static const iconDefault = Color(0xFFA29BBE);
  static const iconActive = lavender; // #C7B8FF
  static const iconHighlight = aurora; // #8065E8

  static Color lagoon = magenta; // Secondary dusk accent
  static Color peony = aurora; // Primary aurora accent
}

/// Supporting tonal palette for clinical states, badges, and readable dark UI text.
class Pastel {
  static const lilac = C.lavender; // Highlights, active labels, countdowns
  static const rose = C.rose; // Estradiol & warm mood accents
  static const mint = Color(0xFF7DE2C7); // Completed doses, adherence, in-range
  static const sky = C.violet; // Testosterone, telemetry, secondary highlights
  static const butter = C.coral; // Alerts, stock reminders, progesterone
  static const cream = C.lavender; // Subtle editorial trim & luminous captions
  static const mist = C.mist; // High-contrast foreground text
  static const glow = Color(0x338065E8); // Soft aurora ambient glow
}

/// Accent preset metadata (retained for preferences compatibility).
const accents = <String, (String, Color, Color)>{
  'lunera': ('Eternal Dusk (Aurora & Sunset)', C.magenta, C.aurora),
  'rose': ('Twilight Rose & Violet', C.rose, C.aurora),
  'lagoon': ('Violet & Lavender', C.lavender, C.violet),
  'solstice': ('Sunset Coral & Magenta', C.coral, C.magenta),
};

void applyAccent([String? id]) {
  // Locked to the unified Eternal Dusk palette.
  C.lagoon = C.magenta;
  C.peony = C.aurora;
}

/// Hormone series colors aligned with Eternal Dusk data visualization harmony.
Color hormoneColor(String hormoneId) {
  switch (hormoneId.toLowerCase()) {
    case 'progesterone':
    case 'p4':
      return C.coral;
    case 'testosterone':
    case 't':
      return C.violet;
    case 'estradiol':
    case 'e2':
    default:
      return C.rose;
  }
}

TextStyle display(double size, {Color? color, FontWeight? weight}) =>
    GoogleFonts.instrumentSerif(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w400,
      height: 1.12,
      letterSpacing: -size * 0.01,
      color: color,
    );

TextStyle wordmark(double size, {Color? color, FontWeight? weight}) =>
    GoogleFonts.instrumentSerif(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w400,
      letterSpacing: size * 0.08,
      height: 1.05,
      color: color,
    );

ThemeData buildTheme([Brightness b = Brightness.dark]) {
  const fg = C.mist;
  final scheme =
      ColorScheme.fromSeed(seedColor: C.aurora, brightness: Brightness.dark)
          .copyWith(
    primary: C.aurora,
    secondary: C.magenta,
    tertiary: C.coral,
    surface: C.deepCard,
    surfaceContainerHighest: C.nebula,
    onSurface: fg,
    outlineVariant: C.lavender.withValues(alpha: 0.22),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
          fallbackColor: Colors.transparent,
        ),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(
          backgroundColor: Colors.transparent,
        ),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(
          backgroundColor: Colors.transparent,
        ),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(
          backgroundColor: Colors.transparent,
        ),
      },
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: fg, displayColor: fg),
    iconTheme: const IconThemeData(color: C.iconDefault, size: 24),
    primaryIconTheme: const IconThemeData(color: C.iconActive, size: 24),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.midnight.withValues(alpha: 0.78),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: C.lavender.withValues(alpha: 0.16)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: C.lavender.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.violet, width: 1.3),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.deepCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: C.lavender.withValues(alpha: 0.22)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.nebula,
      contentTextStyle: TextStyle(
        color: fg,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// Global Eternal Dusk atmospheric wallpaper, scrim, and subtle overlay.
Widget appBackdrop(BuildContext context, Widget? child) {
  return Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/images/eternal_dusk_bg.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.voidBg, C.midnight, C.nebula],
            ),
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              C.voidBg.withValues(alpha: 0.38),
              C.midnight.withValues(alpha: 0.58),
              C.voidBg.withValues(alpha: 0.82),
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
      ),
      IgnorePointer(
        child: Opacity(
          opacity: 0.18,
          child: Image.asset(
            'assets/images/eternal_dusk_overlay.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
      if (child != null) child,
    ],
  );
}

/// Layered dark card decoration with subtle lavender hairline border and ambient shadow.
BoxDecoration cardBox(BuildContext c, {double radius = 28, bool highlight = false}) {
  final t = Theme.of(c);
  return BoxDecoration(
    color: t.colorScheme.surface.withValues(alpha: 0.90),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: highlight
          ? C.violet.withValues(alpha: 0.55)
          : C.lavender.withValues(alpha: 0.16),
      width: highlight ? 1.2 : 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: (highlight ? C.aurora : C.voidBg)
            .withValues(alpha: highlight ? 0.20 : 0.42),
        blurRadius: highlight ? 22 : 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

Widget pillButton(String label, VoidCallback onTap,
    {IconData? icon, Color? color}) {
  final style = FilledButton.styleFrom(
    backgroundColor: color ?? C.aurora,
    foregroundColor: Colors.white,
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
  return icon == null
      ? FilledButton(onPressed: onTap, style: style, child: Text(label))
      : FilledButton.icon(
          onPressed: onTap,
          style: style,
          icon: Icon(icon, size: 20),
          label: Text(label),
        );
}

/// Pill-shaped tab selector with Eternal Dusk Aurora → Magenta gradient highlight.
class PillTabs<T> extends StatelessWidget {
  const PillTabs(
      {super.key,
      required this.items,
      required this.value,
      required this.onChanged});
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(it.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: it.$1 == value
                      ? const LinearGradient(
                          colors: [C.aurora, C.magenta],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      it.$2,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: it.$1 == value
                            ? Colors.white
                            : fg.withValues(alpha: 0.72),
                      ),
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

/// Eternal Dusk orbital crescent moon emblem.
class MoonLogo extends StatelessWidget {
  const MoonLogo({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/images/eternal_dusk_emblem.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => CustomPaint(painter: _MoonPainter()),
        ),
      );
}

class MoonLogoSmall extends StatelessWidget {
  const MoonLogoSmall({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: C.deepCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.lavender.withValues(alpha: 0.28)),
        ),
        child: const MoonLogo(size: 28),
      );
}

/// Primary horizontal Eternal Dusk wordmark + crescent emblem lockup.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 44});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Image.asset(
          'assets/images/eternal_dusk_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoonLogo(size: height * 0.9),
              const SizedBox(width: 10),
              Text(appName, style: wordmark(height * 0.65, color: C.mist)),
            ],
          ),
        ),
      );
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48);
    final paint = Paint()..color = C.lavender;
    final ring = Paint()
      ..color = C.coral.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final orbit = Rect.fromCenter(center: Offset.zero, width: 44, height: 12);
    canvas.save();
    canvas.translate(24, 27);
    canvas.rotate(-0.3);
    canvas.drawArc(orbit, math.pi, math.pi, false, ring);
    canvas.restore();

    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(24, 24), radius: 16)),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(32, 19), radius: 13)),
    );
    canvas.drawPath(moon, paint);
    final star = Path()
      ..moveTo(38, 6)
      ..lineTo(39.6, 10.4)
      ..lineTo(44, 12)
      ..lineTo(39.6, 13.6)
      ..lineTo(38, 18)
      ..lineTo(36.4, 13.6)
      ..lineTo(32, 12)
      ..lineTo(36.4, 10.4)
      ..close();
    canvas.drawPath(star, paint);

    canvas.save();
    canvas.translate(24, 27);
    canvas.rotate(-0.3);
    canvas.drawArc(orbit, 0, math.pi, false, ring);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoonPainter o) => false;
}

/// 8-point compass star fallback icon.
class CompassStarPainter extends CustomPainter {
  const CompassStarPainter({required this.color, this.glow = false});
  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), r * 0.75, glowPaint);
    }

    final path = Path();
    const points = 8;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      double radius;
      if (i % 2 == 0) {
        final isMajor = (i % 4 == 0);
        radius = isMajor ? r : r * 0.58;
      } else {
        radius = r * 0.22;
      }
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final centerDot = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.12, centerDot);
  }

  @override
  bool shouldRepaint(CompassStarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}

/// Atmospheric Eternal Dusk scene for authentication and PIN lock screens.
class AuthScene extends StatelessWidget {
  const AuthScene({super.key, required this.child, this.darken = false});

  final Widget child;
  final bool darken;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/eternal_dusk_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [C.voidBg, C.midnight, C.nebula],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                C.voidBg.withValues(alpha: darken ? 0.66 : 0.35),
                C.midnight.withValues(alpha: darken ? 0.76 : 0.48),
                C.voidBg.withValues(alpha: darken ? 0.90 : 0.72),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: darken ? 0.14 : 0.22,
            child: Image.asset(
              'assets/images/eternal_dusk_overlay.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Eternal Dusk gradient & mountain ridge backdrop helper.
class NightScene extends StatelessWidget {
  const NightScene({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.voidBg, C.midnight, C.nebula, C.magenta],
              stops: [0, 0.48, 0.82, 1],
            ),
          ),
        ),
        CustomPaint(painter: _NightPainter()),
        child,
      ]);
}

class _NightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.35 + rnd.nextDouble() * 0.6);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.6),
        0.6 + rnd.nextDouble() * 1.2,
        p,
      );
    }
    final hh = (s.height * 0.16).clamp(100.0, 170.0);
    Path ridge(List<List<double>> pts) {
      final path = Path()..moveTo(0, s.height);
      for (final q in pts) {
        path.lineTo(q[0] / 1440 * s.width, s.height - hh + q[1] / 140 * hh);
      }
      return path
        ..lineTo(s.width, s.height)
        ..close();
    }

    canvas.drawPath(
      ridge([
        [0, 82],
        [140, 36],
        [260, 74],
        [430, 16],
        [620, 82],
        [790, 38],
        [990, 90],
        [1140, 50],
        [1320, 88],
        [1440, 62]
      ]),
      Paint()..color = C.nebula,
    );
    canvas.drawPath(
      ridge([
        [0, 108],
        [180, 78],
        [330, 104],
        [550, 66],
        [750, 100],
        [990, 70],
        [1240, 102],
        [1440, 92]
      ]),
      Paint()..color = C.voidBg,
    );
  }

  @override
  bool shouldRepaint(_NightPainter o) => false;
}

Future<T?> showSheet<T>(BuildContext c, Widget w) => showModalBottomSheet<T>(
      context: c,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (b) => Padding(
        padding:
            EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(b).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: w),
      ),
    );

/// Layered dark container card with hairline border and soft ambient shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(
        color: highlight
            ? C.violet.withValues(alpha: 0.55)
            : C.lavender.withValues(alpha: 0.16),
        width: highlight ? 1.2 : 1.0,
      ),
    );

    return Container(
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.90),
        shape: shape,
        shadows: [
          BoxShadow(
            color: (highlight ? C.aurora : C.voidBg)
                .withValues(alpha: highlight ? 0.20 : 0.42),
            blurRadius: highlight ? 22 : 16,
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
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Consistent section header across settings and feature pages.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.78),
                  letterSpacing: 0.2,
                ),
          ),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: C.violet,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded square thematic icon badge.
Widget iconBadge(
  IconData icon,
  Color color, {
  double size = 42,
  double iconSize = 22,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.28), width: 1.0),
    ),
    child: Icon(icon, color: color, size: iconSize),
  );
}

Widget gap(double h) => SizedBox(height: h);

Future<bool> confirm(BuildContext c, String text, {String ok = 'Delete'}) async =>
    (await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(c.tr('Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(d, true), child: Text(c.tr(ok))),
        ],
      ),
    )) ??
    false;

/// Eternal Dusk horizon lake scene fallback painter.
class LakeScene extends StatelessWidget {
  const LakeScene({super.key, required this.child, this.moon = true});
  final Widget child;
  final bool moon;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                C.voidBg,
                C.midnight,
                C.nebula,
                C.magenta,
                C.coral,
                C.nebula,
                C.voidBg,
              ],
              stops: [0, 0.35, 0.55, 0.68, 0.72, 0.8, 1],
            ),
          ),
        ),
        CustomPaint(painter: _LakePainter(moon)),
        child,
      ]);
}

class _LakePainter extends CustomPainter {
  _LakePainter(this.moon);
  final bool moon;

  static const List<List<List<double>>> _far = [
    [
      [0, .60],
      [.12, .63],
      [.22, .665],
      [.34, .70],
      [.46, .72]
    ],
    [
      [.56, .72],
      [.68, .68],
      [.80, .64],
      [.90, .62],
      [1, .60]
    ],
  ];
  static const List<List<List<double>>> _near = [
    [
      [0, .665],
      [.10, .69],
      [.20, .71],
      [.30, .72]
    ],
    [
      [.66, .72],
      [.78, .70],
      [.90, .68],
      [1, .66]
    ],
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, horizon = h * 0.72;
    final rnd = math.Random(11);
    for (var i = 0; i < 45; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.5),
        0.5 + rnd.nextDouble() * 1.1,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.6),
      );
    }

    if (moon) {
      final c = Offset(w * 0.46, h * 0.17), r = w * 0.075;
      final crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Path()
          ..addOval(Rect.fromCircle(
              center: c.translate(r * 0.55, -r * 0.2), radius: r * 0.88)),
      );
      canvas.drawPath(
        crescent,
        Paint()
          ..color = C.lavender.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawPath(crescent, Paint()..color = C.mist);
    }

    Path ridge(List<List<double>> pts) {
      final p = Path()..moveTo(pts.first[0] * w, horizon);
      for (final q in pts) {
        p.lineTo(q[0] * w, q[1] * h);
      }
      return p
        ..lineTo(pts.last[0] * w, horizon)
        ..close();
    }

    void draw(List<List<List<double>>> layers, Color color) {
      for (final l in layers) {
        canvas.drawPath(ridge(l), Paint()..color = color);
      }
    }

    draw(_far, C.nebula);
    draw(_near, C.midnight);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, horizon + h * 0.05),
        width: w * 0.5,
        height: h * 0.1,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            C.rose.withValues(alpha: 0.40),
            C.rose.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(w * 0.5, horizon + h * 0.05),
            width: w * 0.5,
            height: h * 0.1,
          ),
        ),
    );
    canvas.save();
    canvas.translate(0, horizon * 2);
    canvas.scale(1, -1);
    for (final l in _far) {
      canvas.drawPath(ridge(l), Paint()..color = C.nebula.withValues(alpha: 0.35));
    }
    for (final l in _near) {
      canvas.drawPath(
          ridge(l), Paint()..color = C.midnight.withValues(alpha: 0.5));
    }
    canvas.restore();
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i < 26; i++) {
      final y = horizon + 6 + rnd.nextDouble() * (h - horizon - 12);
      final x = rnd.nextDouble() * w * 0.8,
          len = w * (0.08 + rnd.nextDouble() * 0.22);
      canvas.drawLine(Offset(x, y), Offset(x + len, y), ripple);
    }
  }

  @override
  bool shouldRepaint(_LakePainter o) => o.moon != moon;
}
