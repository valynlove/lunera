import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'l10n.dart';

DateTime _d(dynamic t) {
  if (t is Timestamp) return t.toDate();
  if (t is DateTime) return t;
  if (t is String) return DateTime.parse(t);
  if (t is Map && t.containsKey(r'$ts')) return DateTime.parse(t[r'$ts'] as String);
  return (t as Timestamp).toDate();
}
Timestamp _t(DateTime d) => Timestamp.fromDate(d);

double? parseNum(String? s) => s == null ? null : double.tryParse(s.trim().replaceAll(',', '.'));
String fmt(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

/// Hormon untuk hasil lab. `units`: satuan -> faktor ke satuan dasar (satuan pertama).
class HormonePreset {
  const HormonePreset(this.id, this.en, this.units);
  final String id, en;
  String get name => tr(en);
  final Map<String, double> units;
  String get base => units.keys.first;
  double toBase(double v, String u) => v * (units[u] ?? 1);
}

const presets = <HormonePreset>[
  HormonePreset('estradiol', 'Estradiol', {'pg/mL': 1, 'pmol/L': 1 / 3.671}),
  HormonePreset('testosterone', 'Testosterone', {'ng/dL': 1, 'ng/mL': 100, 'nmol/L': 28.84}),
  HormonePreset('progesterone', 'Progesterone', {'ng/mL': 1, 'nmol/L': 1 / 3.18}),
  HormonePreset('lh', 'LH', {'IU/L': 1, 'mIU/mL': 1}),
  HormonePreset('fsh', 'FSH', {'IU/L': 1, 'mIU/mL': 1}),
  HormonePreset('prolactin', 'Prolactin', {'ng/mL': 1, 'mIU/L': 1 / 21.2}),
];
HormonePreset presetOf(String id) => presets.firstWhere((p) => p.id == id, orElse: () => presets.first);

/// Cara pemakaian obat. `places`: butuh lokasi (suntik, patch).
class AdminRoute {
  const AdminRoute(this.id, this.en, this.icon, {this.places = false});
  final String id, en;
  String get label => tr(en);
  final IconData icon;
  final bool places;
}

const adminRoutes = <AdminRoute>[
  AdminRoute('inj', 'Injection', Icons.colorize_rounded, places: true),
  AdminRoute('oral', 'Oral', Icons.medication_rounded),
  AdminRoute('sublingual', 'Sublingual', Icons.face_rounded),
  AdminRoute('patch', 'Patch', Icons.layers_rounded, places: true),
  AdminRoute('gel', 'Gel', Icons.water_drop_rounded),
  AdminRoute('implant', 'Implant', Icons.straighten_rounded),
  AdminRoute('supp', 'Suppository', Icons.medication_liquid_rounded),
  AdminRoute('spray', 'Spray', Icons.air_rounded),
  AdminRoute('drops', 'Drops', Icons.opacity_rounded),
  AdminRoute('other', 'Other', Icons.more_horiz_rounded),
];
AdminRoute routeOf(String id) => adminRoutes.firstWhere((r) => r.id == id, orElse: () => adminRoutes.last);

const routes = adminRoutes;

/// Jenis barang non-obat yang umum untuk HRT (kunci -> label English, ikon).
const genericSupplyTypes = <String, (String, IconData)>{
  'syringe': ('Syringe', Icons.vaccines_rounded),
  'wipe': ('Alcohol wipe', Icons.cleaning_services_rounded),
  'needle': ('Needle', Icons.colorize_rounded),
  'gloves': ('Gloves', Icons.back_hand_rounded),
  'bandage': ('Bandage', Icons.healing_rounded),
};
const genericTypes = genericSupplyTypes;

const defaultPlaces = ['Left thigh', 'Right thigh', 'Left buttock', 'Right buttock'];
const placePresets = [
  'Left thigh', 'Right thigh', 'Left arm', 'Right arm', 'Left buttock', 'Right buttock', 'Left abdomen', 'Right abdomen'
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
    this.route = 'oral',
    this.pk,
    this.rolling = false,
    this.injType,
    this.times = const ['08:00'],
    this.weekdays = const [1],
    this.monthDay = 1,
    this.kind = 'interval',
  });
  final String id;
  final String hormoneId;
  final String name;
  final double dose;
  final String doseUnit;
  final int everyDays; // jika kind == 'interval'
  final DateTime start;
  final String? supplyId;
  final String route;
  final String? pk; // profil PK di sim.dart
  final bool rolling; // jeda dihitung dari dosis terakhir
  final String? injType; // im | subq
  final List<String> times; // jam dalam sehari, mis. ['08:00', '20:00']
  final List<int> weekdays; // jika kind == 'weekly' (1 = Senin .. 7 = Minggu)
  final int monthDay; // jika kind == 'monthly' (1 .. 31)
  final String kind; // interval | weekly | monthly | asneeded

  bool get asNeeded => kind == 'asneeded';
  bool get daily => kind == 'interval' && everyDays == 1;

  AdminRoute get adm => routeOf(route);

  Therapy copy({
    String? hormoneId,
    String? name,
    double? dose,
    String? doseUnit,
    int? everyDays,
    DateTime? start,
    String? supplyId,
    String? route,
    String? pk,
    bool? rolling,
    String? injType,
    List<String>? times,
    List<int>? weekdays,
    int? monthDay,
    String? kind,
  }) =>
      Therapy(
        id: id,
        hormoneId: hormoneId ?? this.hormoneId,
        name: name ?? this.name,
        dose: dose ?? this.dose,
        doseUnit: doseUnit ?? this.doseUnit,
        everyDays: everyDays ?? this.everyDays,
        start: start ?? this.start,
        supplyId: supplyId ?? this.supplyId,
        route: route ?? this.route,
        pk: pk ?? this.pk,
        rolling: rolling ?? this.rolling,
        injType: injType ?? this.injType,
        times: times ?? this.times,
        weekdays: weekdays ?? this.weekdays,
        monthDay: monthDay ?? this.monthDay,
        kind: kind ?? this.kind,
      );

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
        'rolling': rolling,
        'injType': injType,
        'times': times,
        'weekdays': weekdays,
        'monthDay': monthDay,
        'kind': kind,
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
        route: m['route'] ?? 'oral',
        pk: m['pk'],
        rolling: m['rolling'] ?? false,
        injType: m['injType'] ?? 'im',
        times: m['times'] is List && (m['times'] as List).isNotEmpty ? [for (final x in m['times'] as List) x as String] : const ['08:00'],
        weekdays: m['weekdays'] is List && (m['weekdays'] as List).isNotEmpty ? [for (final x in m['weekdays'] as List) (x as num).toInt()] : const [1],
        monthDay: (m['monthDay'] as num?)?.toInt() ?? 1,
        kind: m['kind'] ?? ((m['everyDays'] as num?) != null ? 'interval' : 'interval'),
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
    Map<String, double>? used,
    Map<String, double> usedSupplies = const {},
    this.skipped = false,
  }) : usedSupplies = used ?? usedSupplies;
  final String id;
  final String therapyId;
  final DateTime at;
  final List<String> places; // lokasi pemakaian obat
  final double? dose;
  final String? note;
  final double? wasted, dead; // obat terbuang
  final String? injType, slot;
  final Map<String, double> usedSupplies; // id barang -> jumlah yang dipotong
  final bool skipped; // dilewati (bukan diminum/disuntikkan)

  Map<String, double> get used => usedSupplies;
  String get site => places.isEmpty ? '' : places.first;

  DoseLog copy({
    String? therapyId,
    DateTime? at,
    List<String>? places,
    double? dose,
    String? note,
    double? wasted,
    double? dead,
    String? injType,
    String? slot,
    Map<String, double>? usedSupplies,
    bool? skipped,
  }) =>
      DoseLog(
        id: id,
        therapyId: therapyId ?? this.therapyId,
        at: at ?? this.at,
        places: places ?? this.places,
        dose: dose ?? this.dose,
        note: note ?? this.note,
        wasted: wasted ?? this.wasted,
        dead: dead ?? this.dead,
        injType: injType ?? this.injType,
        slot: slot ?? this.slot,
        usedSupplies: usedSupplies ?? this.usedSupplies,
        skipped: skipped ?? this.skipped,
      );

  Map<String, dynamic> toMap() => {
        'therapyId': therapyId,
        'at': _t(at),
        'places': places,
        'dose': dose,
        'note': note,
        'wasted': wasted,
        'dead': dead,
        'injType': injType,
        'slot': slot,
        'usedSupplies': usedSupplies,
        'skipped': skipped,
      };

  factory DoseLog.from(String id, Map<String, dynamic> m) => DoseLog(
        id: id,
        therapyId: m['therapyId'],
        at: _d(m['at']),
        places: m['places'] is List
            ? [for (final x in m['places'] as List) _key(x as String)]
            : (m['site'] is String && m['site'] != '' && m['site'] != 'oral' ? [_key(m['site'] as String)] : <String>[]),
        dose: (m['dose'] as num?)?.toDouble(),
        note: m['note'],
        wasted: (m['wasted'] as num?)?.toDouble(),
        dead: (m['dead'] as num?)?.toDouble(),
        injType: m['injType'],
        slot: m['slot'],
        usedSupplies: m['usedSupplies'] is Map ? {for (final e in (m['usedSupplies'] as Map).entries) e.key as String: (e.value as num).toDouble()} : const {},
        skipped: m['skipped'] ?? false,
      );
}

