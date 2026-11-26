import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'repo.dart';
import 'schedule.dart';
import 'sim.dart';
import 'theme.dart';
import 'l10n.dart';
import 'workout_coach.dart';

/// Background callback triggered by interactive Android Home Screen widgets
/// (WorkoutWidget "Rest / Resume" and CompanionWidget "Poke / Pat / Chat").
@pragma('vm:entry-point')
Future<void> workoutWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  if (uri.host == 'companion') {
    await _handleCompanionWidgetAction(uri.path);
    return;
  }
  if (uri.host != 'workout' || uri.path != '/rest') return;
  try {
    await L10n.load();
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('lunera_workout_v1');
    final current = raw != null && raw.isNotEmpty
        ? WorkoutState.fromMap(
            (jsonDecode(raw) as Map).cast<String, dynamic>())
        : const WorkoutState();
    final now = DateTime.now();
    final todayIso = isoDateOf(now);
    final isResting = current.profile.skippedDateIso == todayIso;
    final nextProfile = isResting
        ? current.profile.copyWith(clearSkippedDate: true)
        : current.profile.copyWith(skippedDateIso: todayIso);
    final next = current.copyWith(profile: nextProfile);
    await sp.setString('lunera_workout_v1', jsonEncode(next.toMap()));

    final rec = evaluateCoachContext(
      now: now,
      profile: next.profile,
      workoutLogs: next.logs,
      therapies: const [],
      doseLogs: const [],
      prefs: const Prefs(),
      customRoutines: next.customRoutines,
    );
    await HomeWidget.saveWidgetData<String>('wrk_badge', rec.contextBadge ?? '');
    await HomeWidget.saveWidgetData<String>(
      'wrk_title',
      rec.kind == CoachContextKind.restedToday
          ? rec.headline
          : rec.recommendedRoutine.title,
    );
    await HomeWidget.saveWidgetData<String>(
      'wrk_sub',
      rec.kind == CoachContextKind.restedToday
          ? tr('Recovery counts too')
          : '~${rec.recommendedRoutine.estimatedMinutes} min · ${tr('{0} active days', [rec.activeDaysThisMonth])}',
    );
    await HomeWidget.saveWidgetData<String>('wrk_mood', rec.coachMood.name);
    await HomeWidget.saveWidgetData<String>(
        'wrk_resting', rec.kind == CoachContextKind.restedToday ? '1' : '0');
    await HomeWidget.updateWidget(
        qualifiedAndroidName: 'com.example.ritme.WorkoutWidget');
  } catch (e) {
    debugPrint('Workout widget background rest failed: $e');
  }
}

const List<(String, String, String)> _companionPokeLines = [
  ('shocked', 'Whoa—! That startled me a little!', 'Eh—! Kaget aku tiba-tiba dicolek!'),
  ('wink', 'Hehe, bored? I am right here with you.', 'Hehe, lagi gabut ya? Aku temenin di sini.'),
  ('laugh', 'Poking my cheeks is officially your new hobby.', 'Nyolek pipiku udah jadi hobi baru nih ya.'),
  ('shy', 'U-um, you keep tapping me... not that I mind.', 'E-eh, dicolek terus... bukan berarti gak suka sih.'),
  ('happy', 'Boop! Sending a tiny spark of stardust your way.', 'Boop! Kirim sepercik energi bintang buat kamu.'),
  ('annoyed', 'Okay okay, my cheeks are not a stress ball!', 'Iya iyaa, pipiku bukan mainan pencet tau!'),
];

const List<(String, String, String)> _companionPatLines = [
  ('love', 'Warm headpats received! Energy +100 ♥', 'Elusan diterima! Energi langsung penuh lagi ♥'),
  ('happy', 'That feels super cozy. You are doing great today.', 'Nyaman banget~ Kamu udah hebat banget hari ini.'),
  ('shy', 'Aww... thank you. Take a soft breath with me.', 'Aww... makasih ya. Tarik napas pelan bareng aku.'),
  ('care', 'You deserve just as much gentleness as you give.', 'Kamu juga berhak disayang pelan-pelan kayak gini.'),
  ('cheer', 'Yay! Instant serotonin boost unlocked ✨', 'Yay! Boost semangat instan aktif ✨'),
];

const List<(String, String, String)> _companionTalkLines = [
  ('calm', 'Plot twist: surviving today already earns full marks.', 'Plot twist: bertahan sampai hari ini aja udah nilai sempurna.'),
  ('ponder', 'Have you had a sip of water recently? Go grab one!', 'Udah minum air putih belum barusan? Minum dikit yuk!'),
  ('wink', 'Even the moon takes a whole month to cycle its phases.', 'Bulan aja butuh sebulan penuh buat ganti fase, santai aja.'),
  ('care', 'Drop your shoulders and unclench your jaw for a second.', 'Turunin bahunya sebentar, lemesin rahangnya ya.'),
  ('cheer', 'Small steady steps still count as moving forward.', 'Langkah kecil yang pelan tetap dihitung maju kok.'),
  ('sleepy', 'If it is getting late, promise me you will rest soon.', 'Kalau udah larut, janji ya bentar lagi istirahat.'),
  ('wave', 'Just checking in—I am always cheering from your home screen.', 'Cuma mau nyapa—aku selalu nyemangatin dari home screen.'),
];

