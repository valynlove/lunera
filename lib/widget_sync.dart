import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'models.dart';
import 'repo.dart';
import 'schedule.dart';
import 'sim.dart';
import 'theme.dart';
import 'l10n.dart';

/// Mengirim data ke widget layar utama Android: lama terapi, jadwal, dan grafik level.
/// Data ditulis ke penyimpanan bersama (SharedPreferences) yang dibaca kode Kotlin widget.
class WidgetSync {
  WidgetSync._();

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static const _widgets = ['HrtWidget', 'ScheduleWidget', 'LevelWidget'];
  static const _keys = [
    'hrt_first_date', 'hrt_count',
    'sch_0_title', 'sch_0_at', 'sch_0_sub', 'sch_1_title', 'sch_1_at', 'sch_1_sub', 'sch_2_title', 'sch_2_at', 'sch_2_sub',
    'lvl_title', 'lvl_value', 'lvl_note', 'lvl_image',
  ];
  static Timer? _timer;

  /// Dijadwalkan dengan jeda 2 detik supaya perubahan beruntun hanya memicu satu pembaruan.
  static void sync(List<Therapy> ths, List<DoseLog> logs, List<Lab> labs, Map<String, List<double>> targets, Prefs prefs) {
    if (!supported) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      _run(ths, logs, labs, targets, prefs).catchError((Object e) => debugPrint(tr('Widget update failed: {0}', [e])));
    });
  }

  /// Kosongkan semua widget (saat keluar dari akun).
  static Future<void> clear() async {
    if (!supported) return;
    _timer?.cancel();
    try {
      for (final k in _keys) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      await _refresh();
    } catch (e) {
      debugPrint(tr('Widget clear failed: {0}', [e]));
    }
  }

  static Future<void> _refresh() async {
    for (final n in _widgets) {
      await HomeWidget.updateWidget(androidName: n);
    }
  }

  static Future<void> _run(List<Therapy> ths, List<DoseLog> logs, List<Lab> labs, Map<String, List<double>> targets, Prefs prefs) async {
    await HomeWidget.saveWidgetData<String>('lang', L10n.code); // dibaca kode Kotlin widget
    await HomeWidget.saveWidgetData<String>('widget_hidden', prefs.widgetHide ? '1' : '0');
    if (prefs.widgetHide) {
      await _refresh();
      return;
    }
    final desc = [...logs]..sort((a, b) => b.at.compareTo(a.at));

    // 1. Lama terapi
    final taken = logs.where((l) => !l.skipped).toList();
    final starts = [...taken.map((l) => l.at), ...ths.map((t) => t.start)]..sort();
    await HomeWidget.saveWidgetData<String>('hrt_first_date', starts.isEmpty ? '' : DateFormat('yyyy-MM-dd').format(starts.first));
    await HomeWidget.saveWidgetData<String>('hrt_count', '${taken.length}');

    // 2. Jadwal: tiga dosis berikutnya yang belum dicatat (yang terlambat tampil lebih dulu)
    final slots = [for (final s in buildSlots(ths, logs, prefs, back: 3, ahead: 21)) if (s.pending) s];
    for (var i = 0; i < 3; i++) {
      final s = i < slots.length ? slots[i] : null;
      final place = s != null && s.t.adm.places ? suggestPlace(prefs, desc, s.t.id) : '';
      await HomeWidget.saveWidgetData<String>('sch_${i}_title', s?.t.name ?? '');
      await HomeWidget.saveWidgetData<String>('sch_${i}_at', s == null ? '' : '${s.at.millisecondsSinceEpoch}');
      await HomeWidget.saveWidgetData<String>('sch_${i}_sub', s == null ? '' : '${fmt(s.t.dose)} ${s.t.doseUnit}${place.isEmpty ? '' : ', ${tr(place)}'}');
    }

    // 3. Grafik level
    await _chart(ths, logs, labs, targets, prefs);
    await _refresh();
  }

  static Future<void> _chart(List<Therapy> ths, List<DoseLog> logs, List<Lab> labs, Map<String, List<double>> targets, Prefs prefs) async {
    final simIds = <String>{for (final t in ths) if (pkOf(t.pk) != null) t.hormoneId};
    String? hid;
    for (final h in simIds) {
      if (intakesFor(h, ths, logs).isNotEmpty) {
        hid = h;
        break;
      }
    }
    final sortedLabs = [...labs]..sort((a, b) => a.at.compareTo(b.at));
    hid ??= sortedLabs.isEmpty ? null : sortedLabs.last.hormoneId;
    final id = hid;
    if (id == null) {
      for (final k in const ['lvl_title', 'lvl_value', 'lvl_note', 'lvl_image']) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      return;
    }
    final p = presetOf(id), unit = prefs.unitOf(id), f = p.units[unit] ?? 1.0;
    final now = DateTime.now(), from = now.subtract(const Duration(days: 14)), to = now.add(const Duration(days: 7));
    final intakes = intakesFor(id, ths, logs);
    final sim = simSpots(intakes, from, to, scale: 1 / f, n: 168);
    final hl = sortedLabs.where((l) => l.hormoneId == id).toList();
    final dots = [
      for (final l in hl)
        if (!l.at.isBefore(from) && !l.at.isAfter(to)) Offset(l.at.difference(from).inMinutes / 1440, l.base / f),
    ];
    final t = targets[id];
    final band = t == null ? null : [t[0] / f, t[1] / f];
    final ys = <double>[...sim.map((s) => s.y), ...dots.map((d) => d.dy), ...?band];
    final top = (ys.isEmpty ? 10.0 : ys.reduce(math.max)) * 1.15 + 1;

    String value = '', note = '';
    if (intakes.isNotEmpty) {
      value = '${fmt((levelAt(intakes, now) / f).roundToDouble())} $unit';
      note = tr('Estimated from dose entries, dots = lab results');
    } else if (hl.isNotEmpty) {
      value = '${fmt(hl.last.base / f)} $unit';
      note = tr('Lab result {0}', [DateFormat('d MMM y', L10n.code).format(hl.last.at)]);
    }
    await HomeWidget.saveWidgetData<String>('lvl_title', p.name);
    await HomeWidget.saveWidgetData<String>('lvl_value', value);
    await HomeWidget.saveWidgetData<String>('lvl_note', note);
    await HomeWidget.renderFlutterWidget(
      _ChartImage(
        sim: [for (final s in sim) Offset(s.x, s.y)],
        dots: dots,
        band: band,
        total: to.difference(from).inMinutes / 1440,
        nowX: 14,
        top: top,
        fromLabel: DateFormat('d MMM', L10n.code).format(from),
        toLabel: DateFormat('d MMM', L10n.code).format(to),
      ),
      key: 'lvl_image',
      logicalSize: const Size(360, 150),
      pixelRatio: 2,
    );
  }
}

