import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'l10n.dart';

DateTime _d(dynamic t) {
  if (t is Timestamp) return t.toDate();
  if (t is DateTime) return t;
  if (t is String) return DateTime.parse(t);
  if (t is Map && t.containsKey(r'$ts'))
    return DateTime.parse(t[r'$ts'] as String);
  return (t as Timestamp).toDate();
}

Timestamp _t(DateTime d) => Timestamp.fromDate(d);

double? parseNum(String? s) =>
    s == null ? null : double.tryParse(s.trim().replaceAll(',', '.'));
String fmt(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

/// Computes liquid draw volume (mL) and equivalent U-100 insulin syringe units
/// for a given [doseMg] and vial [concentrationMgPerMl]. Returns null on invalid inputs.
({double volumeMl, double syringeUnits})? computeInjectionVolume({
  required double doseMg,
  required double concentrationMgPerMl,
}) {
  if (!doseMg.isFinite ||
      !concentrationMgPerMl.isFinite ||
      doseMg <= 0 ||
      concentrationMgPerMl <= 0) {
    return null;
  }
  final ml = doseMg / concentrationMgPerMl;
  return (volumeMl: ml, syringeUnits: ml * 100.0);
}

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
  HormonePreset(
      'estradiol', 'Estradiol', {'pg/mL': 1, 'pmol/L': 1 / 3.671, 'ng/L': 1}),
  HormonePreset('testosterone', 'Testosterone',
      {'ng/dL': 1, 'ng/mL': 100, 'nmol/L': 28.84, 'µg/L': 100}),
  HormonePreset('progesterone', 'Progesterone',
      {'ng/mL': 1, 'nmol/L': 1 / 3.18, 'µg/L': 1}),
  HormonePreset('lh', 'LH', {'IU/L': 1, 'mIU/mL': 1}),
  HormonePreset('fsh', 'FSH', {'IU/L': 1, 'mIU/mL': 1}),
  HormonePreset(
      'prolactin', 'Prolactin', {'ng/mL': 1, 'mIU/L': 1 / 21.2, 'µg/L': 1}),
];
HormonePreset presetOf(String id) {
  if (id == 'blocker')
    return const HormonePreset('blocker', 'Anti-androgen (Blocker)', {'mg': 1});
  return presets.firstWhere((p) => p.id == id, orElse: () => presets.first);
}

/// Senyawa aktif (kandungan kimia/ester obat) yang umum digunakan.
class CompoundPreset {
  const CompoundPreset({
    required this.id,
    required this.hormoneId,
    required this.en,
    this.defaultRoute = 'oral',
    this.defaultDose,
    this.defaultUnit = 'mg',
    this.pk,
  });

  final String id;
  final String
      hormoneId; // estradiol | testosterone | progesterone | blocker | other
  final String en;
  String get name => tr(en);
  final String defaultRoute;
  final double? defaultDose;
  final String defaultUnit;
  final String? pk;
}

