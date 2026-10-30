import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData, Icons;

DateTime _d(dynamic t) => (t as Timestamp).toDate();
Timestamp _t(DateTime d) => Timestamp.fromDate(d);
String fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

/// Hormon untuk hasil lab. `units`: satuan -> faktor ke satuan dasar (satuan pertama).
class HormonePreset {
  const HormonePreset(this.id, this.name, this.units);
  final String id, name;
  final Map<String, double> units;
  String get base => units.keys.first;
  double toBase(double v, String u) => v * (units[u] ?? 1);
}

const presets = <HormonePreset>[
  HormonePreset('estradiol', 'Estradiol', {'pg/mL': 1, 'pmol/L': 1 / 3.671}),
  HormonePreset('testosterone', 'Testosteron', {'ng/dL': 1, 'ng/mL': 100, 'nmol/L': 28.84}),
  HormonePreset('progesterone', 'Progesteron', {'ng/mL': 1, 'nmol/L': 1 / 3.18}),
  HormonePreset('lh', 'LH', {'IU/L': 1, 'mIU/mL': 1}),
  HormonePreset('fsh', 'FSH', {'IU/L': 1, 'mIU/mL': 1}),
  HormonePreset('prolactin', 'Prolaktin', {'ng/mL': 1, 'mIU/L': 1 / 21.2}),
];
HormonePreset presetOf(String id) => presets.firstWhere((p) => p.id == id, orElse: () => presets.first);

/// Cara pemakaian obat. `places`: butuh lokasi (suntik, patch).
class AdminRoute {
  const AdminRoute(this.id, this.label, this.icon, {this.places = false});
  final String id, label;
  final IconData icon;
  final bool places;
}

const routes = <AdminRoute>[
  AdminRoute('inj', 'Injection', Icons.vaccines_rounded, places: true),
  AdminRoute('oral', 'Oral', Icons.medication_rounded),
  AdminRoute('sublingual', 'Sublingual', Icons.medication_liquid_rounded),
  AdminRoute('patch', 'Patch', Icons.sticky_note_2_rounded, places: true),
  AdminRoute('gel', 'Gel', Icons.sanitizer_rounded),
  AdminRoute('implant', 'Implant', Icons.push_pin_rounded),
  AdminRoute('supp', 'Suppository', Icons.medication_rounded),
  AdminRoute('spray', 'Spray', Icons.water_drop_rounded),
  AdminRoute('drops', 'Drops', Icons.opacity_rounded),
];
AdminRoute routeOf(String id) => routes.firstWhere((r) => r.id == id, orElse: () => routes.first);

const genericTypes = <String, (String, IconData)>{
  'syringe': ('Syringe', Icons.vaccines_rounded),
  'wipe': ('Alcohol wipe', Icons.cleaning_services_rounded),
  'needle': ('Needle', Icons.push_pin_rounded),
  'gloves': ('Gloves', Icons.back_hand_rounded),
  'bandage': ('Bandage', Icons.healing_rounded),
};

const defaultPlaces = ['Paha kiri', 'Paha kanan', 'Bokong kiri', 'Bokong kanan'];
const placePresets = [
  'Paha kiri', 'Paha kanan', 'Lengan kiri', 'Lengan kanan', 'Bokong kiri', 'Bokong kanan', 'Perut kiri', 'Perut kanan'
];

/// Jadwal: kind = interval (1 hari = setiap hari) | weekly | monthly | asneeded.
class Therapy {
  const Therapy({
    required this.id,
    required this.hormoneId,
    required this.name,
    required this.dose,
    required this.doseUnit,
    required this.start,
    this.everyDays = 1,
    this.supplyId,
    this.route = 'inj',
    this.pk,
    this.kind = 'interval',
    this.weekdays = const [],
    this.monthDay = 1,
    this.times = const ['09:00'],
    this.injType,
    this.rolling = false,
  });
  final String id, hormoneId, name, doseUnit, route, kind;
  final double dose;
  final int everyDays, monthDay;
  final DateTime start;
  final String? supplyId, pk, injType;
  final List<int> weekdays; // 1 = Senin ... 7 = Minggu
  final List<String> times; // 'HH:mm'
  final bool rolling; // jadwal berikutnya dihitung dari dosis terakhir (hanya interval 2 hari atau lebih)
  AdminRoute get adm => routeOf(route);
  bool get asNeeded => kind == 'asneeded';
  bool get daily => kind == 'interval' && everyDays == 1;

  Map<String, dynamic> toMap() => {
        'hormoneId': hormoneId,
        'name': name,
        'dose': dose,
        'doseUnit': doseUnit,
        'everyDays': everyDays,
        'start': _t(start),
        'supplyId': supplyId,
        'route': route,
        'pk': pk,
        'kind': kind,
        'weekdays': weekdays,
        'monthDay': monthDay,
        'times': times,
        'injType': injType,
        'rolling': rolling,
      };