class Lab {
  const Lab({required this.id, required this.hormoneId, required this.at, required this.value, required this.unit, this.note});
  final String id;
  final String hormoneId;
  final DateTime at;
  final double value;
  final String unit;
  final String? note;

  double get base => presetOf(hormoneId).toBase(value, unit);

  Map<String, dynamic> toMap() => {'hormoneId': hormoneId, 'at': _t(at), 'value': value, 'unit': unit, 'note': note};

  factory Lab.from(String id, Map<String, dynamic> m) => Lab(
        id: id,
        hormoneId: m['hormoneId'],
        at: _d(m['at']),
        value: (m['value'] as num).toDouble(),
        unit: m['unit'],
        note: m['note'],
      );
}

class Supply {
  const Supply({
    required this.id,
    required this.name,
    required this.qty,
    required this.initial,
    this.perDose = 1,
    this.unitLabel = 'pcs',
    this.expiry,
    this.kind = 'med',
    this.gtype,
    this.dosePerUnit,
  });
  final String id;
  final String name;
  final double qty;
  final double initial;
  final double perDose;
  final String unitLabel;
  final DateTime? expiry;
  final String kind; // med | generic
  final String? gtype; // syringe | wipe | needle | gloves | bandage (jika kind == generic)
  final double? dosePerUnit; // mg per unitLabel, mis. 40 mg/mL

