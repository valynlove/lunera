import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';

/// Palet warna resmi Lunera
class C {
  static const midnight = Color(0xFF0F122B);
  static const indigo = Color(0xFF3B3F7A);
  static const lavender = Color(0xFFA997FF);
  static const moonlight = Color(0xFFE6E2FF);
  static const ivory = Color(0xFFF7F6FB);

  static const ink = Color(0xFF12142B);
  static const deepCard = Color(0xFF181B3B);
  static const amber = Color(0xFFF0B541);

  // Dynamic accents (dapat disesuaikan lewat Pengaturan)
  static Color lagoon = const Color(0xFFA997FF); // Primary accent (Lavender)
  static Color peony = const Color(0xFF3B3F7A);  // Secondary accent (Indigo)
}

const accents = <String, (String, Color, Color)>{
  'lunera': ('Lunera', Color(0xFFA997FF), Color(0xFF3B3F7A)),
  'moonlight': ('Moonlight', Color(0xFFC5B8FF), Color(0xFF0F122B)),
  'ocean': ('Ocean', Color(0xFF638EFF), Color(0xFFA997FF)),
  'rose': ('Rose Quartz', Color(0xFFE89BFF), Color(0xFFA997FF)),
};

void applyAccent(String id) {
  final a = accents[id] ?? accents['lunera']!;
  C.lagoon = a.$2;
  C.peony = a.$3;
}

/// Tipografi Seri Lunera (Playfair Display untuk Judul / Header)
TextStyle display(double size, {Color? color, FontWeight? weight}) => GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w600,
      height: 1.15,
      letterSpacing: -size * 0.02,
      color: color,
    );

/// Tipografi Tagline Lunera (Montserrat)
TextStyle tagline(double size, {Color? color}) => GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.4,
      color: color,
    );

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final fg = dark ? const Color(0xFFEAE7FF) : C.ink;
  final primary = C.lagoon;
  final secondary = C.peony;

  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: b).copyWith(
    primary: primary,
    secondary: secondary,
    surface: dark ? C.deepCard : Colors.white,
    onSurface: fg,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? C.midnight : C.ivory,
  );

  return base.copyWith(
    textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(bodyColor: fg, displayColor: fg),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Colors.white.withValues(alpha: .06) : C.moonlight.withValues(alpha: .4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? C.indigo.withValues(alpha: .4) : C.moonlight.withValues(alpha: .5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
  );
}

Widget pillButton(String label, VoidCallback onTap, {IconData? icon, Color? color}) {
  final bg = color ?? C.lavender;
  final fg = bg.computeLuminance() > 0.5 ? C.midnight : Colors.white;
  final style = FilledButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: fg,
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
    textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
  );
  return icon == null
      ? FilledButton(onPressed: onTap, style: style, child: Text(label))
      : FilledButton.icon(onPressed: onTap, style: style, icon: Icon(icon, size: 20), label: Text(label));
}

/// Logo Resmi Lunera (Bulan, Orbit Ring, dan Bintang)
class LuneraLogo extends StatelessWidget {
  const LuneraLogo({
    super.key,
    this.size = 100,
    this.color,
    this.showText = false,
    this.showTagline = false,
  });

  final double size;
  final Color? color;
  final bool showText;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final primary = color ?? C.lavender;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _LuneraLogoPainter(primaryColor: primary),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.12),
          Text('Lunera', style: display(size * 0.36, color: Theme.of(context).colorScheme.onSurface)),
        ],
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Every Phase, Your Own.',
            style: tagline(size * 0.11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _LuneraLogoPainter extends CustomPainter {
  _LuneraLogoPainter({required this.primaryColor});
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.33;

    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        primaryColor.withValues(alpha: .75),
        const Color(0xFFE6E2FF),
      ],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paintFill = Paint()
      ..shader = grad.createShader(rect)
      ..style = PaintingStyle.fill;

    // 1. Crescent Moon
    final moonPath = Path();
    moonPath.addOval(Rect.fromCircle(center: center, radius: radius));

    final innerCenter = center + Offset(radius * 0.38, -radius * 0.22);
    final innerPath = Path()..addOval(Rect.fromCircle(center: innerCenter, radius: radius * 0.88));

    final crescentPath = Path.combine(PathOperation.difference, moonPath, innerPath);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-22 * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(crescentPath, paintFill);
    canvas.restore();

    // 2. Orbit Ring
    final orbitPaint = Paint()
      ..shader = grad.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-28 * math.pi / 180);
    final orbitRect = Rect.fromCenter(center: Offset.zero, width: radius * 2.45, height: radius * 0.82);
    canvas.drawOval(orbitRect, orbitPaint);
    canvas.restore();

    // 3. Sparkle / 4-Pointed Star
    final starCenter = center + Offset(radius * 1.02, -radius * 0.85);
    final starSize = size.width * 0.085;
    final starPath = Path();
    starPath.moveTo(starCenter.dx, starCenter.dy - starSize);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx + starSize, starCenter.dy);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx, starCenter.dy + starSize);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx - starSize, starCenter.dy);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx, starCenter.dy - starSize);
    starPath.close();

    final starPaint = Paint()
      ..color = const Color(0xFFE6E2FF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant _LuneraLogoPainter oldDelegate) => oldDelegate.primaryColor != primaryColor;
}

Future<T?> showSheet<T>(BuildContext c, Widget w) => showModalBottomSheet<T>(
      context: c,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (b) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(b).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: w),
      ),
    );

Widget gap(double h) => SizedBox(height: h);

Future<bool> confirm(BuildContext c, String text, {String ok = 'Delete'}) async =>
    (await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(ok)),
        ],
      ),
    )) ??
    false;

final Map<String, ImageProvider> _avatarCache = {};

ImageProvider? getAvatarImageProvider(String avatarUrl) {
  if (!avatarUrl.startsWith('data:image/')) return null;
  if (_avatarCache.containsKey(avatarUrl)) {
    return _avatarCache[avatarUrl];
  }
  try {
    final base64Str = avatarUrl.split(',').last;
    final bytes = base64Decode(base64Str);
    final provider = MemoryImage(bytes);
    if (_avatarCache.length > 10) _avatarCache.clear();
    _avatarCache[avatarUrl] = provider;
    return provider;
  } catch (_) {
    return null;
  }
}

Widget buildAvatar(Prefs prefs, {double radius = 24, VoidCallback? onTap}) {
  Widget content;
  final provider = getAvatarImageProvider(prefs.avatarUrl);

  if (provider != null) {
    content = CircleAvatar(
      radius: radius,
      backgroundImage: provider,
    );
  } else if (prefs.avatarUrl.isNotEmpty && !prefs.avatarUrl.startsWith('data:image/')) {
    content = CircleAvatar(
      radius: radius,
      backgroundColor: C.lavender.withValues(alpha: .25),
      child: Text(prefs.avatarUrl, style: TextStyle(fontSize: radius * 1.1)),
    );
  } else {
    content = CircleAvatar(
      radius: radius,
      backgroundColor: C.lavender.withValues(alpha: .25),
      child: Icon(Icons.person_rounded, size: radius * 1.1, color: C.lavender),
    );
  }

  return onTap == null
      ? content
      : GestureDetector(onTap: onTap, child: content);
}