const compoundPresets = <CompoundPreset>[
  // Estradiol (E2)
  CompoundPreset(
      id: 'ev_inj',
      hormoneId: 'estradiol',
      en: 'Estradiol valerate',
      defaultRoute: 'inj',
      defaultDose: 4,
      pk: 'e2_valerate'),
  CompoundPreset(
      id: 'ec_inj',
      hormoneId: 'estradiol',
      en: 'Estradiol cypionate',
      defaultRoute: 'inj',
      defaultDose: 5,
      pk: 'e2_cypionate'),
  CompoundPreset(
      id: 'een_inj',
      hormoneId: 'estradiol',
      en: 'Estradiol enanthate',
      defaultRoute: 'inj',
      defaultDose: 5,
      pk: 'e2_enanthate'),
  CompoundPreset(
      id: 'eun_inj',
      hormoneId: 'estradiol',
      en: 'Estradiol undecylate',
      defaultRoute: 'inj',
      defaultDose: 10,
      pk: 'e2_undecylate'),
  CompoundPreset(
      id: 'eb_inj',
      hormoneId: 'estradiol',
      en: 'Estradiol benzoate',
      defaultRoute: 'inj',
      defaultDose: 2,
      pk: 'e2_benzoate'),
  CompoundPreset(
      id: 'e2_hemi',
      hormoneId: 'estradiol',
      en: 'Estradiol hemihydrate',
      defaultRoute: 'oral',
      defaultDose: 2,
      pk: 'e2_oral'),
  CompoundPreset(
      id: 'e2_val_oral',
      hormoneId: 'estradiol',
      en: 'Estradiol valerate (oral)',
      defaultRoute: 'oral',
      defaultDose: 2,
      pk: 'e2_oral'),
  CompoundPreset(
      id: 'e2_gel',
      hormoneId: 'estradiol',
      en: 'Estradiol gel (transdermal)',
      defaultRoute: 'gel',
      defaultDose: 1,
      pk: 'e2_gel'),

  // Testosterone (T)
  CompoundPreset(
      id: 'te_inj',
      hormoneId: 'testosterone',
      en: 'Testosterone enanthate',
      defaultRoute: 'inj',
      defaultDose: 100,
      pk: 't_enanthate'),
  CompoundPreset(
      id: 'tc_inj',
      hormoneId: 'testosterone',
      en: 'Testosterone cypionate',
      defaultRoute: 'inj',
      defaultDose: 100,
      pk: 't_cypionate'),
  CompoundPreset(
      id: 'tu_inj',
      hormoneId: 'testosterone',
      en: 'Testosterone undecanoate (Nebido)',
      defaultRoute: 'inj',
      defaultDose: 1000,
      pk: 't_undecanoate'),
  CompoundPreset(
      id: 'tp_inj',
      hormoneId: 'testosterone',
      en: 'Testosterone propionate',
      defaultRoute: 'inj',
      defaultDose: 50,
      pk: 't_propionate'),
  CompoundPreset(
      id: 't_gel_comp',
      hormoneId: 'testosterone',
      en: 'Bioidentical testosterone (gel)',
      defaultRoute: 'gel',
      defaultDose: 50,
      pk: 't_gel'),

  // Progesterone & Progestins (P4)
  CompoundPreset(
      id: 'mpa_comp',
      hormoneId: 'progesterone',
      en: 'Medroxyprogesterone acetate (MPA)',
      defaultRoute: 'inj',
      defaultDose: 25,
      pk: 'mpa_susp'),
  CompoundPreset(
      id: 'p4_micron',
      hormoneId: 'progesterone',
      en: 'Micronized progesterone',
      defaultRoute: 'oral',
      defaultDose: 200,
      pk: 'p4_oral'),
  CompoundPreset(
      id: 'dydro',
      hormoneId: 'progesterone',
      en: 'Dydrogesterone',
      defaultRoute: 'oral',
      defaultDose: 10),
  CompoundPreset(
      id: '17ohpc',
      hormoneId: 'progesterone',
      en: 'Hydroxyprogesterone caproate',
      defaultRoute: 'inj',
      defaultDose: 250),

  // Anti-Androgens / Blockers
  CompoundPreset(
      id: 'cpa',
      hormoneId: 'blocker',
      en: 'Cyproterone acetate (CPA)',
      defaultRoute: 'oral',
      defaultDose: 10),
  CompoundPreset(
      id: 'spiro',
      hormoneId: 'blocker',
      en: 'Spironolactone',
      defaultRoute: 'oral',
      defaultDose: 50),
  CompoundPreset(
      id: 'bica',
      hormoneId: 'blocker',
      en: 'Bicalutamide',
      defaultRoute: 'oral',
      defaultDose: 50),
  CompoundPreset(
      id: 'fina',
      hormoneId: 'blocker',
      en: 'Finasteride',
      defaultRoute: 'oral',
      defaultDose: 1),
  CompoundPreset(
      id: 'duta',
      hormoneId: 'blocker',
      en: 'Dutasteride',
      defaultRoute: 'oral',
      defaultDose: 0.5),
  CompoundPreset(
      id: 'gnrh',
      hormoneId: 'blocker',
      en: 'Leuprorelin (GnRH agonist)',
      defaultRoute: 'inj',
      defaultDose: 3.75),
];

List<CompoundPreset> compoundsFor(String hormoneId) =>
    compoundPresets.where((c) => c.hormoneId == hormoneId).toList();
CompoundPreset? compoundOf(String? id) =>
    id == null ? null : compoundPresets.where((c) => c.id == id).firstOrNull;

/// Cara pemakaian obat. `places`: butuh lokasi (suntik, patch).
class AdminRoute {
  const AdminRoute(this.id, this.en, this.icon, {this.places = false});
  final String id, en;
  String get label => tr(en);
  final IconData icon;
  final bool places;
}

const adminRoutes = <AdminRoute>[
  AdminRoute('inj', 'Injection', LucideIcons.syringe, places: true),
  AdminRoute('oral', 'Oral', LucideIcons.pill),
  AdminRoute('sublingual', 'Sublingual', LucideIcons.scanFace),
  AdminRoute('patch', 'Patch', LucideIcons.layers, places: true),
  AdminRoute('gel', 'Gel', LucideIcons.droplet),
  AdminRoute('implant', 'Implant', LucideIcons.ruler),
  AdminRoute('supp', 'Suppository', LucideIcons.flaskConical),
  AdminRoute('spray', 'Spray', LucideIcons.wind),
  AdminRoute('drops', 'Drops', LucideIcons.droplets),
  AdminRoute('other', 'Other', LucideIcons.ellipsis),
];
AdminRoute routeOf(String id) =>
    adminRoutes.firstWhere((r) => r.id == id, orElse: () => adminRoutes.last);

const routes = adminRoutes;

/// Jenis barang non-obat yang umum untuk HRT (kunci -> label English, ikon).
const genericSupplyTypes = <String, (String, IconData)>{
  'syringe': ('Syringe', LucideIcons.syringe),
  'wipe': ('Alcohol wipe', LucideIcons.sparkles),
  'needle': ('Needle', LucideIcons.syringe),
  'gloves': ('Gloves', LucideIcons.hand),
  'bandage': ('Bandage', LucideIcons.bandage),
};
const genericTypes = genericSupplyTypes;