  factory Therapy.from(String id, Map<String, dynamic> m) => Therapy(
        id: id,
        hormoneId: m['hormoneId'] ?? 'other',
        name: m['name'] ?? '',
        dose: (m['dose'] as num).toDouble(),
        doseUnit: m['doseUnit'] ?? 'mg',
        everyDays: (m['everyDays'] as num?)?.toInt() ?? 1,
        start: _d(m['start']),
        supplyId: m['supplyId'],
        route: m['route'] ?? 'inj',
        pk: m['pk'],
        kind: m['kind'] ?? 'interval',
        weekdays: m['weekdays'] is List ? [for (final x in m['weekdays'] as List) (x as num).toInt()] : const <int>[],
        monthDay: (m['monthDay'] as num?)?.toInt() ?? 1,
        times: m['times'] is List ? [for (final x in m['times'] as List) x as String] : const ['09:00'],
        injType: m['injType'],
        rolling: m['rolling'] ?? ((m['kind'] ?? 'interval') == 'interval' && ((m['everyDays'] as num?)?.toInt() ?? 1) > 1),
      );
}

class DoseLog {
  const DoseLog({
    required this.id,
    required this.therapyId,
    required this.at,
    this.places = const [],
    this.dose,
    this.note,
    this.wasted,
    this.dead,
    this.injType,
    this.slot,
    this.used = const {},
    this.skipped = false,
  });
  final String id, therapyId;
  final DateTime at;
  final List<String> places;
  final double? dose, wasted, dead; // wasted: mL, dead: µL
  final String? note, injType, slot; // slot: 'yyyy-MM-dd HH:mm' jadwal yang dipenuhi
  final Map<String, double> used; // id stok -> jumlah yang terpakai
  final bool skipped; // dosis sengaja dilewati (tidak dihitung sebagai dosis)
  String get site => places.isEmpty ? '' : places.first;

  Map<String, dynamic> toMap() => {
        'therapyId': therapyId,
        'at': _t(at),
        'site': site,
        'places': places,
        'dose': dose,
        'note': note,
        'wasted': wasted,
        'dead': dead,
        'injType': injType,
        'slot': slot,
        'used': used,
        'skipped': skipped,
      };

  factory DoseLog.from(String id, Map<String, dynamic> m) => DoseLog(
        id: id,
        therapyId: m['therapyId'],
        at: _d(m['at']),
        places: m['places'] is List
            ? [for (final x in m['places'] as List) x as String]
            : (m['site'] is String && m['site'] != '' && m['site'] != 'oral' ? [m['site'] as String] : <String>[]),
        dose: (m['dose'] as num?)?.toDouble(),
        note: m['note'],
        wasted: (m['wasted'] as num?)?.toDouble(),
        dead: (m['dead'] as num?)?.toDouble(),
        injType: m['injType'],
        slot: m['slot'],
        used: m['used'] is Map
            ? {for (final e in (m['used'] as Map).entries) e.key as String: (e.value as num).toDouble()}
            : const <String, double>{},
        skipped: m['skipped'] ?? false,
      );
}

class Lab {
  const Lab({required this.id, required this.hormoneId, required this.at, required this.value, required this.unit, this.note});
  final String id, hormoneId, unit;
  final DateTime at;
  final double value;
  final String? note;
  double get base => presetOf(hormoneId).toBase(value, unit);
  Map<String, dynamic> toMap() => {'hormoneId': hormoneId, 'at': _t(at), 'value': value, 'unit': unit, 'note': note};
  factory Lab.from(String id, Map<String, dynamic> m) => Lab(
      id: id,
      hormoneId: m['hormoneId'],
      at: _d(m['at']),
      value: (m['value'] as num).toDouble(),
      unit: m['unit'],
      note: m['note']);
}

/// Stok. kind 'med' = obat (qty dalam satuan, perDose terpakai per dosis, dosePerUnit mg per satuan),
/// kind 'generic' = perlengkapan (spuit, jarum, dst), berkurang 1 tiap dipilih.
class Supply {
  const Supply({
    required this.id,
    required this.name,
    required this.qty,
    required this.initial,
    this.perDose = 1,
    this.unitLabel = 'buah',
    this.expiry,
    this.kind = 'med',
    this.gtype,
    this.dosePerUnit,
  });
  final String id, name, unitLabel, kind;
  final double qty, initial, perDose;
  final DateTime? expiry;
  final String? gtype;
  final double? dosePerUnit;
  bool get generic => kind == 'generic';
  bool get low => generic ? qty <= 5 : doses <= 2;
  bool get expired => expiry != null && expiry!.isBefore(DateTime.now());
  int? get daysToExpiry => expiry == null ? null : DateTime(expiry!.year, expiry!.month, expiry!.day).difference(DateTime.now()).inDays;
  int get doses => perDose <= 0 ? 0 : (qty / perDose).floor();
  Map<String, dynamic> toMap() => {
        'name': name,
        'qty': qty,
        'initial': initial,
        'perDose': perDose,
        'unitLabel': unitLabel,
        'expiry': expiry == null ? null : _t(expiry!),
        'kind': kind,
        'gtype': gtype,
        'dosePerUnit': dosePerUnit,
      };
  factory Supply.from(String id, Map<String, dynamic> m) => Supply(
      id: id,
      name: m['name'],
      qty: (m['qty'] as num).toDouble(),
      initial: (m['initial'] as num).toDouble(),
      perDose: (m['perDose'] as num?)?.toDouble() ?? 1,
      unitLabel: m['unitLabel'] ?? 'buah',
      expiry: m['expiry'] == null ? null : _d(m['expiry']),
      kind: m['kind'] ?? 'med',
      gtype: m['gtype'],
      dosePerUnit: (m['dosePerUnit'] as num?)?.toDouble());
}

