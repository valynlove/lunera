import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'cycle_insights.dart';
import 'l10n.dart';
import 'models.dart';
import 'schedule.dart';
import 'sim.dart';

class _DoctorReportData {
  const _DoctorReportData({
    required this.generatedText,
    required this.periodText,
    required this.therapyLines,
    required this.adherenceLines,
    required this.labSections,
    required this.estimateLines,
    required this.symptomLines,
  });

  final String generatedText;
  final String periodText;
  final List<String> therapyLines;
  final List<String> adherenceLines;
  final List<(String hormoneName, String? targetLine, List<String> rows)>
      labSections;
  final List<String> estimateLines;
  final List<String> symptomLines;
}

_DoctorReportData _collectDoctorReportData({
  required List<Therapy> therapies,
  required List<DoseLog> logs,
  required List<Lab> labs,
  required Map<String, List<double>> targets,
  required Prefs prefs,
  required DateTime now,
  List<JournalEntry> journal = const [],
  int months = 3,
}) {
  final df = DateFormat('d MMM y', L10n.code);
  final from = DateTime(now.year, now.month - months, now.day);

  final therapyLines = therapies.isEmpty
      ? <String>[tr('None')]
      : <String>[
          for (final t in therapies)
            '${t.name} — ${fmt(t.dose)} ${t.doseUnit}${(t.secondaryHormoneId != null && t.secondaryDose != null) ? ' + ${fmt(t.secondaryDose!)} ${t.secondaryDoseUnit ?? 'mg'} (${presetOf(t.secondaryHormoneId!).name})' : ''}, ${routeOf(t.route).label}, ${scheduleText(t)}',
        ];

  final scheduled = therapies.where((t) => !t.asNeeded).toList();
  final backDays = daysBetween(from, now);
  final slots = scheduled.isEmpty || backDays <= 0
      ? const <Slot>[]
      : [
          for (final s
              in buildSlots(scheduled, logs, prefs, back: backDays, ahead: 0))
            if (!s.at.isBefore(from) && s.at.isBefore(now)) s,
        ];
  final adherenceLines = <String>[];
  for (final t in scheduled) {
    final ts = [
      for (final s in slots)
        if (s.t.id == t.id) s
    ];
    if (ts.isEmpty) continue;
    final taken = ts.where((s) => s.taken).length;
    final skipped = ts.where((s) => s.skipped).length;
    final pct = (taken * 100 / ts.length).round();
    final skipPart = skipped > 0 ? ', ${tr('{0} skipped', [skipped])}' : '';
    adherenceLines.add('${t.name}: $taken / ${ts.length} ($pct%)$skipPart');
  }
  if (adherenceLines.isEmpty) {
    adherenceLines.add(tr('No scheduled doses in this period'));
  }

  final byH = <String, List<Lab>>{};
  for (final l in labs) {
    if (!l.at.isBefore(from) && !l.at.isAfter(now)) {
      (byH[l.hormoneId] ??= []).add(l);
    }
  }
  final labSections =
      <(String hormoneName, String? targetLine, List<String> rows)>[];
  for (final h in byH.keys) {
    final p = presetOf(h);
    final u = prefs.unitOf(h);
    final f = p.units[u] ?? 1.0;
    final band = targets[h];
    final list = byH[h]!..sort((a, b) => b.at.compareTo(a.at));
    final targetLine = band == null
        ? null
        : '${tr('Target')}: ${fmt(band[0] / f)}–${fmt(band[1] / f)} $u';
    final rows = <String>[];
    for (final l in list) {
      var status = '';
      if (band != null && l.cmp == null) {
        final label = (l.base >= band[0] && l.base <= band[1])
            ? tr('In range')
            : (l.base < band[0] ? tr('Below target') : tr('Above target'));
        status = ' ($label)';
      }
      rows.add(
          '${df.format(l.at)} — ${l.prefix}${fmt(l.value)} ${l.unit}$status');
    }
    labSections.add((p.name, targetLine, rows));
  }

  final simIds = <String>{
    for (final t in therapies) ...[
      if (pkOf(t.pk) != null) t.hormoneId,
      if (pkOf(t.secondaryPk) != null && t.secondaryHormoneId != null)
        t.secondaryHormoneId!,
    ]
  };
  final estimateLines = <String>[];
  for (final h in simIds) {
    final xs = intakesFor(h, therapies, logs);
    if (xs.isEmpty) continue;
    final p = presetOf(h);
    final u = prefs.unitOf(h);
    final f = p.units[u] ?? 1.0;
    final v = levelAt(xs, now) / f;
    final valText = h == 'progesterone'
        ? (v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(1))
        : (v >= 20 ? '${v.round()}' : fmt(v));
    estimateLines.add(
        '${p.name}: $valText $u (${tr('model estimate, not a lab result')})');
  }
  if (estimateLines.isEmpty) {
    estimateLines.add(tr('None'));
  }

  final symptomCounts = <String, int>{};
  for (final e in journal) {
    if (!e.at.isBefore(from) && !e.at.isAfter(now)) {
      for (final s in e.symptoms) {
        if (symptomPresets.containsKey(s)) {
          symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
        }
      }
    }
  }
  final symptomLines = [
    for (final entry in symptomPresets.entries)
      if ((symptomCounts[entry.key] ?? 0) > 0)
        '${tr(entry.value.$1)}: ${symptomCounts[entry.key]}x',
  ];

  final cycleReport = analyzeCyclePhaseInsights(
    therapies: therapies,
    logs: logs,
    journal: journal,
    now: now,
    lookbackDays: months * 30,
  );
  if (cycleReport?.clinicianNote != null) {
    symptomLines.add(cycleReport!.clinicianNote!);
  }

  return _DoctorReportData(
    generatedText: tr('Generated: {0}', [df.format(now)]),
    periodText: tr('Period: {0} to {1}', [df.format(from), df.format(now)]),
    therapyLines: therapyLines,
    adherenceLines: adherenceLines,
    labSections: labSections,
    estimateLines: estimateLines,
    symptomLines: symptomLines,
  );
}