  bool get generic => kind == 'generic';
  int get doses => perDose > 0 ? (qty / perDose).floor() : 0;
  bool get low => generic ? qty <= 5 : doses <= 3;
  bool get expired => expiry != null && expiry!.isBefore(DateTime.now());
  int? get daysToExpiry => expiry?.difference(DateTime.now()).inDays;

  Supply copy({
    String? name,
    double? qty,
    double? initial,
    double? perDose,
    String? unitLabel,
    DateTime? expiry,
    String? kind,
    String? gtype,
    double? dosePerUnit,
  }) =>
      Supply(
        id: id,
        name: name ?? this.name,
        qty: qty ?? this.qty,
        initial: initial ?? this.initial,
        perDose: perDose ?? this.perDose,
        unitLabel: unitLabel ?? this.unitLabel,
        expiry: expiry ?? this.expiry,
        kind: kind ?? this.kind,
        gtype: gtype ?? this.gtype,
        dosePerUnit: dosePerUnit ?? this.dosePerUnit,
      );

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
      unitLabel: m['unitLabel'] ?? 'pcs',
      expiry: m['expiry'] == null ? null : _d(m['expiry']),
      kind: m['kind'] ?? 'med',
      gtype: m['gtype'],
      dosePerUnit: (m['dosePerUnit'] as num?)?.toDouble());
}