/// Gambar grafik untuk widget, digambar langsung dengan CustomPainter agar hasilnya pasti
/// walau dirender di luar layar.
class _ChartImage extends StatelessWidget {
  const _ChartImage({required this.sim, required this.dots, required this.band, required this.total, required this.nowX, required this.top, required this.fromLabel, required this.toLabel});
  final List<Offset> sim, dots;
  final List<double>? band;
  final double total, nowX, top;
  final String fromLabel, toLabel;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 360,
          height: 150,
          child: CustomPaint(
            painter: _ChartPainter(
              sim: sim,
              dots: dots,
              band: band,
              total: total,
              nowX: nowX,
              top: top,
              fromLabel: fromLabel,
              toLabel: toLabel,
              line: C.lagoon,
              dot: Color.lerp(C.peony, Colors.white, .5)!,
            ),
          ),
        ),
      );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.sim, required this.dots, required this.band, required this.total, required this.nowX, required this.top, required this.fromLabel, required this.toLabel, required this.line, required this.dot});
  final List<Offset> sim, dots;
  final List<double>? band;
  final double total, nowX, top;
  final String fromLabel, toLabel;
  final Color line, dot;

  static const _text = Color(0xFFB9B6E0);

  void _label(Canvas c, String s, Offset at, {bool right = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: const TextStyle(fontSize: 10, color: _text)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, right ? Offset(at.dx - tp.width, at.dy) : at);
  }

  @override
  void paint(Canvas canvas, Size s) {
    const padL = 34.0, padR = 6.0, padT = 6.0, padB = 18.0;
    final w = s.width - padL - padR, h = s.height - padT - padB;
    Offset p(double x, double y) {
      final fx = total <= 0 ? 0.0 : x / total;
      final fy = top <= 0 ? 0.0 : (y / top).clamp(0.0, 1.0).toDouble();
      return Offset(padL + fx * w, padT + h - fy * h);
    }

    final grid = Paint()
      ..color = _text.withValues(alpha: .18)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = top * i / 2, o = p(0, y);
      canvas.drawLine(Offset(padL, o.dy), Offset(padL + w, o.dy), grid);
      _label(canvas, y.round().toString(), Offset(0, o.dy - 6));
    }
    final b = band;
    if (b != null) canvas.drawRect(Rect.fromPoints(p(0, b[1]), p(total, b[0])), Paint()..color = line.withValues(alpha: .16));

    if (sim.length > 1) {
      final pts = [for (final o in sim) p(o.dx, o.dy)];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      final base = padT + h;
      final area = Path.from(path)
        ..lineTo(pts.last.dx, base)
        ..lineTo(pts.first.dx, base)
        ..close();
      canvas.drawPath(area, Paint()..color = line.withValues(alpha: .14));
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // garis "sekarang" putus-putus
    final nx = p(nowX, 0).dx;
    final nowPaint = Paint()
      ..color = _text.withValues(alpha: .6)
      ..strokeWidth = 1.5;
    for (var y = padT; y < padT + h; y += 8) {
      canvas.drawLine(Offset(nx, y), Offset(nx, math.min(y + 4, padT + h)), nowPaint);
    }

    for (final d in dots) {
      final o = p(d.dx, d.dy);
      canvas.drawCircle(o, 5, Paint()..color = dot);
      canvas.drawCircle(
        o,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    _label(canvas, fromLabel, Offset(padL, s.height - 13));
    _label(canvas, toLabel, Offset(padL + w, s.height - 13), right: true);
  }

  @override
  bool shouldRepaint(_ChartPainter o) => true;
}

/// Dipantau dari Shell: memperbarui widget saat data berubah.
final widgetSyncProvider = Provider<void>((ref) {
  ref.watch(langProvider); // teks widget ikut bahasa
  final ths = ref.watch(therapiesProvider).value;
  final logs = ref.watch(logsProvider).value;
  final labs = ref.watch(labsProvider).value;
  final targets = ref.watch(targetsProvider).value;
  final prefs = ref.watch(prefsProvider).value;
  if (ths == null || logs == null || labs == null || targets == null || prefs == null) return;
  WidgetSync.sync(ths, logs, labs, targets, prefs);
});
