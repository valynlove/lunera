import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import 'journal.dart';

/// Tubuh & perubahan: ringkasan dan garis waktu dari entri jurnal.
class BodyPage extends ConsumerStatefulWidget {
  const BodyPage({super.key});
  @override
  ConsumerState<BodyPage> createState() => _BodyPageState();
}

// Bagian yang digambar pada siluet, urut dari atas, beserta posisi label (pecahan tinggi).
const _onBody = [('Rambut', .06), ('Payudara', .22), ('Kulit', .38), ('Bentuk tubuh', .54)];

class _BodyPageState extends ConsumerState<BodyPage> {
  int tab = 0;
  String area = bodyAreas.first;

  @override
  Widget build(BuildContext context) {
    final entries = <JournalEntry>[...(ref.watch(journalProvider).value ?? <JournalEntry>[])]..sort((a, b) => b.at.compareTo(a.at));
    final withBody = entries.where((e) => e.hasBody).toList();
    final latest = <String, (String, DateTime)>{};
    for (final e in withBody) {
      for (final b in e.body.entries) {
        latest.putIfAbsent(b.key, () => (b.value, e.at));
      }
    }
    final fg = Theme.of(context).colorScheme.onSurface;
    final fmtDate = DateFormat('d MMM y', 'id');

    Widget callout(String name, double fy, double w, double h) {
      final l = latest[name];
      return Positioned(
        left: w * .46,
        right: 0,
        top: fy * h - 24,
        child: GestureDetector(
          onTap: () => setState(() {
            area = name;
            tab = 1;
          }),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: C.peony.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(l?.$1 ?? 'Belum ada catatan', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: .65))),
            ]),
          ),
        ),
      );
    }

    Widget otherRow(String name) {
      final l = latest[name];
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: cardBox(context, radius: 20),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: () => setState(() {
            area = name;
            tab = 1;
          }),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(l == null ? 'Belum ada catatan' : '${l.$1}\n${fmtDate.format(l.$2)}'),
          isThreeLine: l != null,
          trailing: Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: .5)),
        ),
      );
    }

    final overview = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(context),
        child: LayoutBuilder(builder: (c, cons) {
          final w = cons.maxWidth;
          const h = 420.0;
          return SizedBox(
            height: h,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _BodyPainter(C.peony))),
              for (final a in _onBody) callout(a.$1, a.$2, w, h),
            ]),
          );
        }),
      ),
      gap(12),
      otherRow('Energi'),
      otherRow('Tidur'),
      gap(4),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.peony.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)),
        child: const Text('Perubahan butuh waktu. Catat apa adanya, lalu bandingkan lagi beberapa minggu kemudian.'),
      ),
    ]);

    final items = [for (final e in withBody) if (e.body.containsKey(area)) (e.at, e.body[area]!)];
    final detail = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final a in bodyAreas) ChoiceChip(label: Text(a), selected: area == a, onSelected: (_) => setState(() => area = a)),
      ]),
      gap(14),
      if (items.isEmpty)
        Text('Belum ada catatan untuk $area. Tambahkan lewat tombol "Catat perubahan".')
      else ...[
        Text('${items.length} catatan, pertama pada ${fmtDate.format(items.last.$1)}', style: Theme.of(context).textTheme.bodySmall),
        gap(10),
        for (final it in items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: cardBox(context, radius: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fmtDate.format(it.$1), style: Theme.of(context).textTheme.bodySmall),
              gap(4),
              Text(it.$2),
            ]),
          ),
      ],
    ]);

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text('Tubuh & perubahan', style: display(28))),
          ]),
          gap(12),
          PillTabs<int>(items: const [(0, 'Ringkasan'), (1, 'Detail')], value: tab, onChanged: (v) => setState(() => tab = v)),
          gap(16),
          if (tab == 0) overview else detail,
          gap(16),
          pillButton('Catat perubahan', () => showSheet(context, const JournalSheet()), icon: Icons.add_rounded),
        ]),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, cx = w * .2, sw = w * .3;
    final fill = Paint()..color = color.withValues(alpha: .26);
    final stroke = Paint()
      ..color = color.withValues(alpha: .26)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, h * .065), h * .05, fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * .12), width: sw * .16, height: h * .05), const Radius.circular(6)), fill);
    final torso = Path()
      ..moveTo(cx - .55 * sw, h * .15)
      ..quadraticBezierTo(cx, h * .12, cx + .55 * sw, h * .15)
      ..cubicTo(cx + .5 * sw, h * .24, cx + .3 * sw, h * .30, cx + .3 * sw, h * .36)
      ..cubicTo(cx + .3 * sw, h * .40, cx + .55 * sw, h * .43, cx + .6 * sw, h * .50)
      ..lineTo(cx - .6 * sw, h * .50)
      ..cubicTo(cx - .55 * sw, h * .43, cx - .3 * sw, h * .40, cx - .3 * sw, h * .36)
      ..cubicTo(cx - .3 * sw, h * .30, cx - .5 * sw, h * .24, cx - .55 * sw, h * .15)
      ..close();
    canvas.drawPath(torso, fill);
    stroke.strokeWidth = sw * .1;
    canvas.drawLine(Offset(cx - .62 * sw, h * .17), Offset(cx - .82 * sw, h * .40), stroke);
    canvas.drawLine(Offset(cx + .62 * sw, h * .17), Offset(cx + .82 * sw, h * .40), stroke);
    stroke.strokeWidth = sw * .24;
    canvas.drawLine(Offset(cx - .27 * sw, h * .52), Offset(cx - .24 * sw, h * .93), stroke);
    canvas.drawLine(Offset(cx + .27 * sw, h * .52), Offset(cx + .24 * sw, h * .93), stroke);

    // titik di tubuh dan garis ke label (urut sama dengan _onBody)
    final labelX = w * .46 - 6;
    final marks = [
      (Offset(cx + h * .05, h * .065), _onBody[0].$2 * h),
      (Offset(cx + .22 * sw, h * .22), _onBody[1].$2 * h),
      (Offset(cx + .82 * sw, h * .33), _onBody[2].$2 * h),
      (Offset(cx + .52 * sw, h * .46), _onBody[3].$2 * h),
    ];
    final line = Paint()
      ..color = color.withValues(alpha: .55)
      ..strokeWidth = 1.5;
    final dot = Paint()..color = color;
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in marks) {
      canvas.drawLine(m.$1, Offset(labelX, m.$2), line);
      canvas.drawCircle(m.$1, 5, dot);
      canvas.drawCircle(m.$1, 5, ring);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter o) => o.color != color;
}
