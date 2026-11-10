import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'l10n.dart';
import 'models.dart';

/// Profil farmakokinetik. Injeksi: p = [F, auc, k1, k2, k3] (model 3 kompartemen).
/// Oral / Transdermal: p = [gain satuan per mg, ka, ke] per hari (model 1 kompartemen).
/// Parameter ester estradiol diambil dari Mona (AGPL-3.0, "inferred by alix, WHSAH Collective").
/// Parameter testosteron dan progestin dimodelkan berdasarkan data farmakokinetik klinis.
class PkProfile {
  const PkProfile(this.id, this.en, this.oral, this.p, {this.hormoneId = 'estradiol'});
  final String id, en;
  String get name => tr(en);
  final bool oral;
  final List<double> p;
  final String hormoneId;
}

const pkProfiles = <PkProfile>[
  // Estradiol (E2) - satuan dasar pg/mL
  PkProfile('e2_enanthate', 'Enanthate', false, [0.708, 875.4, 0.09441, 3.354, 0.4078], hormoneId: 'estradiol'),
  PkProfile('e2_valerate', 'Valerate', false, [0.764, 621.3, 0.2230, 17.62, 1.305], hormoneId: 'estradiol'),
  PkProfile('e2_benzoate', 'Benzoate', false, [0.723, 889.9, 0.5220, 521.9, 5.223], hormoneId: 'estradiol'),
  PkProfile('e2_cypionate', 'Cypionate', false, [0.687, 554.5, 0.0880, 17.95, 0.7177], hormoneId: 'estradiol'),
  PkProfile('e2_cyp_susp', 'Cypionate suspension', false, [0.687, 852.6, 0.0973, 218.67, 6.624], hormoneId: 'estradiol'),
  PkProfile('e2_undecylate', 'Undecylate', false, [0.618, 385.8, 0.02189, 183.4, 1.564], hormoneId: 'estradiol'),
  PkProfile('e2_oral', 'Oral estradiol (rough)', true, [27.6, 8.4, 1.188], hormoneId: 'estradiol'),

  // Testosterone (T) - satuan dasar ng/dL
  PkProfile('t_enanthate', 'Enanthate', false, [0.72, 160.0, 0.154, 0.85, 3.2], hormoneId: 'testosterone'),
  PkProfile('t_cypionate', 'Cypionate', false, [0.70, 165.0, 0.140, 0.80, 3.0], hormoneId: 'testosterone'),
  PkProfile('t_propionate', 'Propionate', false, [0.837, 70.0, 0.65, 2.5, 5.0], hormoneId: 'testosterone'),
  PkProfile('t_undecanoate', 'Undecanoate (Nebido)', false, [0.63, 100.0, 0.022, 0.15, 1.5], hormoneId: 'testosterone'),
  PkProfile('t_gel', 'Transdermal gel (daily)', true, [15.0, 2.8, 0.7], hormoneId: 'testosterone'),

  // Progesterone & Progestins (P4) - satuan dasar ng/mL
  PkProfile('mpa_susp', 'Medroxyprogesterone suspension (MPA)', false, [1.0, 1.8, 0.045, 0.45, 3.0], hormoneId: 'progesterone'),
  PkProfile('p4_oral', 'Oral micronized (rough)', true, [0.065, 9.0, 1.8], hormoneId: 'progesterone'),
  PkProfile('p4_rectal', 'Rectal micronized (rough)', true, [0.12, 6.0, 1.2], hormoneId: 'progesterone'),
];

PkProfile? pkOf(String? id) => id == null ? null : pkProfiles.where((p) => p.id == id).firstOrNull;

List<PkProfile> pkProfilesFor(String hormoneId, String route) {
  return pkProfiles.where((p) {
    if (p.hormoneId != hormoneId) return false;
    if (route == 'inj') return !p.oral;
    if (route == 'oral') return p.oral && !p.id.contains('rectal') && !p.id.contains('gel');
    if (route == 'supp') return p.id.contains('rectal');
    if (route == 'gel') return p.id.contains('gel');
    return false;
  }).toList();
}

class Intake {
  const Intake(this.at, this.dose, this.pk);
  final DateTime at;
  final double dose; // mg
  final PkProfile pk;
}

double mgOf(double d, String u) => switch (u.trim().toLowerCase()) {
      'mcg' || 'µg' || 'ug' => d / 1000,
      'g' => d * 1000,
      _ => d,
    };

double _conc(Intake i, DateTime t) {
  final dt = t.difference(i.at).inMinutes / 1440.0;
  final m = i.pk;
  if (dt <= 0 || dt >= (m.oral ? 10 : 150)) return 0;
  if (m.oral) {
    final g = m.p[0], ka = m.p[1], ke = m.p[2];
    return i.dose * g * ka / (ka - ke) * (math.exp(-ke * dt) - math.exp(-ka * dt));
  }
  final f = m.p[0], auc = m.p[1], k1 = m.p[2], k2 = m.p[3], k3 = m.p[4];
  final a = math.exp(-k1 * dt) / ((k1 - k2) * (k1 - k3));
  final b = math.exp(-k2 * dt) / ((k1 - k2) * (k2 - k3));
  final c = math.exp(-k3 * dt) / ((k1 - k3) * (k2 - k3));
  return i.dose * f * auc * k1 * k2 * k3 * (a - b + c);
}

/// Level (dalam satuan dasar hormon) pada waktu [t].
double levelAt(List<Intake> xs, DateTime t) => xs.fold(0.0, (s, i) => s + _conc(i, t));

/// Ubah catatan dosis jadi daftar asupan untuk satu hormon (hanya terapi yang punya profil simulasi).
List<Intake> intakesFor(String hormoneId, List<Therapy> ths, List<DoseLog> logs) {
  final byId = {for (final t in ths) t.id: t};
  final out = <Intake>[];
  for (final l in logs) {
    if (l.skipped) continue;
    final t = byId[l.therapyId];
    if (t == null) continue;
    final pkPrimary = pkOf(t.pk);
    if (pkPrimary != null && t.hormoneId == hormoneId) {
      out.add(Intake(l.at, mgOf(l.dose ?? t.dose, t.doseUnit), pkPrimary));
    }
    final pkSecondary = pkOf(t.secondaryPk);
    final secDose = l.secondaryDose ?? t.secondaryDose;
    if (pkSecondary != null && t.secondaryHormoneId == hormoneId && secDose != null) {
      out.add(Intake(l.at, mgOf(secDose, t.secondaryDoseUnit ?? 'mg'), pkSecondary));
    }
  }
  return out;
}

List<FlSpot> simSpots(List<Intake> xs, DateTime t0, DateTime t1, {double scale = 1, int n = 300}) {
  if (xs.isEmpty) return [];
  final minutes = t1.difference(t0).inMinutes.toDouble();
  return [
    for (var k = 0; k <= n; k++)
      FlSpot(minutes * k / n / 1440, levelAt(xs, t0.add(Duration(minutes: (minutes * k / n).round()))) * scale),
  ];
}

/// Faktor skala (median lab / simulasi) dan jumlah hasil lab yang dipakai.
(double, int) calibration(List<Intake> xs, List<Lab> labs) {
  final r = <double>[];
  for (final l in labs) {
    final s = levelAt(xs, l.at);
    if (s > 1) r.add(l.base / s);
  }
  if (r.isEmpty) return (1.0, 0);
  r.sort();
  final mid = r.length ~/ 2;
  return (r.length.isOdd ? r[mid] : (r[mid - 1] + r[mid]) / 2, r.length);
}