const defaultPlaces = [
  'Left thigh',
  'Right thigh',
  'Left buttock',
  'Right buttock'
];
const placePresets = [
  'Left thigh',
  'Right thigh',
  'Left arm',
  'Right arm',
  'Left buttock',
  'Right buttock',
  'Left abdomen',
  'Right abdomen'
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
    this.secondaryHormoneId,
    this.secondaryDose,
    this.secondaryDoseUnit,
    this.secondaryPk,
    this.compound,
    this.secondaryCompound,
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

  // Komponen aktif kedua (untuk obat kombinasi seperti Cyclofem)
  final String? secondaryHormoneId;
  final double? secondaryDose;
  final String? secondaryDoseUnit;
  final String? secondaryPk;

  // Kandungan senyawa aktif yang dipilih
  final String? compound;
  final String? secondaryCompound;

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
    String? secondaryHormoneId,
    double? secondaryDose,
    String? secondaryDoseUnit,
    String? secondaryPk,
    bool clearSecondary = false,
    String? compound,
    String? secondaryCompound,
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
        secondaryHormoneId: clearSecondary
            ? null
            : (secondaryHormoneId ?? this.secondaryHormoneId),
        secondaryDose:
            clearSecondary ? null : (secondaryDose ?? this.secondaryDose),
        secondaryDoseUnit: clearSecondary
            ? null
            : (secondaryDoseUnit ?? this.secondaryDoseUnit),
        secondaryPk: clearSecondary ? null : (secondaryPk ?? this.secondaryPk),
        compound: compound ?? this.compound,
        secondaryCompound: secondaryCompound ?? this.secondaryCompound,
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
        if (secondaryHormoneId != null)
          'secondaryHormoneId': secondaryHormoneId,
        if (secondaryDose != null) 'secondaryDose': secondaryDose,
        if (secondaryDoseUnit != null) 'secondaryDoseUnit': secondaryDoseUnit,
        if (secondaryPk != null) 'secondaryPk': secondaryPk,
        if (compound != null) 'compound': compound,
        if (secondaryCompound != null) 'secondaryCompound': secondaryCompound,
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
        times: m['times'] is List && (m['times'] as List).isNotEmpty
            ? [for (final x in m['times'] as List) x as String]
            : const ['08:00'],
        weekdays: m['weekdays'] is List && (m['weekdays'] as List).isNotEmpty
            ? [for (final x in m['weekdays'] as List) (x as num).toInt()]
            : const [1],
        monthDay: (m['monthDay'] as num?)?.toInt() ?? 1,
        kind: m['kind'] ??
            ((m['everyDays'] as num?) != null ? 'interval' : 'interval'),
        secondaryHormoneId: m['secondaryHormoneId'],
        secondaryDose: (m['secondaryDose'] as num?)?.toDouble(),
        secondaryDoseUnit: m['secondaryDoseUnit'],
        secondaryPk: m['secondaryPk'],
        compound: m['compound'],
        secondaryCompound: m['secondaryCompound'],
      );
}

class DoseLog {
  const DoseLog({
    required this.id,
    required this.therapyId,
    required this.at,
    this.places = const [],
    this.dose,
    this.secondaryDose,
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
  final double? secondaryDose;
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
    double? secondaryDose,
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
        secondaryDose: secondaryDose ?? this.secondaryDose,
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
        if (secondaryDose != null) 'secondaryDose': secondaryDose,
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
            : (m['site'] is String && m['site'] != '' && m['site'] != 'oral'
                ? [_key(m['site'] as String)]
                : <String>[]),
        dose: (m['dose'] as num?)?.toDouble(),
        secondaryDose: (m['secondaryDose'] as num?)?.toDouble(),
        note: m['note'],
        wasted: (m['wasted'] as num?)?.toDouble(),
        dead: (m['dead'] as num?)?.toDouble(),
        injType: m['injType'],
        slot: m['slot'],
        usedSupplies: m['usedSupplies'] is Map
            ? {
                for (final e in (m['usedSupplies'] as Map).entries)
                  e.key as String: (e.value as num).toDouble()
              }
            : const {},
        skipped: m['skipped'] ?? false,
      );
}

class Lab {
  const Lab({
    required this.id,
    required this.hormoneId,
    required this.at,
    required this.value,
    required this.unit,
    this.note,
    this.cmp,
  });
  final String id;
  final String hormoneId;
  final DateTime at;
  final double value;
  final String unit;
  final String? note;
  final String? cmp; // '<' | '>' | null (exact)

  double get base => presetOf(hormoneId).toBase(value, unit);
  String get prefix => (cmp == '<' || cmp == '>') ? '$cmp ' : '';

  Map<String, dynamic> toMap() => {
        'hormoneId': hormoneId,
        'at': _t(at),
        'value': value,
        'unit': unit,
        'note': note,
        if (cmp == '<' || cmp == '>') 'cmp': cmp,
      };

  factory Lab.from(String id, Map<String, dynamic> m) => Lab(
        id: id,
        hormoneId: m['hormoneId'],
        at: _d(m['at']),
        value: (m['value'] as num).toDouble(),
        unit: m['unit'],
        note: m['note'],
        cmp: (m['cmp'] == '<' || m['cmp'] == '>') ? m['cmp'] as String : null,
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
    this.openedAt,
    this.beyondUseDays = 28,
    this.deadSpace,
  });
  final String id;
  final String name;
  final double qty;
  final double initial;
  final double perDose;
  final String unitLabel;
  final DateTime? expiry;
  final String kind; // med | generic
  final String?
      gtype; // syringe | wipe | needle | gloves | bandage (jika kind == generic)
  final double? dosePerUnit; // mg per unitLabel, mis. 40 mg/mL
  final DateTime? openedAt; // tanggal vial pertama kali dibuka/ditusuk
  final int beyondUseDays; // batas aman pakai setelah dibuka (default 28 hari)
  final double?
      deadSpace; // kehilangan cairan di jarum/hub per dosis (unitLabel)