/// Pengaturan yang ikut tersinkron antar perangkat.
class Prefs {
  const Prefs({
    this.theme = 'system',
    this.units = const {},
    this.places = defaultPlaces,
    this.hrtCounter = true,
    this.dayStart = 240,
    this.accent = 'lunera',
    this.notify = false,
    this.widgetHide = false,
    this.locale = 'en',
    this.geminiApiKey = '',
    this.asteriaMode = 'shared',
    this.discreetNotify = 'off',
  });
  final String accent; // kunci di `accents`
  final bool notify; // pengingat dosis
  final bool widgetHide; // widget hanya menampilkan nama aplikasi
  final String locale; // bahasa preferensi
  final String theme; // system | light | dark
  final Map<String, String> units; // id hormon -> satuan tampilan
  final List<String> places;
  final bool hrtCounter;
  final int dayStart; // menit sejak 00:00; hari "logis" mulai di jam ini
  final String geminiApiKey;
  final String asteriaMode; // 'shared' (Bintang Bersama) | 'personal' (Bintang Pribadi)
  final String discreetNotify; // 'off' | 'wellness' | 'minimal'

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
    String? geminiApiKey,
    String? asteriaMode,
    String? discreetNotify,
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
        geminiApiKey: geminiApiKey ?? this.geminiApiKey,
        asteriaMode: asteriaMode ?? this.asteriaMode,
        discreetNotify: discreetNotify ?? this.discreetNotify,
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
        'geminiApiKey': geminiApiKey,
        'asteriaMode': asteriaMode,
        'discreetNotify': discreetNotify,
      };

  factory Prefs.from(Map<String, dynamic> m) => Prefs(
        theme: m['theme'] ?? 'system',
        units: m['units'] is Map
            ? {for (final e in (m['units'] as Map).entries) e.key as String: e.value as String}
            : const <String, String>{},
        places: m['places'] is List && (m['places'] as List).isNotEmpty
            ? [for (final x in m['places'] as List) _key(x as String)]
            : defaultPlaces,
        hrtCounter: m['hrtCounter'] ?? true,
        dayStart: (m['dayStart'] as num?)?.toInt() ?? 240,
        accent: m['accent'] ?? 'lunera',
        notify: m['notify'] ?? false,
        widgetHide: m['widgetHide'] ?? false,
        locale: m['locale'] ?? 'en',
        geminiApiKey: m['geminiApiKey'] ?? '',
        asteriaMode: m['asteriaMode'] ?? 'shared',
        discreetNotify: m['discreetNotify'] ?? 'off',
      );
}

/// Lokasi dan bagian tubuh yang dulu disimpan dengan nama Indonesia dipetakan ke kunci English saat dibaca.
const _legacyKeys = {
  'Paha kiri': 'Left thigh', 'Paha kanan': 'Right thigh', 'Bokong kiri': 'Left buttock', 'Bokong kanan': 'Right buttock',
  'Lengan kiri': 'Left arm', 'Lengan kanan': 'Right arm', 'Perut kiri': 'Left abdomen', 'Perut kanan': 'Right abdomen',
  'Kulit': 'Skin', 'Payudara': 'Breasts', 'Bentuk tubuh': 'Body shape', 'Rambut': 'Hair', 'Energi': 'Energy', 'Tidur': 'Sleep',
};
String _key(String s) => _legacyKeys[s] ?? s;

class CloudBackup {
  const CloudBackup({required this.id, required this.at, required this.count, required this.bytes});
  final String id;
  final DateTime at;
  final int count, bytes;
}

/// Suasana hati untuk jurnal: kunci -> (label, ikon).
const moodTypes = <String, (String, IconData)>{
  'happy': ('Happy', Icons.sentiment_very_satisfied_rounded),
  'calm': ('Calm', Icons.sentiment_satisfied_rounded),
  'neutral': ('Neutral', Icons.sentiment_neutral_rounded),
  'low': ('Low', Icons.sentiment_dissatisfied_rounded),
  'anxious': ('Anxious', Icons.sentiment_very_dissatisfied_rounded),
};
const moods = moodTypes;

/// Bagian tubuh untuk observasi transisi di jurnal.
const bodyAreas = ['Skin', 'Breasts', 'Body shape', 'Hair', 'Energy', 'Sleep'];

class JournalEntry {
  const JournalEntry({required this.id, required this.at, this.mood, this.body = const {}, this.text});
  final String id;
  final DateTime at;
  final String? mood; // happy | calm | neutral | low | anxious
  final Map<String, String> body; // area -> catatan
  final String? text; // catatan umum bebas

  bool get hasMood => mood != null && mood!.isNotEmpty;
  bool get hasBody => body.isNotEmpty;
  bool get hasText => text != null && text!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {'at': _t(at), 'mood': mood, 'body': body, 'text': text};

  factory JournalEntry.from(String id, Map<String, dynamic> m) => JournalEntry(
        id: id,
        at: _d(m['at']),
        mood: m['mood'],
        body: m['body'] is Map
            ? {for (final e in (m['body'] as Map).entries) _key(e.key as String): e.value as String}
            : const <String, String>{},
        text: m['text'],
      );
}

/// Skor suasana hati untuk menghitung pola (1 terendah, 5 tertinggi).
const moodScore = <String, double>{'happy': 5, 'calm': 4, 'neutral': 3, 'low': 2, 'anxious': 1};