/// Membuat ringkasan teks Markdown untuk diskusi konsultasi dokter/endokrinolog.
/// Hanya menyertakan data klinis terstruktur & check-in gejala terstruktur; catatan bebas,
/// isi jurnal teks, stok, ukuran tubuh, dan email akun sengaja dikecualikan demi privasi.
String buildDoctorReport({
  required List<Therapy> therapies,
  required List<DoseLog> logs,
  required List<Lab> labs,
  required Map<String, List<double>> targets,
  required Prefs prefs,
  required DateTime now,
  List<JournalEntry> journal = const [],
  int months = 3,
  List<String> consultationQuestions = const [],
}) {
  final d = _collectDoctorReportData(
    therapies: therapies,
    logs: logs,
    labs: labs,
    targets: targets,
    prefs: prefs,
    now: now,
    journal: journal,
    months: months,
  );

  final buf = StringBuffer()
    ..writeln('# Lunera — ${tr('Doctor visit summary')}')
    ..writeln(d.generatedText)
    ..writeln(d.periodText)
    ..writeln()
    ..writeln('## ${tr('Active therapies')}');
  for (final line in d.therapyLines) {
    buf.writeln('- $line');
  }
  buf
    ..writeln()
    ..writeln('## ${tr('Adherence')}');
  for (final line in d.adherenceLines) {
    buf.writeln('- $line');
  }
  buf
    ..writeln()
    ..writeln('## ${tr('Lab results in period')}');
  if (d.labSections.isEmpty) {
    buf.writeln('- ${tr('No lab results in this period')}');
  } else {
    for (final sec in d.labSections) {
      buf.writeln('### ${sec.$1}');
      if (sec.$2 != null) buf.writeln('- ${sec.$2}');
      for (final row in sec.$3) {
        buf.writeln('- $row');
      }
    }
  }
  buf
    ..writeln()
    ..writeln('## ${tr('Model estimates now')}');
  for (final line in d.estimateLines) {
    buf.writeln('- $line');
  }
  if (d.symptomLines.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## ${tr('Reported symptoms & check-ins')}');
    for (final line in d.symptomLines) {
      buf.writeln('- $line');
    }
  }
  if (consultationQuestions.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## ${tr('Prepared Consultation Questions')}');
    for (final q in consultationQuestions) {
      buf.writeln('- $q');
    }
  }
  buf
    ..writeln()
    ..writeln('---')
    ..writeln(
        '_${tr('Generated by Lunera for discussion with your clinician. Estimates are statistical models, not diagnoses.')}_');

  return buf.toString().trimRight();
}

