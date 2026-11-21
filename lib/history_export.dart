import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n.dart';
import 'lock.dart';
import 'models.dart';
import 'repo.dart';
import 'theme.dart';

const _formulaPrefixes = {'=', '+', '-', '@', '\t', '\r'};

String _csvCell(String raw, {bool sanitizeFormula = true}) {
  var value = raw;
  if (sanitizeFormula &&
      value.isNotEmpty &&
      _formulaPrefixes.contains(value[0])) {
    value = "'$value";
  }
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _unescapeFormula(String cell) {
  if (cell.length >= 2 &&
      cell.startsWith("'") &&
      _formulaPrefixes.contains(cell[1])) {
    return cell.substring(1);
  }
  return cell;
}

({
  String therapy,
  String route,
  String? injType,
  String status,
  double? dose,
  String? doseUnit,
  double? secondaryDose,
  String? secondaryDoseUnit,
}) _describeLog(DoseLog l, Therapy? t) {
  final rawInjType = l.injType ?? (t?.route == 'injection' ? t?.injType : null);
  final injType =
      (rawInjType == null || rawInjType.isEmpty) ? null : rawInjType;
  final hasSecondary =
      !l.skipped && (t?.secondaryHormoneId != null || l.secondaryDose != null);
  final secVal = hasSecondary ? (l.secondaryDose ?? t?.secondaryDose) : null;
  return (
    therapy: t?.name ?? 'Therapy deleted',
    route: t?.route ?? '',
    injType: injType,
    status: l.skipped ? 'skipped' : 'taken',
    dose: l.skipped ? null : (l.dose ?? t?.dose ?? 0),
    doseUnit: l.skipped ? null : (t?.doseUnit ?? ''),
    secondaryDose: secVal,
    secondaryDoseUnit: secVal != null ? (t?.secondaryDoseUnit ?? 'mg') : null,
  );
}

/// Formats dose administration history as RFC 4180 CSV with formula-injection protection.
String exportDoseHistoryCsv(List<DoseLog> logs, List<Therapy> therapies) {
  final sorted = [...logs]..sort((a, b) => b.at.compareTo(a.at));
  final byId = {for (final t in therapies) t.id: t};
  final rows = <String>[
    'date,time,timestamp,therapy,route,injection_type,status,dose,dose_unit,secondary_dose,secondary_dose_unit,sites,note',
  ];

  for (final l in sorted) {
    final info = _describeLog(l, byId[l.therapyId]);
    rows.add([
      DateFormat('yyyy-MM-dd').format(l.at),
      DateFormat('HH:mm').format(l.at),
      l.at.toIso8601String(),
      _csvCell(info.therapy),
      _csvCell(info.route),
      _csvCell(info.injType ?? ''),
      info.status,
      info.dose == null ? '' : fmt(info.dose!),
      _csvCell(info.doseUnit ?? '', sanitizeFormula: false),
      info.secondaryDose == null ? '' : fmt(info.secondaryDose!),
      _csvCell(info.secondaryDoseUnit ?? '', sanitizeFormula: false),
      _csvCell(l.places.join('; ')),
      _csvCell(l.note ?? ''),
    ].join(','));
  }

  return rows.join('\r\n');
}

/// Formats dose administration history as a standalone JSON document distinct from full backups.
String exportDoseHistoryJson(List<DoseLog> logs, List<Therapy> therapies,
    {DateTime? now}) {
  final sorted = [...logs]..sort((a, b) => b.at.compareTo(a.at));
  final byId = {for (final t in therapies) t.id: t};

  final entries = <Map<String, dynamic>>[];
  for (final l in sorted) {
    final info = _describeLog(l, byId[l.therapyId]);
    entries.add({
      'id': l.id,
      'timestamp': l.at.toIso8601String(),
      'date': DateFormat('yyyy-MM-dd').format(l.at),
      'time': DateFormat('HH:mm').format(l.at),
      'therapy': info.therapy,
      'therapy_id': l.therapyId,
      'route': info.route,
      'injection_type': info.injType,
      'status': info.status,
      'dose': info.dose,
      'dose_unit': info.doseUnit,
      'secondary_dose': info.secondaryDose,
      'secondary_dose_unit': info.secondaryDoseUnit,
      'sites': l.places,
      'note': l.note,
    });
  }

  return const JsonEncoder.withIndent('  ').convert({
    'metadata': {
      'app': 'lunera',
      'export_type': 'dose_history',
      'version': 1,
      'exported_at': (now ?? DateTime.now()).toIso8601String(),
      'count': entries.length,
    },
    'entries': entries,
  });
}

/// Result of parsing and merging a standalone CSV or JSON dose history file.
class DoseHistoryImportResult {
  const DoseHistoryImportResult({
    required this.logs,
    required this.newCount,
    required this.updatedCount,
  });

  final List<DoseLog> logs;
  final int newCount;
  final int updatedCount;
}

typedef _RawHistoryEntry = ({
  String? id,
  String? therapyId,
  String? therapyName,
  DateTime at,
  List<String> places,
  double? dose,
  double? secondaryDose,
  String? injType,
  String? note,
  bool skipped,
});

/// Parses a Lunera dose history export (JSON `dose_history` or CSV) and prepares logs for merge import.
DoseHistoryImportResult parseDoseHistoryImport(
  String rawContent, {
  required List<Therapy> therapies,
  required List<DoseLog> existingLogs,
}) {
  var content = rawContent;
  if (content.startsWith('\uFEFF')) {
    content = content.substring(1);
  }
  content = content.trim();
  if (content.isEmpty) {
    throw FormatException(tr('Invalid dose history file.'));
  }

  final parsedEntries = (content.startsWith('{') || content.startsWith('['))
      ? _parseDoseHistoryJson(content)
      : _parseDoseHistoryCsv(content);

  if (parsedEntries.isEmpty) {
    throw FormatException(tr('No dose history entries found in file.'));
  }

  final byTherapyId = {for (final t in therapies) t.id: t};
  final byTherapyNameLower = {
    for (final t in therapies) t.name.trim().toLowerCase(): t,
  };

  final existingById = {for (final l in existingLogs) l.id: l};
  final existingByKey = {
    for (final l in existingLogs)
      '${l.therapyId}|${l.at.millisecondsSinceEpoch}': l,
  };
  final existingByMinuteKey = {
    for (final l in existingLogs)
      '${l.therapyId}|${l.at.year}-${l.at.month}-${l.at.day} ${l.at.hour}:${l.at.minute}':
          l,
  };

  final mergedById = <String, DoseLog>{};
  final matchedExistingIds = <String>{};

  for (var i = 0; i < parsedEntries.length; i++) {
    final entry = parsedEntries[i];
    final therapyId = _resolveTherapyId(
      entry.therapyId,
      entry.therapyName,
      byId: byTherapyId,
      byNameLower: byTherapyNameLower,
    );

    final rawId = entry.id?.trim();
    DoseLog? existing;
    if (rawId != null && rawId.isNotEmpty) {
      existing = existingById[rawId];
    }
    existing ??= existingByKey['$therapyId|${entry.at.millisecondsSinceEpoch}'];
    if (existing == null && entry.at.second == 0 && entry.at.millisecond == 0) {
      existing = existingByMinuteKey[
          '$therapyId|${entry.at.year}-${entry.at.month}-${entry.at.day} ${entry.at.hour}:${entry.at.minute}'];
    }

    final String id;
    if (existing != null) {
      id = existing.id;
      matchedExistingIds.add(id);
    } else if (rawId != null && rawId.isNotEmpty) {
      id = rawId;
    } else {
      id =
          'hist_${entry.at.millisecondsSinceEpoch}_${therapyId.hashCode.abs()}_$i';
    }

    mergedById[id] = DoseLog(
      id: id,
      therapyId: therapyId,
      at: entry.at,
      places: entry.places,
      dose: entry.dose,
      secondaryDose: entry.secondaryDose,
      note: entry.note,
      wasted: existing?.wasted,
      dead: existing?.dead,
      injType: entry.injType,
      slot: existing?.slot,
      usedSupplies: existing?.usedSupplies ?? const {},
      skipped: entry.skipped,
    );
  }

  final logs = mergedById.values.toList();
  final updatedCount = matchedExistingIds.length;
  final newCount = logs.length - updatedCount;

  return DoseHistoryImportResult(
    logs: logs,
    newCount: newCount,
    updatedCount: updatedCount,
  );
}

String _resolveTherapyId(
  String? rawTherapyId,
  String? rawTherapyName, {
  required Map<String, Therapy> byId,
  required Map<String, Therapy> byNameLower,
}) {
  final tid = rawTherapyId?.trim();
  if (tid != null && tid.isNotEmpty && byId.containsKey(tid)) {
    return tid;
  }
  final name = (rawTherapyName ?? '').trim();
  final nameLower = name.toLowerCase();
  if (name.isNotEmpty && nameLower != 'therapy deleted') {
    final matched = byNameLower[nameLower];
    if (matched != null) {
      return matched.id;
    }
  }
  if (tid != null && tid.isNotEmpty) {
    return tid;
  }
  final slug = nameLower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return (slug.isEmpty || slug == 'therapy_deleted')
      ? 'deleted_therapy'
      : 'deleted_$slug';
}

DateTime _parseEntryTimestamp(String? tsStr, String? dateStr, String? timeStr) {
  final ts = tsStr?.trim() ?? '';
  if (ts.isNotEmpty) {
    final parsed = DateTime.tryParse(ts);
    if (parsed != null) return parsed;
    throw FormatException(tr('Invalid timestamp in dose history file.'));
  }

  final dStr = dateStr?.trim() ?? '';
  if (dStr.isNotEmpty) {
    final d = DateTime.tryParse(dStr);
    if (d != null) {
      final tStr = timeStr?.trim() ?? '';
      if (tStr.isEmpty) {
        return DateTime(d.year, d.month, d.day);
      }
      final m = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(tStr);
      if (m != null) {
        final hour = int.parse(m[1]!);
        final minute = int.parse(m[2]!);
        final second = m[3] != null ? int.parse(m[3]!) : 0;
        if (hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59 &&
            second >= 0 &&
            second <= 59) {
          return DateTime(d.year, d.month, d.day, hour, minute, second);
        }
      }
    }
  }

  throw FormatException(tr('Invalid timestamp in dose history file.'));
}

double? _parseDoseNumber(dynamic raw) {
  if (raw == null) return null;
  final double? value;
  if (raw is num) {
    value = raw.toDouble();
  } else if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    value = double.tryParse(s.replaceAll(',', '.'));
  } else {
    throw FormatException(tr('Invalid dose value in history file.'));
  }

  if (value == null || !value.isFinite || value < 0) {
    throw FormatException(tr('Invalid dose value in history file.'));
  }
  return value;
}

