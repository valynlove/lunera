import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'models.dart';

/// Profil farmakokinetik. Injeksi: p = [F, auc, k1, k2, k3] (model 3 kompartemen).
/// Oral: p = [gain pg/mL per mg, ka, ke] per hari (model 1 kompartemen, perkiraan kasar).
/// Parameter ester injeksi diambil dari Mona (AGPL-3.0, "inferred by alix, WHSAH Collective").
class PkProfile {
  const PkProfile(this.id, this.name, this.oral, this.p);
  final String id, name;
  final bool oral;
  final List<double> p;
}

const pkProfiles = <PkProfile>[
  PkProfile('e2_enanthate', 'Enantat', false, [0.708, 875.4, 0.09441, 3.354, 0.4078]),
  PkProfile('e2_valerate', 'Valerat', false, [0.764, 621.3, 0.2230, 17.62, 1.305]),
  PkProfile('e2_benzoate', 'Benzoat', false, [0.723, 889.9, 0.5220, 521.9, 5.223]),
  PkProfile('e2_cypionate', 'Sipionat', false, [0.687, 554.5, 0.0880, 17.95, 0.7177]),
  PkProfile('e2_cyp_susp', 'Sipionat suspensi', false, [0.687, 852.6, 0.0973, 218.67, 6.624]),
  PkProfile('e2_undecylate', 'Undesilat', false, [0.618, 385.8, 0.02189, 183.4, 1.564]),
  PkProfile('e2_oral', 'Estradiol oral (kasar)', true, [27.6, 8.4, 1.188]),
];

PkProfile? pkOf(String? id) => id == null ? null : pkProfiles.where((p) => p.id == id).firstOrNull;

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
  if (dt <= 0 || dt >= (m.oral ? 10 : 100)) return 0;
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

/// Level (dalam satuan dasar hormon, pg/mL untuk estradiol) pada waktu [t].
double levelAt(List<Intake> xs, DateTime t) => xs.fold(0.0, (s, i) => s + _conc(i, t));

/// Ubah catatan dosis jadi daftar asupan untuk satu hormon (hanya terapi yang punya profil simulasi).
List<Intake> intakesFor(String hormoneId, List<Therapy> ths, List<DoseLog> logs) {
  final byId = {for (final t in ths) t.id: t};
  final out = <Intake>[];
  for (final l in logs) {
    if (l.skipped) continue;
    final t = byId[l.therapyId];
    final pk = pkOf(t?.pk);
    if (t == null || pk == null || t.hormoneId != hormoneId) continue;
    out.add(Intake(l.at, mgOf(l.dose ?? t.dose, t.doseUnit), pk));
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