  bool get generic => kind == 'generic';
  double get effectivePerDose =>
      perDose +
      ((deadSpace != null && deadSpace! > 0 && deadSpace!.isFinite)
          ? deadSpace!
          : 0.0);
  int get doses =>
      effectivePerDose > 0 ? ((qty / effectivePerDose) + 1e-9).floor() : 0;
  bool get low => generic ? qty <= 5 : doses <= 3;
  DateTime? get openExpiry => openedAt == null
      ? null
      : DateTime(
          openedAt!.year, openedAt!.month, openedAt!.day + beyondUseDays);
  DateTime? get effectiveExpiry {
    final a = expiry;
    final b = openExpiry;
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return a.isBefore(b) ? a : b;
  }

  bool get isOpenExpired =>
      openExpiry != null && openExpiry!.isBefore(DateTime.now());
  bool get expired =>
      effectiveExpiry != null && effectiveExpiry!.isBefore(DateTime.now());
  int? get daysToExpiry => expiry?.difference(DateTime.now()).inDays;
  int? get daysToOpenExpiry => openExpiry?.difference(DateTime.now()).inDays;

  Supply copy({
    String? name,
    double? qty,
    double? initial,
    double? perDose,
    String? unitLabel,
    DateTime? expiry,
    bool clearExpiry = false,
    String? kind,
    String? gtype,
    double? dosePerUnit,
    DateTime? openedAt,
    bool clearOpenedAt = false,
    int? beyondUseDays,
    double? deadSpace,
    bool clearDeadSpace = false,
  }) =>
      Supply(
        id: id,
        name: name ?? this.name,
        qty: qty ?? this.qty,
        initial: initial ?? this.initial,
        perDose: perDose ?? this.perDose,
        unitLabel: unitLabel ?? this.unitLabel,
        expiry: clearExpiry ? null : (expiry ?? this.expiry),
        kind: kind ?? this.kind,
        gtype: gtype ?? this.gtype,
        dosePerUnit: dosePerUnit ?? this.dosePerUnit,
        openedAt: clearOpenedAt ? null : (openedAt ?? this.openedAt),
        beyondUseDays: beyondUseDays ?? this.beyondUseDays,
        deadSpace: clearDeadSpace ? null : (deadSpace ?? this.deadSpace),
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
        if (openedAt != null) 'openedAt': _t(openedAt!),
        if (beyondUseDays != 28) 'beyondUseDays': beyondUseDays,
        if (deadSpace != null && deadSpace! > 0) 'deadSpace': deadSpace,
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
        dosePerUnit: (m['dosePerUnit'] as num?)?.toDouble(),
        openedAt: _optDate(m['openedAt']),
        beyondUseDays:
            ((m['beyondUseDays'] as num?)?.toInt() ?? 28).clamp(1, 365),
        deadSpace: (m['deadSpace'] as num?)?.toDouble(),
      );
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
    this.widgetHide = true,
    this.locale = 'en',
    this.discreetNotify = 'wellness',
    this.showWorkoutHomeCard = false,
    this.nextLabDate,
    this.careAllergies = '',
    this.careClinicInfo = '',
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
  final String discreetNotify; // 'off' | 'wellness' | 'minimal'
  final bool
      showWorkoutHomeCard; // tampilkan kartu pintasan Movement Coach di Home
  final DateTime? nextLabDate; // jadwal tes darah berikutnya (opsional)
  final String careAllergies; // catatan alergi/sensitivitas untuk Care Card
  final String careClinicInfo; // kontak klinik/farmasi untuk Care Card

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
    String? discreetNotify,
    bool? showWorkoutHomeCard,
    DateTime? nextLabDate,
    bool clearNextLabDate = false,
    String? careAllergies,
    String? careClinicInfo,
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
        discreetNotify: discreetNotify ?? this.discreetNotify,
        showWorkoutHomeCard: showWorkoutHomeCard ?? this.showWorkoutHomeCard,
        nextLabDate:
            clearNextLabDate ? null : (nextLabDate ?? this.nextLabDate),
        careAllergies: careAllergies ?? this.careAllergies,
        careClinicInfo: careClinicInfo ?? this.careClinicInfo,
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
        'discreetNotify': discreetNotify,
        'showWorkoutHomeCard': showWorkoutHomeCard,
        if (nextLabDate != null) 'nextLabDate': _t(nextLabDate!),
        if (careAllergies.isNotEmpty) 'careAllergies': careAllergies,
        if (careClinicInfo.isNotEmpty) 'careClinicInfo': careClinicInfo,
      };

  factory Prefs.from(Map<String, dynamic> m) => Prefs(
        theme: m['theme'] ?? 'system',
        units: m['units'] is Map
            ? {
                for (final e in (m['units'] as Map).entries)
                  e.key as String: e.value as String
              }
            : const <String, String>{},
        places: m['places'] is List && (m['places'] as List).isNotEmpty
            ? [for (final x in m['places'] as List) _key(x as String)]
            : defaultPlaces,
        hrtCounter: m['hrtCounter'] ?? true,
        dayStart: (m['dayStart'] as num?)?.toInt() ?? 240,
        accent: m['accent'] ?? 'lunera',
        notify: m['notify'] ?? false,
        widgetHide: m['widgetHide'] ?? true,
        locale: m['locale'] ?? 'en',
        discreetNotify: m['discreetNotify'] ?? 'wellness',
        showWorkoutHomeCard: m['showWorkoutHomeCard'] == true,
        nextLabDate: _optDate(m['nextLabDate']),
        careAllergies:
            m['careAllergies'] is String ? m['careAllergies'] as String : '',
        careClinicInfo:
            m['careClinicInfo'] is String ? m['careClinicInfo'] as String : '',
      );
}

