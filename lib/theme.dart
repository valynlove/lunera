import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const appName = 'Lunera';
const tagline = 'Setiap fase, milikmu.';

class C {
  static const ink = Color(0xFF1E1B4B);
  static const mist = Color(0xFFF4F3FD);
  static const amber = Color(0xFFF0B541);
  static const deep = Color(0xFF12112F);
  static const deepCard = Color(0xFF1C1B45);
  static const midnight = Color(0xFF0F122B);
  static const lavender = Color(0xFFA997FF);

  static Color lagoon = const Color(0xFF34B08F); // aksen kedua (mint): selesai, perkiraan
  static Color peony = const Color(0xFF6B5CE0); // aksen utama (violet): tombol, hari ini
}

/// (nama, aksen kedua, aksen utama)
const accents = <String, (String, Color, Color)>{
  'lunera': ('Violet dan mint', Color(0xFF34B08F), Color(0xFF6B5CE0)),
  'lagoon': ('Teal dan peony', Color(0xFF1E9E9A), Color(0xFFE8628C)),
  'ocean': ('Biru dan jingga', Color(0xFF2F7FD6), Color(0xFFF08A3C)),
  'forest': ('Hijau dan koral', Color(0xFF3E9B5F), Color(0xFFE5675A)),
};

void applyAccent(String id) {
  final a = accents[id] ?? accents['lunera']!;
  C.lagoon = a.$2;
  C.peony = a.$3;
}

TextStyle display(double size, {Color? color, FontWeight? weight}) => GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight ?? (size >= 40 ? FontWeight.w800 : FontWeight.w700),
      height: 1.05,
      letterSpacing: -size * 0.02,
      color: color,
    );

TextStyle wordmark(double size, {Color? color}) =>
    GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w300, letterSpacing: size * .14, height: 1, color: color);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final fg = dark ? const Color(0xFFECEAFF) : C.ink;
  final scheme = ColorScheme.fromSeed(seedColor: C.peony, brightness: b)
      .copyWith(primary: C.peony, secondary: C.lagoon, surface: dark ? C.deepCard : Colors.white, onSurface: fg);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: Colors.transparent);
  return base.copyWith(
    textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(bodyColor: fg, displayColor: fg),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fg.withValues(alpha: .06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
  );
}

/// Latar gradien seluruh aplikasi (malam di mode gelap, kabut lavender di mode terang).
Widget appBackdrop(BuildContext context, Widget? child) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark ? const [Color(0xFF1B1A4B), Color(0xFF0F0E2A)] : const [Color(0xFFF6F5FF), Color(0xFFE9E7F9)],
      ),
    ),
    child: child,
  );
}

/// Kartu: tepi tipis di mode gelap, bayangan lembut ungu di mode terang.
BoxDecoration cardBox(BuildContext c, {double radius = 28}) {
  final t = Theme.of(c), dark = t.brightness == Brightness.dark;
  return BoxDecoration(
    color: t.colorScheme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: dark ? Border.all(color: Colors.white.withValues(alpha: .07)) : null,
    boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF6B5CE0).withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 8))],
  );
}

Widget pillButton(String label, VoidCallback onTap, {IconData? icon, Color? color}) {
  final style = FilledButton.styleFrom(
    backgroundColor: color ?? C.peony,
    foregroundColor: Colors.white,
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
  return icon == null
      ? FilledButton(onPressed: onTap, style: style, child: Text(label))
      : FilledButton.icon(onPressed: onTap, style: style, icon: Icon(icon, size: 20), label: Text(label));
}

/// Tab berbentuk pil: yang aktif berisi gradien violet.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({super.key, required this.items, required this.value, required this.onChanged});
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: fg.withValues(alpha: .07), borderRadius: BorderRadius.circular(999)),
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
                  gradient: it.$1 == value ? LinearGradient(colors: [C.peony, Color.lerp(C.peony, Colors.white, .22)!]) : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  it.$2,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: it.$1 == value ? Colors.white : fg.withValues(alpha: .7)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Logo: bulan sabit dengan bintang.
class MoonLogo extends StatelessWidget {
  const MoonLogo({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _MoonPainter()));
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48);
    final paint = Paint()..color = const Color(0xFFE7E3FF);
    final ring = Paint()
      ..color = const Color(0xFFE7E3FF).withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final orbit = Rect.fromCenter(center: Offset.zero, width: 44, height: 12);
    // cincin orbit: setengah belakang digambar sebelum bulan, setengah depan sesudahnya
    canvas.save();
    canvas.translate(24, 27);
    canvas.rotate(-0.3);
    canvas.drawArc(orbit, math.pi, math.pi, false, ring);
    canvas.restore();

    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(24, 24), radius: 16)),
      Path()..addOval(Rect.fromCircle(center: const Offset(32, 19), radius: 13)),
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