List<_RawHistoryEntry> _parseDoseHistoryJson(String content) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(content);
  } catch (_) {
    throw FormatException(tr('Invalid dose history file.'));
  }

  if (decoded is! Map) {
    throw FormatException(tr('Invalid dose history file.'));
  }
  if (decoded['data'] is Map) {
    throw FormatException(
      tr('This is a full backup file. Use "Import backup file (JSON)" in Settings instead.'),
    );
  }

  final meta = decoded['metadata'];
  final entriesRaw = decoded['entries'];
  if (meta is! Map ||
      meta['app'] != 'lunera' ||
      meta['export_type'] != 'dose_history' ||
      entriesRaw is! List) {
    throw FormatException(tr('Invalid dose history file.'));
  }

  final out = <_RawHistoryEntry>[];
  for (final item in entriesRaw) {
    if (item is! Map) {
      throw FormatException(tr('Invalid dose history file.'));
    }

    final idVal = item['id'];
    if (idVal != null && idVal is! String) {
      throw FormatException(tr('Invalid dose history file.'));
    }

    final therapyIdVal = item['therapy_id'];
    if (therapyIdVal != null && therapyIdVal is! String) {
      throw FormatException(tr('Invalid dose history file.'));
    }

    final therapyVal = item['therapy'];
    if (therapyVal != null && therapyVal is! String) {
      throw FormatException(tr('Invalid dose history file.'));
    }

    final at = _parseEntryTimestamp(
      item['timestamp'] as String?,
      item['date'] as String?,
      item['time'] as String?,
    );

    final statusVal = '${item['status'] ?? ''}'.trim().toLowerCase();
    final skipped = item['skipped'] == true || statusVal == 'skipped';

    final dose = skipped ? null : _parseDoseNumber(item['dose']);
    final secondaryDose =
        skipped ? null : _parseDoseNumber(item['secondary_dose']);

    final injTypeVal = item['injection_type'];
    if (injTypeVal != null && injTypeVal is! String) {
      throw FormatException(tr('Invalid dose history file.'));
    }
    final injType = (injTypeVal as String?)?.trim();

    final sitesVal = item['sites'];
    final places = <String>[];
    if (sitesVal != null) {
      if (sitesVal is! List) {
        throw FormatException(tr('Invalid dose history file.'));
      }
      for (final s in sitesVal) {
        final str = '$s'.trim();
        if (str.isNotEmpty) places.add(str);
      }
    }

    final noteVal = item['note'];
    if (noteVal != null && noteVal is! String) {
      throw FormatException(tr('Invalid dose history file.'));
    }
    final note = (noteVal == null || noteVal.isEmpty) ? null : noteVal;

    out.add((
      id: idVal as String?,
      therapyId: therapyIdVal as String?,
      therapyName: therapyVal as String?,
      at: at,
      places: places,
      dose: dose,
      secondaryDose: secondaryDose,
      injType: (injType == null || injType.isEmpty) ? null : injType,
      note: note,
      skipped: skipped,
    ));
  }

  return out;
}