/// Lokasi dan bagian tubuh yang dulu disimpan dengan nama Indonesia dipetakan ke kunci English saat dibaca.
const _legacyKeys = {
  'Paha kiri': 'Left thigh',
  'Paha kanan': 'Right thigh',
  'Bokong kiri': 'Left buttock',
  'Bokong kanan': 'Right buttock',
  'Lengan kiri': 'Left arm',
  'Lengan kanan': 'Right arm',
  'Perut kiri': 'Left abdomen',
  'Perut kanan': 'Right abdomen',
  'Kulit': 'Skin',
  'Payudara': 'Breasts',
  'Bentuk tubuh': 'Body shape',
  'Rambut': 'Hair',
  'Energi': 'Energy',
  'Tidur': 'Sleep',
};
String _key(String s) => _legacyKeys[s] ?? s;

class CloudBackup {
  const CloudBackup(
      {required this.id,
      required this.at,
      required this.count,
      required this.bytes});
  final String id;
  final DateTime at;
  final int count, bytes;
}

/// Suasana hati untuk jurnal: kunci -> (label, ikon).
const moodTypes = <String, (String, IconData)>{
  'happy': ('Happy', LucideIcons.laugh),
  'calm': ('Calm', LucideIcons.smile),
  'neutral': ('Neutral', LucideIcons.meh),
  'low': ('Low', LucideIcons.frown),
  'anxious': ('Anxious', LucideIcons.angry),
};
const moods = moodTypes;

/// Bagian tubuh untuk observasi transisi di jurnal.
const bodyAreas = ['Skin', 'Breasts', 'Body shape', 'Hair', 'Energy', 'Sleep'];

/// Presets gejala & kondisi terstruktur untuk check-in harian dan ringkasan konsultasi dokter.
const symptomPresets = <String, (String, IconData)>{
  'steady_energy': ('Steady energy', LucideIcons.zap),
  'fatigue': ('Fatigue / Low energy', LucideIcons.batteryLow),
  'restful_sleep': ('Restful sleep', LucideIcons.moon),
  'insomnia': ('Restless sleep', LucideIcons.cloudMoon),
  'hot_flashes': ('Hot flashes / Warmth', LucideIcons.flame),
  'headache': ('Headache', LucideIcons.activity),
  'tender_chest': ('Chest / Breast tenderness', LucideIcons.heartPulse),
  'site_soreness': ('Injection site soreness', LucideIcons.syringe),
  'skin_softening': ('Skin / Texture shift', LucideIcons.sparkles),
  'calm_focus': ('Calm focus', LucideIcons.sun),
};

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.at,
    this.mood,
    this.body = const {},
    this.symptoms = const [],
    this.text,
  });
  final String id;
  final DateTime at;
  final String? mood; // happy | calm | neutral | low | anxious
  final Map<String, String> body; // area -> catatan
  final List<String> symptoms; // daftar kunci dari symptomPresets
  final String? text; // catatan umum bebas

  bool get hasMood => mood != null && mood!.isNotEmpty;
  bool get hasBody => body.isNotEmpty;
  bool get hasSymptoms => symptoms.isNotEmpty;
  bool get hasText => text != null && text!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'at': _t(at),
        'mood': mood,
        'body': body,
        if (symptoms.isNotEmpty) 'symptoms': symptoms,
        'text': text,
      };

  factory JournalEntry.from(String id, Map<String, dynamic> m) => JournalEntry(
        id: id,
        at: _d(m['at']),
        mood: m['mood'],
        body: m['body'] is Map
            ? {
                for (final e in (m['body'] as Map).entries)
                  _key(e.key as String): e.value as String
              }
            : const <String, String>{},
        symptoms: m['symptoms'] is List
            ? [
                for (final x in m['symptoms'] as List)
                  if (x is String && x.trim().isNotEmpty) x.trim()
              ]
            : const <String>[],
        text: m['text'],
      );
}

/// Skor suasana hati untuk menghitung pola (1 terendah, 5 tertinggi).
const moodScore = <String, double>{
  'happy': 5,
  'calm': 4,
  'neutral': 3,
  'low': 2,
  'anxious': 1
};

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
    eu = '34';
    usW = '4';
    usM = '2.5';
    uk = '1.5';
  } else if (footCm < 22.5) {
    eu = '35';
    usW = '5';
    usM = '3.5';
    uk = '2.5';
  } else if (footCm < 23.0) {
    eu = '36';
    usW = '5.5';
    usM = '4';
    uk = '3';
  } else if (footCm < 23.5) {
    eu = '37';
    usW = '6.5';
    usM = '5';
    uk = '4';
  } else if (footCm < 24.0) {
    eu = '37.5';
    usW = '7';
    usM = '5.5';
    uk = '4.5';
  } else if (footCm < 24.5) {
    eu = '38';
    usW = '7.5';
    usM = '6';
    uk = '5';
  } else if (footCm < 25.0) {
    eu = '39';
    usW = '8.5';
    usM = '7';
    uk = '6';
  } else if (footCm < 25.5) {
    eu = '40';
    usW = '9';
    usM = '7.5';
    uk = '6.5';
  } else if (footCm < 26.0) {
    eu = '40.5';
    usW = '9.5';
    usM = '8';
    uk = '7';
  } else if (footCm < 26.5) {
    eu = '41';
    usW = '10';
    usM = '8.5';
    uk = '7.5';
  } else if (footCm < 27.0) {
    eu = '42';
    usW = '10.5';
    usM = '9';
    uk = '8';
  } else if (footCm < 27.5) {
    eu = '43';
    usW = '11.5';
    usM = '10';
    uk = '9';
  } else if (footCm < 28.0) {
    eu = '44';
    usW = '12';
    usM = '10.5';
    uk = '9.5';
  } else {
    eu = '45';
    usW = '13';
    usM = '11.5';
    uk = '10.5';
  }
  return ShoeSizeResult(
      eu: eu, usWomen: usW, usMen: usM, uk: uk, footCm: footCm);
}