/// Hasil perhitungan ukuran bra dan dada
class BraSizeResult {
  const BraSizeResult({
    required this.usUk,
    required this.euId,
    required this.cup,
    required this.bandEu,
    required this.bandUs,
    required this.diffCm,
    this.sisterTight,
    this.sisterLoose,
  });

  final String usUk; // misal: "34B"
  final String euId; // misal: "75B"
  final String cup; // misal: "B"
  final int bandEu; // 75
  final int bandUs; // 34
  final double diffCm; // selisih bust - underbust dalam cm
  final String? sisterTight; // misal: "32C (70C)"
  final String? sisterLoose; // misal: "36A (80A)"
}

/// Hasil perhitungan ukuran sepatu multi-standar (EU/ID, US Women, US Men, UK)
class ShoeSizeResult {
  const ShoeSizeResult({
    required this.eu,
    required this.usWomen,
    required this.usMen,
    required this.uk,
    required this.footCm,
  });

  final String eu; // misal: "39"
  final String usWomen; // misal: "8.5"
  final String usMen; // misal: "7"
  final String uk; // misal: "6"
  final double footCm;
}

/// Menghitung konversi ukuran sepatu berdasarkan panjang telapak kaki dalam cm
ShoeSizeResult calculateShoeSize(double footCm) {
  String eu, usW, usM, uk;
  if (footCm < 22.0) {
    eu = '34'; usW = '4'; usM = '2.5'; uk = '1.5';
  } else if (footCm < 22.5) {
    eu = '35'; usW = '5'; usM = '3.5'; uk = '2.5';
  } else if (footCm < 23.0) {
    eu = '36'; usW = '5.5'; usM = '4'; uk = '3';
  } else if (footCm < 23.5) {
    eu = '37'; usW = '6.5'; usM = '5'; uk = '4';
  } else if (footCm < 24.0) {
    eu = '37.5'; usW = '7'; usM = '5.5'; uk = '4.5';
  } else if (footCm < 24.5) {
    eu = '38'; usW = '7.5'; usM = '6'; uk = '5';
  } else if (footCm < 25.0) {
    eu = '39'; usW = '8.5'; usM = '7'; uk = '6';
  } else if (footCm < 25.5) {
    eu = '40'; usW = '9'; usM = '7.5'; uk = '6.5';
  } else if (footCm < 26.0) {
    eu = '40.5'; usW = '9.5'; usM = '8'; uk = '7';
  } else if (footCm < 26.5) {
    eu = '41'; usW = '10'; usM = '8.5'; uk = '7.5';
  } else if (footCm < 27.0) {
    eu = '42'; usW = '10.5'; usM = '9'; uk = '8';
  } else if (footCm < 27.5) {
    eu = '43'; usW = '11.5'; usM = '10'; uk = '9';
  } else if (footCm < 28.0) {
    eu = '44'; usW = '12'; usM = '10.5'; uk = '9.5';
  } else {
    eu = '45'; usW = '13'; usM = '11.5'; uk = '10.5';
  }
  return ShoeSizeResult(eu: eu, usWomen: usW, usMen: usM, uk: uk, footCm: footCm);
}