Future<void> _handleCompanionWidgetAction(String path) async {
  try {
    await L10n.load();
    final id = L10n.code == 'id';
    final sp = await SharedPreferences.getInstance();
    var pats = sp.getInt('cmp_pats_count') ?? 0;
    var pokeStreak = sp.getInt('cmp_poke_streak') ?? 0;
    var talkIdx = sp.getInt('cmp_talk_idx') ?? 0;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var water = sp.getString('cmp_hydration_date') == todayStr
        ? (sp.getInt('cmp_hydration_cups') ?? 0)
        : 0;
    final rng = math.Random();

    late String mood;
    late String speech;

    if (path == '/water') {
      water += 1;
      pokeStreak = 0;
      await sp.setString('cmp_hydration_date', todayStr);
      await sp.setInt('cmp_hydration_cups', water);
      if (water >= 8) {
        mood = 'cheer';
        speech = id
            ? 'Target minum tercapai ($water/8)! Hebat banget 💧'
            : 'Hydration goal reached ($water/8)! Amazing job 💧';
      } else {
        mood = water.isEven ? 'care' : 'happy';
        speech = id
            ? 'Minum +1 ($water/8)! Tubuhmu pasti senang 💧'
            : 'Hydration +1 ($water/8)! Your future self thanks you 💧';
      }
    } else if (path == '/pat') {
      pats += 1;
      pokeStreak = 0;
      final pick = _companionPatLines[rng.nextInt(_companionPatLines.length)];
      mood = pick.$1;
      speech = id ? pick.$3 : pick.$2;
    } else if (path == '/talk') {
      pokeStreak = 0;
      final hour = DateTime.now().hour;
      if ((hour >= 22 || hour < 5) && rng.nextInt(3) == 0) {
        mood = 'sleepy';
        speech = id
            ? 'Udah malam nih... jangan lupa istirahat ya 🌙'
            : 'It is getting late... do not forget to rest 🌙';
      } else {
        final pick = _companionTalkLines[talkIdx % _companionTalkLines.length];
        talkIdx += 1;
        mood = pick.$1;
        speech = id ? pick.$3 : pick.$2;
      }
    } else {
      // /poke (tap directly on mascot)
      pats += 1;
      pokeStreak += 1;
      final (String, String, String) pick;
      if (pokeStreak >= 4) {
        pick = _companionPokeLines.last;
        pokeStreak = 0;
      } else {
        pick = _companionPokeLines[rng.nextInt(_companionPokeLines.length - 1)];
      }
      mood = pick.$1;
      speech = id ? pick.$3 : pick.$2;
    }

    await sp.setInt('cmp_pats_count', pats);
    await sp.setInt('cmp_poke_streak', pokeStreak);
    await sp.setInt('cmp_talk_idx', talkIdx);

    await HomeWidget.saveWidgetData<String>('lang', L10n.code);
    await HomeWidget.saveWidgetData<String>('cmp_mood', mood);
    await HomeWidget.saveWidgetData<String>('cmp_speech', speech);
    await HomeWidget.saveWidgetData<String>('cmp_pats', '$pats');
    await HomeWidget.saveWidgetData<String>('cmp_water', '$water');
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.ritme.CompanionWidget',
    );
  } catch (e) {
    debugPrint('Companion widget background action failed: $e');
  }
}

/// Mengirim data ke widget layar utama Android: lama terapi, jadwal, dan grafik level.
/// Data ditulis ke penyimpanan bersama (SharedPreferences) yang dibaca kode Kotlin widget.
class WidgetSync {
  WidgetSync._();

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static final pendingWorkoutAction = ValueNotifier<String?>(null);
  static final pendingCompanionAction = ValueNotifier<String?>(null);
  static const _widgets = ['HrtWidget', 'ScheduleWidget', 'LevelWidget', 'WorkoutWidget', 'CompanionWidget'];
  static const _keys = [
    'hrt_first_date', 'hrt_count',
    'sch_0_title', 'sch_0_at', 'sch_0_sub', 'sch_1_title', 'sch_1_at', 'sch_1_sub', 'sch_2_title', 'sch_2_at', 'sch_2_sub',
    'lvl_title', 'lvl_value', 'lvl_note', 'lvl_image',
    'wrk_badge', 'wrk_title', 'wrk_sub', 'wrk_mood', 'wrk_resting',
    'cmp_mood', 'cmp_speech', 'cmp_pats', 'cmp_water',
  ];
  static Timer? _timer;