List<List<String>> _parseCsvTable(String input) {
  final rows = <List<String>>[];
  var currentRow = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  var fieldQuoted = false;

  void finishCell() {
    currentRow.add(cell.toString());
    cell.clear();
    fieldQuoted = false;
  }

  void finishRow() {
    finishCell();
    if (currentRow.any((c) => c.isNotEmpty)) {
      rows.add(currentRow);
    }
    currentRow = <String>[];
  }

  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
    } else {
      if (ch == '"' && cell.isEmpty && !fieldQuoted) {
        inQuotes = true;
        fieldQuoted = true;
      } else if (ch == ',') {
        finishCell();
      } else if (ch == '\r') {
        if (i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        finishRow();
      } else if (ch == '\n') {
        finishRow();
      } else {
        cell.write(ch);
      }
    }
  }

  if (inQuotes) {
    throw FormatException(tr('Invalid dose history file.'));
  }
  if (cell.isNotEmpty || currentRow.isNotEmpty || fieldQuoted) {
    finishRow();
  }
  return rows;
}

List<_RawHistoryEntry> _parseDoseHistoryCsv(String content) {
  final table = _parseCsvTable(content);
  if (table.isEmpty) {
    throw FormatException(tr('Invalid dose history CSV header.'));
  }

  final header = table.first;
  final cols = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    cols[header[i].trim().toLowerCase()] = i;
  }

  final hasTherapy = cols.containsKey('therapy');
  final hasTimestamp = cols.containsKey('timestamp');
  final hasDateAndTime = cols.containsKey('date') && cols.containsKey('time');
  if (!hasTherapy || (!hasTimestamp && !hasDateAndTime)) {
    throw FormatException(tr('Invalid dose history CSV header.'));
  }

  String cellAt(List<String> row, String name) {
    final idx = cols[name];
    if (idx == null || idx >= row.length) return '';
    return row[idx];
  }

  final out = <_RawHistoryEntry>[];
  for (var r = 1; r < table.length; r++) {
    final row = table[r];
    if (row.every((c) => c.trim().isEmpty)) continue;

    final therapyName = _unescapeFormula(cellAt(row, 'therapy')).trim();
    final injTypeRaw = _unescapeFormula(cellAt(row, 'injection_type')).trim();
    final status = cellAt(row, 'status').trim().toLowerCase();
    final skipped = status == 'skipped';

    final at = _parseEntryTimestamp(
      cellAt(row, 'timestamp'),
      cellAt(row, 'date'),
      cellAt(row, 'time'),
    );

    final dose = skipped ? null : _parseDoseNumber(cellAt(row, 'dose'));
    final secondaryDose =
        skipped ? null : _parseDoseNumber(cellAt(row, 'secondary_dose'));

    final sitesRaw = _unescapeFormula(cellAt(row, 'sites'));
    final places = [
      for (final part in sitesRaw.split(';'))
        if (part.trim().isNotEmpty) part.trim(),
    ];

    final noteRaw = _unescapeFormula(cellAt(row, 'note'));
    final note = noteRaw.isEmpty ? null : noteRaw;

    out.add((
      id: null,
      therapyId: null,
      therapyName: therapyName,
      at: at,
      places: places,
      dose: dose,
      secondaryDose: secondaryDose,
      injType: injTypeRaw.isEmpty ? null : injTypeRaw,
      note: note,
      skipped: skipped,
    ));
  }

  return out;
}