/// Menghitung ukuran bra berdasarkan lingkar dada (bust) dan bawah dada (underbust) dalam cm
BraSizeResult calculateBraSize({required double bustCm, required double underbustCm}) {
  final diff = (bustCm - underbustCm).clamp(0.0, 100.0);

  // Band EU & US
  int bandEu;
  int bandUs;
  if (underbustCm < 63) {
    bandEu = 60; bandUs = 28;
  } else if (underbustCm < 68) {
    bandEu = 65; bandUs = 30;
  } else if (underbustCm < 73) {
    bandEu = 70; bandUs = 32;
  } else if (underbustCm < 78) {
    bandEu = 75; bandUs = 34;
  } else if (underbustCm < 83) {
    bandEu = 80; bandUs = 36;
  } else if (underbustCm < 88) {
    bandEu = 85; bandUs = 38;
  } else if (underbustCm < 93) {
    bandEu = 90; bandUs = 40;
  } else if (underbustCm < 98) {
    bandEu = 95; bandUs = 42;
  } else if (underbustCm < 103) {
    bandEu = 100; bandUs = 44;
  } else if (underbustCm < 108) {
    bandEu = 105; bandUs = 46;
  } else {
    bandEu = 110; bandUs = 48;
  }

  // Cup ladder
  const cupLadder = ['AA', 'A', 'B', 'C', 'D', 'DD', 'E', 'F', 'FF', 'G'];
  String cup;
  int cupIndex;
  if (diff < 10.0) {
    cup = 'AA'; cupIndex = 0;
  } else if (diff < 12.0) {
    cup = 'A'; cupIndex = 1;
  } else if (diff < 14.0) {
    cup = 'B'; cupIndex = 2;
  } else if (diff < 16.0) {
    cup = 'C'; cupIndex = 3;
  } else if (diff < 18.0) {
    cup = 'D'; cupIndex = 4;
  } else if (diff < 20.0) {
    cup = 'DD'; cupIndex = 5;
  } else if (diff < 22.0) {
    cup = 'E'; cupIndex = 6;
  } else if (diff < 24.0) {
    cup = 'F'; cupIndex = 7;
  } else if (diff < 26.0) {
    cup = 'FF'; cupIndex = 8;
  } else {
    cup = 'G'; cupIndex = 9;
  }

  final usUk = '$bandUs$cup';
  final euId = '$bandEu$cup';

  String? sisterTight;
  if (bandUs > 28 && cupIndex < cupLadder.length - 1) {
    sisterTight = '${bandUs - 2}${cupLadder[cupIndex + 1]} (${bandEu - 5}${cupLadder[cupIndex + 1]})';
  }
  String? sisterLoose;
  if (bandUs < 48 && cupIndex > 0) {
    sisterLoose = '${bandUs + 2}${cupLadder[cupIndex - 1]} (${bandEu + 5}${cupLadder[cupIndex - 1]})';
  }

  return BraSizeResult(
    usUk: usUk,
    euId: euId,
    cup: cup,
    bandEu: bandEu,
    bandUs: bandUs,
    diffCm: diff,
    sisterTight: sisterTight,
    sisterLoose: sisterLoose,
  );
}

/// Catatan ukuran tubuh untuk menentukan ukuran pakaian dan perkembangan fisik
class BodyMeasurement {
  const BodyMeasurement({
    required this.id,
    required this.at,
    this.unit = 'cm',
    this.bust,
    this.underbust,
    this.waist,
    this.hips,
    this.shoulder,
    this.thigh,
    this.calf,
    this.inseam,
    this.footLength,
    this.shoeSize,
    this.weight,
    this.height,
    this.note,
  });

  final String id;
  final DateTime at;
  final String unit; // 'cm' | 'in'
  final double? bust; // Lingkar dada / full bust
  final double? underbust; // Lingkar bawah dada / ribcage
  final double? waist; // Lingkar pinggang
  final double? hips; // Lingkar pinggul
  final double? shoulder; // Lebar bahu
  final double? thigh; // Lingkar paha
  final double? calf; // Lingkar betis
  final double? inseam; // Panjang kaki bagian dalam (selangkangan ke mata kaki)
  final double? footLength; // Panjang telapak kaki
  final String? shoeSize; // Ukuran sepatu yang biasa dipakai / manual (misal: "39" atau "EU 39")
  final double? weight; // Berat badan (kg)
  final double? height; // Tinggi badan (cm)
  final String? note;

  double? get bustCm => bust == null ? null : (unit == 'in' ? bust! * 2.54 : bust);
  double? get underbustCm => underbust == null ? null : (unit == 'in' ? underbust! * 2.54 : underbust);
  double? get waistCm => waist == null ? null : (unit == 'in' ? waist! * 2.54 : waist);
  double? get hipsCm => hips == null ? null : (unit == 'in' ? hips! * 2.54 : hips);
  double? get shoulderCm => shoulder == null ? null : (unit == 'in' ? shoulder! * 2.54 : shoulder);
  double? get thighCm => thigh == null ? null : (unit == 'in' ? thigh! * 2.54 : thigh);
  double? get calfCm => calf == null ? null : (unit == 'in' ? calf! * 2.54 : calf);
  double? get inseamCm => inseam == null ? null : (unit == 'in' ? inseam! * 2.54 : inseam);
  double? get footLengthCm => footLength == null ? null : (unit == 'in' ? footLength! * 2.54 : footLength);