  /// Dijadwalkan dengan jeda 2 detik supaya perubahan beruntun hanya memicu satu pembaruan.
  static void sync(List<Therapy> ths, List<DoseLog> logs, List<Lab> labs, Map<String, List<double>> targets, Prefs prefs, {WorkoutState? workout}) {
    if (!supported) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      _run(ths, logs, labs, targets, prefs, workout: workout).catchError((Object e) => debugPrint(tr('Widget update failed: {0}', [e])));
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
      await HomeWidget.updateWidget(qualifiedAndroidName: 'com.example.ritme.$n');
    }
  }

  static Future<void> _run(List<Therapy> ths, List<DoseLog> logs, List<Lab> labs, Map<String, List<double>> targets, Prefs prefs, {WorkoutState? workout}) async {
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

    // 4. Movement Coach 2x2 widget
    final ws = workout ?? await WorkoutController.loadDirect();
    final rec = evaluateCoachContext(
      now: DateTime.now(),
      profile: ws.profile,
      workoutLogs: ws.logs,
      therapies: ths,
      doseLogs: logs,
      prefs: prefs,
      customRoutines: ws.customRoutines,
    );
    await HomeWidget.saveWidgetData<String>('wrk_badge', rec.contextBadge ?? '');
    await HomeWidget.saveWidgetData<String>(
      'wrk_title',
      rec.kind == CoachContextKind.restedToday
          ? rec.headline
          : rec.recommendedRoutine.title,
    );
    await HomeWidget.saveWidgetData<String>(
      'wrk_sub',
      rec.kind == CoachContextKind.restedToday
          ? tr('Recovery counts too')
          : '~${rec.recommendedRoutine.estimatedMinutes} min · ${tr('{0} active days', [rec.activeDaysThisMonth])}',
    );
    await HomeWidget.saveWidgetData<String>('wrk_mood', rec.coachMood.name);
    await HomeWidget.saveWidgetData<String>(
        'wrk_resting', rec.kind == CoachContextKind.restedToday ? '1' : '0');

    // 5. Companion 2x2 interactive mascot widget (preserve existing state if already set)
    final sp = await SharedPreferences.getInstance();
    final pats = sp.getInt('cmp_pats_count') ?? 0;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final water = sp.getString('cmp_hydration_date') == todayStr
        ? (sp.getInt('cmp_hydration_cups') ?? 0)
        : 0;
    await HomeWidget.saveWidgetData<String>('cmp_pats', '$pats');
    await HomeWidget.saveWidgetData<String>('cmp_water', '$water');
    final existingMood = await HomeWidget.getWidgetData<String>('cmp_mood');
    if (existingMood == null || existingMood.isEmpty) {
      await HomeWidget.saveWidgetData<String>('cmp_mood', 'wave');
    }

    await _refresh();
  }

  /// Immediately pushes updated companion affection & hydration counts to CompanionWidget.
  static Future<void> syncCompanionStats({
    required int pats,
    required int waterCups,
  }) async {
    if (!supported) return;
    try {
      await HomeWidget.saveWidgetData<String>('cmp_pats', '$pats');
      await HomeWidget.saveWidgetData<String>('cmp_water', '$waterCups');
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'com.example.ritme.CompanionWidget',
      );
    } catch (e) {
      debugPrint('Companion stats sync failed: $e');
    }
  }

  /// Forces an immediate refresh of all Android home screen widgets.
  static Future<void> refreshAll() async {
    if (!supported) return;
    try {
      await _refresh();
    } catch (e) {
      debugPrint('Widget refresh failed: $e');
    }
  }

  static Future<void> _chart(List<Therapy> ths, List<DoseLog> logs, List<Lab> labs, Map<String, List<double>> targets, Prefs prefs) async {
    final simIds = <String>{
      for (final t in ths) ...[
        if (pkOf(t.pk) != null) t.hormoneId,
        if (pkOf(t.secondaryPk) != null && t.secondaryHormoneId != null) t.secondaryHormoneId!,
      ]
    };
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
    final band = (t == null || t.length < 2) ? null : [t[0] / f, t[1] / f];
    final ys = <double>[...sim.map((s) => s.y), ...dots.map((d) => d.dy), ...?band];
    final top = (ys.isEmpty ? 10.0 : ys.reduce(math.max)) * 1.15 + 1;

    String value = '', note = '';
    if (intakes.isNotEmpty) {
      value = '${fmt((levelAt(intakes, now) / f).roundToDouble())} $unit';
      note = tr('Estimated from dose entries, dots = lab results');
    } else if (hl.isNotEmpty) {
      value = '${hl.last.prefix}${fmt(hl.last.base / f)} $unit';
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
      pixelRatio: 1.5,
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

  static const _text = Color(0xFFC7B8FF);

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
      final gradPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, padT),
          Offset(0, base),
          [
            line.withValues(alpha: .36),
            line.withValues(alpha: .03),
          ],
        );
      canvas.drawPath(area, gradPaint);
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
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
      canvas.drawCircle(o, 7, Paint()..color = dot.withValues(alpha: .30));
      canvas.drawCircle(o, 4.5, Paint()..color = dot);
      canvas.drawCircle(
        o,
        4.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
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
  final workout = ref.watch(workoutProvider);
  if (ths == null || logs == null || labs == null || targets == null || prefs == null) return;
  WidgetSync.sync(ths, logs, labs, targets, prefs, workout: workout);
});