/// Menghitung ukuran bra berdasarkan lingkar dada (bust) dan bawah dada (underbust) dalam cm
BraSizeResult calculateBraSize(
    {required double bustCm, required double underbustCm}) {
  final diff = (bustCm - underbustCm).clamp(0.0, 100.0);

  // Band EU & US
  int bandEu;
  int bandUs;
  if (underbustCm < 63) {
    bandEu = 60;
    bandUs = 28;
  } else if (underbustCm < 68) {
    bandEu = 65;
    bandUs = 30;
  } else if (underbustCm < 73) {
    bandEu = 70;
    bandUs = 32;
  } else if (underbustCm < 78) {
    bandEu = 75;
    bandUs = 34;
  } else if (underbustCm < 83) {
    bandEu = 80;
    bandUs = 36;
  } else if (underbustCm < 88) {
    bandEu = 85;
    bandUs = 38;
  } else if (underbustCm < 93) {
    bandEu = 90;
    bandUs = 40;
  } else if (underbustCm < 98) {
    bandEu = 95;
    bandUs = 42;
  } else if (underbustCm < 103) {
    bandEu = 100;
    bandUs = 44;
  } else if (underbustCm < 108) {
    bandEu = 105;
    bandUs = 46;
  } else {
    bandEu = 110;
    bandUs = 48;
  }

  // Cup ladder
  const cupLadder = ['AA', 'A', 'B', 'C', 'D', 'DD', 'E', 'F', 'FF', 'G'];
  String cup;
  int cupIndex;
  if (diff < 10.0) {
    cup = 'AA';
    cupIndex = 0;
  } else if (diff < 12.0) {
    cup = 'A';
    cupIndex = 1;
  } else if (diff < 14.0) {
    cup = 'B';
    cupIndex = 2;
  } else if (diff < 16.0) {
    cup = 'C';
    cupIndex = 3;
  } else if (diff < 18.0) {
    cup = 'D';
    cupIndex = 4;
  } else if (diff < 20.0) {
    cup = 'DD';
    cupIndex = 5;
  } else if (diff < 22.0) {
    cup = 'E';
    cupIndex = 6;
  } else if (diff < 24.0) {
    cup = 'F';
    cupIndex = 7;
  } else if (diff < 26.0) {
    cup = 'FF';
    cupIndex = 8;
  } else {
    cup = 'G';
    cupIndex = 9;
  }

  final usUk = '$bandUs$cup';
  final euId = '$bandEu$cup';

  String? sisterTight;
  if (bandUs > 28 && cupIndex < cupLadder.length - 1) {
    sisterTight =
        '${bandUs - 2}${cupLadder[cupIndex + 1]} (${bandEu - 5}${cupLadder[cupIndex + 1]})';
  }
  String? sisterLoose;
  if (bandUs < 48 && cupIndex > 0) {
    sisterLoose =
        '${bandUs + 2}${cupLadder[cupIndex - 1]} (${bandEu + 5}${cupLadder[cupIndex - 1]})';
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
  final String?
      shoeSize; // Ukuran sepatu yang biasa dipakai / manual (misal: "39" atau "EU 39")
  final double? weight; // Berat badan (kg)
  final double? height; // Tinggi badan (cm)
  final String? note;

  double? get bustCm =>
      bust == null ? null : (unit == 'in' ? bust! * 2.54 : bust);
  double? get underbustCm =>
      underbust == null ? null : (unit == 'in' ? underbust! * 2.54 : underbust);
  double? get waistCm =>
      waist == null ? null : (unit == 'in' ? waist! * 2.54 : waist);
  double? get hipsCm =>
      hips == null ? null : (unit == 'in' ? hips! * 2.54 : hips);
  double? get shoulderCm =>
      shoulder == null ? null : (unit == 'in' ? shoulder! * 2.54 : shoulder);
  double? get thighCm =>
      thigh == null ? null : (unit == 'in' ? thigh! * 2.54 : thigh);
  double? get calfCm =>
      calf == null ? null : (unit == 'in' ? calf! * 2.54 : calf);
  double? get inseamCm =>
      inseam == null ? null : (unit == 'in' ? inseam! * 2.54 : inseam);
  double? get footLengthCm => footLength == null
      ? null
      : (unit == 'in' ? footLength! * 2.54 : footLength);

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
    if (shoeSize != null && shoeSize!.trim().isNotEmpty)
      return shoeSize!.trim();
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

  factory BodyMeasurement.from(String id, Map<String, dynamic> m) =>
      BodyMeasurement(
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

DateTime? _optDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is Map && v.containsKey(r'$ts')) {
    final ts = v[r'$ts'];
    return ts is String ? DateTime.tryParse(ts) : null;
  }
  return null;
}

/// User configuration and baseline calibration for the HRT-aware Movement Coach.
class WorkoutProfile {
  const WorkoutProfile({
    this.id = 'main',
    this.onboarded = false,
    this.focus = 'bone_heart',
    this.level = 'gentle',
    this.equipment = const ['bodyweight'],
    this.weekdays = const [2, 4, 6],
    this.reminderTime = '18:00',
    this.notifyWorkout = false,
    this.consecutiveEasyCount = 0,
    this.baselineAt,
    this.skippedDateIso,
  });

  final String id;
  final bool onboarded;
  final String focus; // feminizing | masculinizing | bone_heart | recovery
  final String level; // gentle | steady | active
  final List<String> equipment; // bodyweight | dumbbells | bands
  final List<int> weekdays; // 1 (Mon) .. 7 (Sun)
  final String reminderTime; // HH:mm
  final bool notifyWorkout; // always OFF by default
  final int consecutiveEasyCount;
  final DateTime? baselineAt;
  final String? skippedDateIso; // YYYY-MM-DD when user chose "Rest today"

  WorkoutProfile copyWith({
    String? id,
    bool? onboarded,
    String? focus,
    String? level,
    List<String>? equipment,
    List<int>? weekdays,
    String? reminderTime,
    bool? notifyWorkout,
    int? consecutiveEasyCount,
    DateTime? baselineAt,
    bool clearBaselineAt = false,
    String? skippedDateIso,
    bool clearSkippedDate = false,
  }) =>
      WorkoutProfile(
        id: id ?? this.id,
        onboarded: onboarded ?? this.onboarded,
        focus: focus ?? this.focus,
        level: level ?? this.level,
        equipment: equipment ?? this.equipment,
        weekdays: weekdays ?? this.weekdays,
        reminderTime: reminderTime ?? this.reminderTime,
        notifyWorkout: notifyWorkout ?? this.notifyWorkout,
        consecutiveEasyCount: consecutiveEasyCount ?? this.consecutiveEasyCount,
        baselineAt: clearBaselineAt ? null : (baselineAt ?? this.baselineAt),
        skippedDateIso:
            clearSkippedDate ? null : (skippedDateIso ?? this.skippedDateIso),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'onboarded': onboarded,
        'focus': focus,
        'level': level,
        'equipment': equipment,
        'weekdays': weekdays,
        'reminderTime': reminderTime,
        'notifyWorkout': notifyWorkout,
        'consecutiveEasyCount': consecutiveEasyCount,
        if (baselineAt != null) 'baselineAt': baselineAt!.toIso8601String(),
        if (skippedDateIso != null) 'skippedDateIso': skippedDateIso,
      };

  factory WorkoutProfile.from(String id, Map<String, dynamic> m) {
    final rawEq = m['equipment'] is List
        ? [
            for (final e in m['equipment'] as List)
              if (e is String && e.trim().isNotEmpty) e.trim(),
          ]
        : const <String>['bodyweight'];
    final rawDays = m['weekdays'] is List
        ? [
            for (final d in m['weekdays'] as List)
              if (d is num && d.toInt() >= 1 && d.toInt() <= 7) d.toInt(),
          ]
        : const <int>[2, 4, 6];
    const validFocus = {
      'feminizing',
      'masculinizing',
      'bone_heart',
      'recovery'
    };
    const validLevel = {'gentle', 'steady', 'active'};
    final focus =
        validFocus.contains(m['focus']) ? m['focus'] as String : 'bone_heart';
    final level =
        validLevel.contains(m['level']) ? m['level'] as String : 'gentle';
    return WorkoutProfile(
      id: (m['id'] is String && (m['id'] as String).trim().isNotEmpty)
          ? m['id'] as String
          : id,
      onboarded: m['onboarded'] == true,
      focus: focus,
      level: level,
      equipment: rawEq.isEmpty ? const ['bodyweight'] : rawEq,
      weekdays: rawDays,
      reminderTime: m['reminderTime'] is String &&
              (m['reminderTime'] as String).contains(':')
          ? m['reminderTime'] as String
          : '18:00',
      notifyWorkout: m['notifyWorkout'] == true,
      consecutiveEasyCount:
          (m['consecutiveEasyCount'] as num?)?.toInt().clamp(0, 10) ?? 0,
      baselineAt: _optDate(m['baselineAt']),
      skippedDateIso:
          m['skippedDateIso'] is String ? m['skippedDateIso'] as String : null,
    );
  }
}

/// A single exercise entry inside a workout routine.
class WorkoutExerciseItem {
  const WorkoutExerciseItem({
    required this.exerciseId,
    this.customName,
    this.sets = 2,
    this.reps,
    this.seconds,
    this.restSeconds = 45,
    this.useEasierVariant = false,
  });

  final String exerciseId;
  final String? customName;
  final int sets;
  final int? reps;
  final int? seconds;
  final int restSeconds;
  final bool useEasierVariant;

  bool get isTimed => seconds != null && seconds! > 0;

  WorkoutExerciseItem copyWith({
    String? exerciseId,
    String? customName,
    int? sets,
    int? reps,
    bool clearReps = false,
    int? seconds,
    bool clearSeconds = false,
    int? restSeconds,
    bool? useEasierVariant,
  }) =>
      WorkoutExerciseItem(
        exerciseId: exerciseId ?? this.exerciseId,
        customName: customName ?? this.customName,
        sets: (sets ?? this.sets).clamp(1, 8),
        reps: clearReps ? null : (reps ?? this.reps),
        seconds: clearSeconds ? null : (seconds ?? this.seconds),
        restSeconds: (restSeconds ?? this.restSeconds).clamp(10, 180),
        useEasierVariant: useEasierVariant ?? this.useEasierVariant,
      );

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        if (customName != null && customName!.trim().isNotEmpty)
          'customName': customName!.trim(),
        'sets': sets,
        if (reps != null) 'reps': reps,
        if (seconds != null) 'seconds': seconds,
        'restSeconds': restSeconds,
        if (useEasierVariant) 'useEasierVariant': useEasierVariant,
      };

  factory WorkoutExerciseItem.fromMap(Map<String, dynamic> m) {
    final sets = ((m['sets'] as num?)?.toInt() ?? 2).clamp(1, 8);
    final reps = (m['reps'] as num?)?.toInt();
    final seconds = (m['seconds'] as num?)?.toInt();
    return WorkoutExerciseItem(
      exerciseId: m['exerciseId'] as String? ?? 'glute_bridge',
      customName: m['customName'] as String?,
      sets: sets,
      reps: reps != null && reps > 0 ? reps.clamp(1, 100) : null,
      seconds: seconds != null && seconds > 0 ? seconds.clamp(5, 600) : null,
      restSeconds: ((m['restSeconds'] as num?)?.toInt() ?? 45).clamp(10, 180),
      useEasierVariant: m['useEasierVariant'] == true,
    );
  }
}