  /// Hitung ukuran bra / dada lengkap (US/UK, EU/ID, cup, sister sizes)
  BraSizeResult? get braSize {
    final b = bustCm, u = underbustCm;
    if (b == null || u == null || b < u) return null;
    return calculateBraSize(bustCm: b, underbustCm: u);
  }

  /// Hitung estimasi ukuran sepatu multi-standar (EU, US W, US M, UK)
  ShoeSizeResult? get shoeSizeResult {
    final f = footLengthCm;
    if (f == null || f <= 0) return null;
    return calculateShoeSize(f);
  }

  /// Teks ringkas ukuran sepatu untuk ditampilkan di kartu pakaian
  String? get displayShoeSize {
    if (shoeSize != null && shoeSize!.trim().isNotEmpty) return shoeSize!.trim();
    final res = shoeSizeResult;
    if (res == null) return null;
    return 'EU ${res.eu} (US W ${res.usWomen})';
  }

  /// Estimasi ukuran atasan / baju
  String? get topSize {
    final b = bustCm;
    if (b == null) return null;
    if (b < 80) return 'XS';
    if (b <= 86) return 'S';
    if (b <= 93) return 'M';
    if (b <= 100) return 'L';
    if (b <= 108) return 'XL';
    return 'XXL';
  }

  /// Estimasi ukuran bawahan / celana (dengan panjang inseam jika diisi)
  String? get bottomSize {
    final w = waistCm;
    if (w == null) return null;
    String base;
    if (w < 65) {
      base = '26 (XS)';
    } else if (w <= 71) {
      base = '27–28 (S)';
    } else if (w <= 78) {
      base = '29–30 (M)';
    } else if (w <= 85) {
      base = '31–32 (L)';
    } else if (w <= 93) {
      base = '33–34 (XL)';
    } else {
      base = '35+ (XXL)';
    }
    if (inseamCm != null) {
      final inInches = (inseamCm! / 2.54).round();
      return '$base / L$inInches';
    }
    return base;
  }

  /// Rasio Pinggang ke Pinggul (Waist-to-Hip Ratio / WHR)
  double? get waistToHipRatio {
    final w = waistCm, h = hipsCm;
    if (w == null || h == null || h <= 0) return null;
    return w / h;
  }

  BodyMeasurement copy({
    DateTime? at,
    String? unit,
    double? bust,
    double? underbust,
    double? waist,
    double? hips,
    double? shoulder,
    double? thigh,
    double? calf,
    double? inseam,
    double? footLength,
    String? shoeSize,
    double? weight,
    double? height,
    String? note,
  }) =>
      BodyMeasurement(
        id: id,
        at: at ?? this.at,
        unit: unit ?? this.unit,
        bust: bust ?? this.bust,
        underbust: underbust ?? this.underbust,
        waist: waist ?? this.waist,
        hips: hips ?? this.hips,
        shoulder: shoulder ?? this.shoulder,
        thigh: thigh ?? this.thigh,
        calf: calf ?? this.calf,
        inseam: inseam ?? this.inseam,
        footLength: footLength ?? this.footLength,
        shoeSize: shoeSize ?? this.shoeSize,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
        'at': _t(at),
        'unit': unit,
        'bust': bust,
        'underbust': underbust,
        'waist': waist,
        'hips': hips,
        'shoulder': shoulder,
        'thigh': thigh,
        'calf': calf,
        'inseam': inseam,
        'footLength': footLength,
        'shoeSize': shoeSize,
        'weight': weight,
        'height': height,
        'note': note,
      };

  factory BodyMeasurement.from(String id, Map<String, dynamic> m) => BodyMeasurement(
        id: id,
        at: _d(m['at']),
        unit: m['unit'] ?? 'cm',
        bust: (m['bust'] as num?)?.toDouble(),
        underbust: (m['underbust'] as num?)?.toDouble(),
        waist: (m['waist'] as num?)?.toDouble(),
        hips: (m['hips'] as num?)?.toDouble(),
        shoulder: (m['shoulder'] as num?)?.toDouble(),
        thigh: (m['thigh'] as num?)?.toDouble(),
        calf: (m['calf'] as num?)?.toDouble(),
        inseam: (m['inseam'] as num?)?.toDouble(),
        footLength: (m['footLength'] as num?)?.toDouble(),
        shoeSize: m['shoeSize'],
        weight: (m['weight'] as num?)?.toDouble(),
        height: (m['height'] as num?)?.toDouble(),
        note: m['note'],
      );
}