/// Prompts the user to pick a CSV or JSON history file, previews merge counts, and imports logs.
Future<void> importDoseHistoryFile(BuildContext context, WidgetRef ref) async {
  const group = XTypeGroup(label: 'CSV / JSON', extensions: ['csv', 'json']);
  final onAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  try {
    final f = await Lock.instance.suppressLockDuring(
      () => openFile(acceptedTypeGroups: onAndroid ? const [] : const [group]),
    );
    if (f == null || !context.mounted) return;

    final rawContent = utf8.decode(await f.readAsBytes());
    final res = parseDoseHistoryImport(
      rawContent,
      therapies: ref.read(therapiesProvider).value ?? const [],
      existingLogs: ref.read(logsProvider).value ?? const [],
    );

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(tr(
                'Import {0} {0?dose entry|dose entries}?', [res.logs.length])),
            content: Text(
              tr(
                'Merge into your dose history ({0} new, {1} updated). Existing history and supply stock will not be removed.',
                [res.newCount, res.updatedCount],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(d, false),
                  child: Text(tr('Cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(d, true),
                  child: Text(tr('Import'))),
            ],
          ),
        ) ??
        false;
    if (!ok || !context.mounted) return;

    await ref.read(repoProvider)?.importDoseLogs(res.logs);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
              'Imported {0} {0?dose entry|dose entries}.', [res.logs.length])),
        ),
      );
    }
  } on FormatException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Failed: {0}', [e]))),
      );
    }
  }
}