String _pdfSafe(String s) {
  final replaced = s
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('•', '-')
      .replaceAll('µ', 'u')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"');
  final buf = StringBuffer();
  for (final rune in replaced.runes) {
    if (rune >= 32 && rune <= 126) {
      buf.writeCharCode(rune);
    } else if (rune >= 160 && rune <= 255) {
      buf.writeCharCode(rune);
    } else {
      buf.write(' ');
    }
  }
  return buf.toString();
}

String _pdfEscape(String s) => _pdfSafe(s)
    .replaceAll('\\', '\\\\')
    .replaceAll('(', '\\(')
    .replaceAll(')', '\\)');

List<String> _wrapLine(String text, int maxChars) {
  final clean = _pdfSafe(text).trim();
  if (clean.length <= maxChars) return [clean];
  final words = clean.split(RegExp(r'\s+'));
  final lines = <String>[];
  var current = StringBuffer();
  for (final w in words) {
    if (current.isEmpty) {
      current.write(w);
    } else if (current.length + 1 + w.length <= maxChars) {
      current.write(' $w');
    } else {
      lines.add(current.toString());
      current = StringBuffer(w);
    }
  }
  if (current.isNotEmpty) lines.add(current.toString());
  return lines;
}

class _PdfLine {
  const _PdfLine(this.text,
      {this.bold = false, this.size = 10.5, this.gap = 4});
  final String text;
  final bool bold;
  final double size;
  final double gap;
}