/// Suasana hati untuk jurnal: kunci -> (label, ikon).
const moods = <String, (String, IconData)>{
  'happy': ('Happy', Icons.sentiment_very_satisfied_rounded),
  'calm': ('Calm', Icons.sentiment_satisfied_rounded),
  'neutral': ('Neutral', Icons.sentiment_neutral_rounded),
  'low': ('Low', Icons.sentiment_dissatisfied_rounded),
  'anxious': ('Anxious', Icons.sentiment_very_dissatisfied_rounded),
};

const bodyAreas = ['Skin', 'Breasts', 'Body shape', 'Hair', 'Energy', 'Sleep'];

/// Satu entri jurnal: suasana hati, perubahan tubuh per bagian, dan/atau catatan bebas.
class JournalEntry {
  const JournalEntry({required this.id, required this.at, this.mood, this.body = const {}, this.text});
  final String id;
  final DateTime at;
  final String? mood, text;
  final Map<String, String> body;
  bool get hasMood => mood != null;
  bool get hasBody => body.isNotEmpty;
  bool get hasText => text != null && text!.isNotEmpty;

  Map<String, dynamic> toMap() => {'at': _t(at), 'mood': mood, 'body': body, 'text': text};
  factory JournalEntry.from(String id, Map<String, dynamic> m) => JournalEntry(
        id: id,
        at: _d(m['at']),
        mood: m['mood'],
        body: m['body'] is Map
            ? {for (final e in (m['body'] as Map).entries) e.key as String: e.value as String}
            : const <String, String>{},
        text: m['text'],
      );
}

/// Skor suasana hati untuk menghitung pola (1 terendah, 5 tertinggi).
const moodScore = <String, double>{'happy': 5, 'calm': 4, 'neutral': 3, 'low': 2, 'anxious': 1};

/// Pengaturan yang ikut tersinkron antar perangkat.
class Prefs {
  const Prefs({
    this.theme = 'system',
    this.units = const {},
    this.places = defaultPlaces,
    this.hrtCounter = true,
    this.dayStart = 240,
    this.accent = 'lunera',
    this.notify = true,
    this.widgetHide = false,
    this.locale = 'en',
  });
  final String accent; // kunci di `accents`
  final bool notify; // pengingat dosis
  final bool widgetHide; // widget hanya menampilkan nama aplikasi
  final String locale; // 'en' (default) atau 'id'
  final String theme; // system | light | dark
  final Map<String, String> units; // id hormon -> satuan tampilan
  final List<String> places;
  final bool hrtCounter;
  final int dayStart; // menit sejak 00:00; hari "logis" mulai di jam ini

  String unitOf(String hormoneId) {
    final p = presetOf(hormoneId), u = units[hormoneId];
    return u != null && p.units.containsKey(u) ? u : p.base;
  }

  Prefs copy({
    String? theme,
    Map<String, String>? units,
    List<String>? places,
    bool? hrtCounter,
    int? dayStart,
    String? accent,
    bool? notify,
    bool? widgetHide,
    String? locale,
  }) =>
      Prefs(
        theme: theme ?? this.theme,
        units: units ?? this.units,
        places: places ?? this.places,
        hrtCounter: hrtCounter ?? this.hrtCounter,
        dayStart: dayStart ?? this.dayStart,
        accent: accent ?? this.accent,
        notify: notify ?? this.notify,
        widgetHide: widgetHide ?? this.widgetHide,
        locale: locale ?? this.locale,
      );

  Map<String, dynamic> toMap() => {
        'theme': theme,
        'units': units,
        'places': places,
        'hrtCounter': hrtCounter,
        'dayStart': dayStart,
        'accent': accent,
        'notify': notify,
        'widgetHide': widgetHide,
        'locale': locale,
      };

  factory Prefs.from(Map<String, dynamic> m) => Prefs(
        theme: m['theme'] ?? 'system',
        units: m['units'] is Map
            ? {for (final e in (m['units'] as Map).entries) e.key as String: e.value as String}
            : const <String, String>{},
        places: m['places'] is List && (m['places'] as List).isNotEmpty
            ? [for (final x in m['places'] as List) x as String]
            : defaultPlaces,
        hrtCounter: m['hrtCounter'] ?? true,
        dayStart: (m['dayStart'] as num?)?.toInt() ?? 240,
        accent: m['accent'] ?? 'lunera',
        notify: m['notify'] ?? true,
        widgetHide: m['widgetHide'] ?? false,
        locale: m['locale'] ?? 'en',
      );
}

class CloudBackup {
  const CloudBackup({required this.id, required this.at, required this.count, required this.bytes});
  final String id;
  final DateTime at;
  final int count, bytes;
}