/// Prompts the user to choose CSV or JSON and shares/downloads their dose history.
Future<void> showHistoryExportSheet(
  BuildContext context,
  List<DoseLog> logs,
  List<Therapy> therapies,
) async {
  if (logs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('No dose history to export yet.'))),
    );
    return;
  }

  final format = await showSheet<String>(
    context,
    _HistoryExportFormatSheet(count: logs.length),
  );
  if (format == null || !context.mounted) return;

  final isCsv = format == 'csv';
  final text = isCsv
      ? exportDoseHistoryCsv(logs, therapies)
      : exportDoseHistoryJson(logs, therapies);
  final ext = isCsv ? 'csv' : 'json';
  final mimeType = isCsv ? 'text/csv' : 'application/json';
  final name =
      'lunera_history_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.$ext';

  try {
    final f = XFile.fromData(
      Uint8List.fromList(utf8.encode(text)),
      mimeType: mimeType,
      name: name,
    );
    if (kIsWeb) {
      await f.saveTo(name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('File downloaded.'))),
        );
      }
    } else {
      await Lock.instance.suppressLockDuring(
        () => Share.shareXFiles([f], fileNameOverrides: [name]),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Failed: {0}', [e]))),
      );
    }
  }
}

class _HistoryExportFormatSheet extends StatelessWidget {
  const _HistoryExportFormatSheet({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Export Dose History'), style: display(26)),
        const SizedBox(height: 6),
        Text(
          tr('{0} {0?entry|entries} ready to export.', [count]),
          style: TextStyle(
              fontSize: 13, color: Pastel.mist.withValues(alpha: 0.85)),
        ),
        gap(16),
        _FormatOptionTile(
          icon: LucideIcons.upload,
          color: Pastel.mint,
          title: tr('Spreadsheet (CSV)'),
          subtitle:
              tr('Best for Excel, Google Sheets, or sharing with a doctor.'),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, 'csv');
          },
        ),
        gap(10),
        _FormatOptionTile(
          icon: LucideIcons.code,
          color: Pastel.sky,
          title: tr('Structured Data (JSON)'),
          subtitle: tr('Machine-readable dose history file.'),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, 'json');
          },
        ),
      ],
    );
  }
}

class _FormatOptionTile extends StatelessWidget {
  const _FormatOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardBox(context, radius: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: iconBadge(icon, color),
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
                fontSize: 12, color: Pastel.mist.withValues(alpha: 0.8)),
          ),
          trailing: const Icon(LucideIcons.chevronRight,
              size: 18, color: C.iconDefault),
          onTap: onTap,
        ),
      ),
    );
  }
}