/// Langit malam dengan bintang dan pegunungan, untuk layar masuk dan kunci.
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
              colors: [Color(0xFF12112F), Color(0xFF25225A), Color(0xFF5C4A8F), Color(0xFFC98AA8)],
              stops: [0, .52, .84, 1],
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
      final p = Paint()..color = Colors.white.withValues(alpha: .35 + rnd.nextDouble() * .6);
      canvas.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .6), .6 + rnd.nextDouble() * 1.2, p);
    }
    final hh = (s.height * .16).clamp(100.0, 170.0);
    Path ridge(List<List<double>> pts) {
      final path = Path()..moveTo(0, s.height);
      for (final q in pts) {
        path.lineTo(q[0] / 1440 * s.width, s.height - hh + q[1] / 140 * hh);
      }
      return path..lineTo(s.width, s.height)..close();
    }

    canvas.drawPath(
        ridge([[0, 82], [140, 36], [260, 74], [430, 16], [620, 82], [790, 38], [990, 90], [1140, 50], [1320, 88], [1440, 62]]),
        Paint()..color = const Color(0xFF1A1844));
    canvas.drawPath(
        ridge([[0, 108], [180, 78], [330, 104], [550, 66], [750, 100], [990, 70], [1240, 102], [1440, 92]]),
        Paint()..color = const Color(0xFF12112F));
  }

  @override
  bool shouldRepaint(_NightPainter o) => false;
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

Future<bool> confirm(BuildContext c, String text, {String ok = 'Hapus'}) async =>
    (await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(ok)),
        ],
      ),
    )) ??
    false;

/// Pemandangan danau di malam hari (layar pembuka): langit, bulan sabit, pegunungan,
/// dan danau yang memantulkan cahaya cakrawala. [moon] false jika bulan digambar di tempat lain.
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
                Color(0xFF0F0E33),
                Color(0xFF25225A),
                Color(0xFF4B3C86),
                Color(0xFF8E6AA8),
                Color(0xFFD79AB8),
                Color(0xFF3A2E72),
                Color(0xFF14123A),
              ],
              stops: [0, .35, .55, .68, .72, .8, 1],
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
    [[0, .60], [.12, .63], [.22, .665], [.34, .70], [.46, .72]],
    [[.56, .72], [.68, .68], [.80, .64], [.90, .62], [1, .60]],
  ];
  static const List<List<List<double>>> _near = [
    [[0, .665], [.10, .69], [.20, .71], [.30, .72]],
    [[.66, .72], [.78, .70], [.90, .68], [1, .66]],
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, horizon = h * .72;
    final rnd = math.Random(11);
    for (var i = 0; i < 45; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * .5),
        .5 + rnd.nextDouble() * 1.1,
        Paint()..color = Colors.white.withValues(alpha: .3 + rnd.nextDouble() * .6),
      );
    }

    if (moon) {
      final c = Offset(w * .46, h * .17), r = w * .075;
      final crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Path()..addOval(Rect.fromCircle(center: c.translate(r * .55, -r * .2), radius: r * .88)),
      );
      canvas.drawPath(
        crescent,
        Paint()
          ..color = const Color(0xFFF3E9E4).withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawPath(crescent, Paint()..color = const Color(0xFFF3E9E4));
    }

    Path ridge(List<List<double>> pts) {
      final p = Path()..moveTo(pts.first[0] * w, horizon);
      for (final q in pts) {
        p.lineTo(q[0] * w, q[1] * h);
      }
      return p..lineTo(pts.last[0] * w, horizon)..close();
    }

    void draw(List<List<List<double>>> layers, Color color) {
      for (final l in layers) {
        canvas.drawPath(ridge(l), Paint()..color = color);
      }
    }

    draw(_far, const Color(0xFF3B2F73));
    draw(_near, const Color(0xFF1A1844));

    // pantulan cahaya cakrawala di danau
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .5, horizon + h * .05), width: w * .5, height: h * .1),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x66E7A9C4), Color(0x00E7A9C4)],
        ).createShader(
          Rect.fromCenter(center: Offset(w * .5, horizon + h * .05), width: w * .5, height: h * .1),
        ),
    );
    // pantulan pegunungan (dicerminkan terhadap cakrawala)
    canvas.save();
    canvas.translate(0, horizon * 2);
    canvas.scale(1, -1);
    for (final l in _far) {
      canvas.drawPath(ridge(l), Paint()..color = const Color(0xFF3B2F73).withValues(alpha: .35));
    }
    for (final l in _near) {
      canvas.drawPath(ridge(l), Paint()..color = const Color(0xFF1A1844).withValues(alpha: .5));
    }
    canvas.restore();
    // riak air
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..strokeWidth = 1;
    for (var i = 0; i < 26; i++) {
      final y = horizon + 6 + rnd.nextDouble() * (h - horizon - 12);
      final x = rnd.nextDouble() * w * .8, len = w * (.08 + rnd.nextDouble() * .22);
      canvas.drawLine(Offset(x, y), Offset(x + len, y), ripple);
    }
  }

  @override
  bool shouldRepaint(_LakePainter o) => o.moon != moon;
}