/// Generates an A4 print-ready PDF 1.4 version of the Doctor Visit Summary
/// using pure Dart with zero external PDF/image dependencies, strictly excluding
/// private notes, free-text journal entries, supplies, and measurements.
Future<Uint8List> buildDoctorReportPdf({
  required List<Therapy> therapies,
  required List<DoseLog> logs,
  required List<Lab> labs,
  required Map<String, List<double>> targets,
  required Prefs prefs,
  required DateTime now,
  List<JournalEntry> journal = const [],
  int months = 3,
  List<String> consultationQuestions = const [],
}) async {
  final d = _collectDoctorReportData(
    therapies: therapies,
    logs: logs,
    labs: labs,
    targets: targets,
    prefs: prefs,
    now: now,
    journal: journal,
    months: months,
  );

  final items = <_PdfLine>[
    _PdfLine('Lunera - ${tr('Doctor visit summary')}',
        bold: true, size: 17, gap: 6),
    _PdfLine('${d.generatedText}   |   ${d.periodText}', size: 9.5, gap: 10),
    const _PdfLine(
        '--------------------------------------------------------------------------------',
        size: 9,
        gap: 8),
    _PdfLine(tr('Active therapies'), bold: true, size: 12.5, gap: 4),
    for (final line in d.therapyLines) _PdfLine('- $line'),
    const _PdfLine('', gap: 6),
    _PdfLine(tr('Adherence'), bold: true, size: 12.5, gap: 4),
    for (final line in d.adherenceLines) _PdfLine('- $line'),
    const _PdfLine('', gap: 6),
    _PdfLine(tr('Lab results in period'), bold: true, size: 12.5, gap: 4),
    if (d.labSections.isEmpty)
      _PdfLine('- ${tr('No lab results in this period')}')
    else
      for (final sec in d.labSections) ...[
        _PdfLine(sec.$1, bold: true, size: 11, gap: 3),
        if (sec.$2 != null) _PdfLine('- ${sec.$2}'),
        for (final row in sec.$3) _PdfLine('- $row'),
      ],
    const _PdfLine('', gap: 6),
    _PdfLine(tr('Model estimates now'), bold: true, size: 12.5, gap: 4),
    for (final line in d.estimateLines) _PdfLine('- $line'),
    if (d.symptomLines.isNotEmpty) ...[
      const _PdfLine('', gap: 6),
      _PdfLine(tr('Reported symptoms & check-ins'),
          bold: true, size: 12.5, gap: 4),
      for (final line in d.symptomLines) _PdfLine('- $line'),
    ],
    if (consultationQuestions.isNotEmpty) ...[
      const _PdfLine('', gap: 6),
      _PdfLine(tr('Prepared Consultation Questions'),
          bold: true, size: 12.5, gap: 4),
      for (final q in consultationQuestions) _PdfLine('- $q'),
    ],
    const _PdfLine('', gap: 10),
    const _PdfLine(
        '--------------------------------------------------------------------------------',
        size: 9,
        gap: 6),
    _PdfLine(
      tr('Generated by Lunera for discussion with your clinician. Estimates are statistical models, not diagnoses.'),
      size: 9,
      gap: 4,
    ),
  ];

  // Paginate onto A4 pages (595 x 842 pt)
  final pages = <String>[];
  var pageBuf = StringBuffer();
  var y = 788.0;

  void flushPage() {
    pages.add(pageBuf.toString());
    pageBuf = StringBuffer();
    y = 788.0;
  }

  for (final item in items) {
    if (item.text.isEmpty) {
      y -= item.gap;
      if (y < 60) flushPage();
      continue;
    }
    final maxChars = item.size >= 15 ? 58 : (item.size >= 12 ? 72 : 84);
    final wrapped = _wrapLine(item.text, maxChars);
    final lineHeight = item.size * 1.35;
    for (var i = 0; i < wrapped.length; i++) {
      if (y < 60) flushPage();
      final font = item.bold ? '/F2' : '/F1';
      pageBuf.writeln(
          'BT $font ${item.size.toStringAsFixed(1)} Tf 48 ${y.toStringAsFixed(1)} Td (${_pdfEscape(wrapped[i])}) Tj ET');
      y -= lineHeight;
    }
    y -= item.gap;
  }
  if (pageBuf.isNotEmpty || pages.isEmpty) {
    pages.add(pageBuf.toString());
  }

  // Assemble PDF 1.4 binary with exact xref byte offsets
  final out = BytesBuilder();
  void writeStr(String s) => out.add(latin1.encode(s));

  writeStr('%PDF-1.4\n');
  final offsets = <int>[];

  int addObj(String body) {
    offsets.add(out.length);
    final id = offsets.length;
    writeStr('$id 0 obj\n$body\nendobj\n');
    return id;
  }

  final kidsRefs = [for (var p = 0; p < pages.length; p++) '${5 + p * 2} 0 R'];
  addObj('<< /Type /Catalog /Pages 2 0 R >>');
  addObj(
      '<< /Type /Pages /Kids [${kidsRefs.join(' ')}] /Count ${pages.length} >>');
  addObj(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
  addObj(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');

  for (var p = 0; p < pages.length; p++) {
    final pageObjId = 5 + p * 2;
    final contentObjId = pageObjId + 1;
    addObj(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents $contentObjId 0 R >>');
    final streamBytes = latin1.encode(pages[p]);
    offsets.add(out.length);
    final objNum = offsets.length;
    writeStr('$objNum 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    out.add(streamBytes);
    writeStr('\nendstream\nendobj\n');
  }

  final xrefOffset = out.length;
  writeStr('xref\n0 ${offsets.length + 1}\n');
  writeStr('0000000000 65535 f \n');
  for (final off in offsets) {
    writeStr('${off.toString().padLeft(10, '0')} 00000 n \n');
  }
  writeStr('trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\n');
  writeStr('startxref\n$xrefOffset\n%%EOF\n');

  return out.toBytes();
}