/// A structured preset or user-created workout routine.
class WorkoutRoutine {
  const WorkoutRoutine({
    required this.id,
    required this.title,
    this.category = 'custom',
    this.isCustom = true,
    this.estimatedMinutes = 15,
    this.items = const [],
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String
      category; // feminizing | masculinizing | bone_heart | recovery | custom
  final bool isCustom;
  final int estimatedMinutes;
  final List<WorkoutExerciseItem> items;
  final DateTime updatedAt;

  WorkoutRoutine copyWith({
    String? id,
    String? title,
    String? category,
    bool? isCustom,
    int? estimatedMinutes,
    List<WorkoutExerciseItem>? items,
    DateTime? updatedAt,
  }) =>
      WorkoutRoutine(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        isCustom: isCustom ?? this.isCustom,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        items: items ?? this.items,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'isCustom': isCustom,
        'estimatedMinutes': estimatedMinutes,
        'items': [for (final item in items) item.toMap()],
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WorkoutRoutine.from(String id, Map<String, dynamic> m) =>
      WorkoutRoutine(
        id: (m['id'] is String && (m['id'] as String).trim().isNotEmpty)
            ? m['id'] as String
            : id,
        title: m['title'] as String? ?? 'Custom Routine',
        category: m['category'] as String? ?? 'custom',
        isCustom: m['isCustom'] != false,
        estimatedMinutes:
            ((m['estimatedMinutes'] as num?)?.toInt() ?? 15).clamp(3, 120),
        items: m['items'] is List
            ? [
                for (final x in m['items'] as List)
                  if (x is Map)
                    WorkoutExerciseItem.fromMap(x.cast<String, dynamic>()),
              ]
            : const [],
        updatedAt: _optDate(m['updatedAt']) ?? DateTime.now(),
      );
}

/// Completed workout session entry for guilt-free progress & pacing calibration.
class WorkoutSessionLog {
  const WorkoutSessionLog({
    required this.id,
    required this.at,
    required this.routineId,
    required this.routineTitle,
    this.category = 'bone_heart',
    this.durationSec = 600,
    this.completedSets = 1,
    this.totalSets = 1,
    this.effort = 'right',
    this.wasLightMode = false,
    this.note,
  });

  final String id;
  final DateTime at;
  final String routineId;
  final String routineTitle;
  final String category;
  final int durationSec;
  final int completedSets;
  final int totalSets;
  final String effort; // easy | right | tough
  final bool wasLightMode;
  final String? note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'at': at.toIso8601String(),
        'routineId': routineId,
        'routineTitle': routineTitle,
        'category': category,
        'durationSec': durationSec,
        'completedSets': completedSets,
        'totalSets': totalSets,
        'effort': effort,
        'wasLightMode': wasLightMode,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  factory WorkoutSessionLog.from(String id, Map<String, dynamic> m) =>
      WorkoutSessionLog(
        id: (m['id'] is String && (m['id'] as String).trim().isNotEmpty)
            ? m['id'] as String
            : id,
        at: _optDate(m['at']) ?? DateTime.now(),
        routineId: m['routineId'] as String? ?? '',
        routineTitle: m['routineTitle'] as String? ?? 'Movement Session',
        category: m['category'] as String? ?? 'bone_heart',
        durationSec: ((m['durationSec'] as num?)?.toInt() ?? 0).clamp(0, 86400),
        completedSets:
            ((m['completedSets'] as num?)?.toInt() ?? 0).clamp(0, 200),
        totalSets: ((m['totalSets'] as num?)?.toInt() ?? 1).clamp(1, 200),
        effort: const {'easy', 'right', 'tough'}.contains(m['effort'])
            ? m['effort'] as String
            : 'right',
        wasLightMode: m['wasLightMode'] == true,
        note: m['note'] as String?,
      );
}
