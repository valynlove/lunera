import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'l10n.dart';

Object? _enc(dynamic o) {
  if (o is Timestamp) return {'\$ts': o.toDate().toUtc().toIso8601String()};
  throw UnsupportedError(tr('Unsupported type: {0}', [o]));
}

dynamic _dec(dynamic v) {
  if (v is Map) {
    if (v.length == 1 && v.containsKey('\$ts')) return Timestamp.fromDate(DateTime.parse(v['\$ts'] as String));
    return {for (final e in v.entries) e.key as String: _dec(e.value)};
  }
  if (v is List) return [for (final x in v) _dec(x)];
  return v;
}

const _wait = Duration(seconds: 10);

class Repo {
  Repo(this.uid);
  final String uid;
  static const _cols = ['therapies', 'logs', 'labs', 'supplies', 'targets', 'prefs', 'journal', 'measurements'];
  CollectionReference<Map<String, dynamic>> _c(String n) => FirebaseFirestore.instance.collection('users/$uid/$n');

  Stream<List<T>> _watch<T>(String n, T Function(String, Map<String, dynamic>) f) =>
      _c(n).snapshots().map((s) => s.docs.map((d) => f(d.id, d.data())).toList());

  Stream<List<Therapy>> therapies() => _watch('therapies', Therapy.from);
  Stream<List<DoseLog>> logs() => _watch('logs', DoseLog.from);
  Stream<List<Lab>> labs() => _watch('labs', Lab.from);
  Stream<List<Supply>> supplies() => _watch('supplies', Supply.from);
  Stream<List<JournalEntry>> journal() => _watch('journal', JournalEntry.from);
  Stream<List<BodyMeasurement>> measurements() => _watch('measurements', BodyMeasurement.from);
  Stream<Map<String, List<double>>> targets() => _c('targets').snapshots().map((s) => {
        for (final d in s.docs) d.id: [(d['low'] as num).toDouble(), (d['high'] as num).toDouble()]
      });

  // Jangan di-await dari UI: saat offline, future baru selesai setelah server menerima data.
  Future<void> addTherapy(Therapy t) => _c('therapies').add(t.toMap());
  Future<void> addLab(Lab l) => _c('labs').add(l.toMap());
  Future<void> addSupply(Supply s) => _c('supplies').add(s.toMap());
  Future<void> addMeasurement(BodyMeasurement m) => _c('measurements').add(m.toMap());
  Future<void> updateMeasurement(BodyMeasurement m) => _c('measurements').doc(m.id).set(m.toMap());
  Future<void> deleteMeasurement(String id) => _c('measurements').doc(id).delete();
  Future<void> setTarget(String h, double lo, double hi) => _c('targets').doc(h).set({'low': lo, 'high': hi});
  Future<void> adjustSupply(String id, double delta) =>
      _c('supplies').doc(id).update({'qty': FieldValue.increment(delta)});

  Future<void> updateTherapy(Therapy t) => _c('therapies').doc(t.id).set(t.toMap());
  Future<void> deleteTherapy(String id) => _c('therapies').doc(id).delete();
  Future<void> updateSupply(Supply s) => _c('supplies').doc(s.id).set(s.toMap());
  Future<void> deleteSupply(String id) => _c('supplies').doc(id).delete();
  Future<void> addJournal(JournalEntry e) => _c('journal').add(e.toMap());
  Future<void> updateJournal(JournalEntry e) => _c('journal').doc(e.id).set(e.toMap());
  Future<void> deleteJournal(String id) => _c('journal').doc(id).delete();
  Future<void> updateLab(Lab l) => _c('labs').doc(l.id).set(l.toMap());
  Future<void> deleteLab(String id) => _c('labs').doc(id).delete();

  /// Simpan catatan dosis dan kurangi stok sesuai `used`.
  Future<void> logDose(DoseLog l) {
    final b = FirebaseFirestore.instance.batch();
    b.set(_c('logs').doc(), l.toMap());
    for (final e in l.used.entries) {
      b.update(_c('supplies').doc(e.key), {'qty': FieldValue.increment(-e.value)});
    }
    return b.commit();
  }

  /// Mengubah catatan tidak mengubah stok.
  Future<void> updateLog(DoseLog l) => _c('logs').doc(l.id).set(l.toMap());

  /// Hapus catatan; stok yang terpakai dikembalikan (jika stoknya masih ada).
  Future<void> deleteLog(DoseLog l, Set<String> existingSupplies) {
    final b = FirebaseFirestore.instance.batch();
    b.delete(_c('logs').doc(l.id));
    for (final e in l.used.entries) {
      if (existingSupplies.contains(e.key)) {
        b.update(_c('supplies').doc(e.key), {'qty': FieldValue.increment(e.value)});
      }
    }
    return b.commit();
  }

  Stream<Prefs> prefs() =>
      _c('prefs').doc('main').snapshots().map((d) => d.exists ? Prefs.from(d.data()!) : const Prefs());
  Future<void> setPrefs(Prefs p) => _c('prefs').doc('main').set(p.toMap());

  // ---- Data contoh (id berawalan 'demo_') ----
  Future<void> addDemo() {
    final b = FirebaseFirestore.instance.batch();
    final n = DateTime.now();
    DateTime ago(int d, [int h = 20]) => DateTime(n.year, n.month, n.day - d, h);
    b.set(_c('supplies').doc('demo_vial'),
        Supply(id: '', name: tr('Estradiol valerate 40 mg/mL (sample)'), qty: 8, initial: 10, perDose: 0.1, unitLabel: 'mL', dosePerUnit: 40, expiry: DateTime(n.year + 1, n.month, n.day)).toMap());
    b.set(_c('supplies').doc('demo_syringe'), Supply(id: '', name: tr('Syringe (sample)'), qty: 12, initial: 20, kind: 'generic', gtype: 'syringe').toMap());
    b.set(_c('supplies').doc('demo_wipe'), Supply(id: '', name: tr('Alcohol wipe (sample)'), qty: 3, initial: 50, kind: 'generic', gtype: 'wipe').toMap());
    b.set(_c('therapies').doc('demo_inj'),
        Therapy(id: '', hormoneId: 'estradiol', name: tr('Estradiol valerate (sample)'), dose: 4, doseUnit: 'mg', start: ago(35, 0), everyDays: 7, supplyId: 'demo_vial', route: 'inj', pk: 'e2_valerate', rolling: true, injType: 'im', times: const ['20:00']).toMap());
    b.set(_c('therapies').doc('demo_pill'),
        Therapy(id: '', hormoneId: 'other', name: tr('Spironolactone (sample)'), dose: 50, doseUnit: 'mg', start: ago(35, 0), route: 'oral', times: const ['09:00']).toMap());
    for (var i = 0; i < 5; i++) {
      b.set(_c('logs').doc('demo_log$i'),
          DoseLog(id: '', therapyId: 'demo_inj', at: ago(35 - 7 * i), places: [defaultPlaces[i % defaultPlaces.length]], dose: 4, injType: 'im').toMap());
    }
    b.set(_c('labs').doc('demo_lab1'), Lab(id: '', hormoneId: 'estradiol', at: ago(21, 9), value: 180, unit: 'pg/mL').toMap());
    b.set(_c('labs').doc('demo_lab2'), Lab(id: '', hormoneId: 'estradiol', at: ago(7, 9), value: 240, unit: 'pg/mL').toMap());
    b.set(_c('labs').doc('demo_lab3'), Lab(id: '', hormoneId: 'testosterone', at: ago(21, 9), value: 35, unit: 'ng/dL').toMap());
    return b.commit();
  }

  Future<void> clearDemo() async {
    for (final n in const ['therapies', 'logs', 'labs', 'supplies']) {
      final s = await _c(n).get();
      final b = FirebaseFirestore.instance.batch();
      for (final d in s.docs) {
        if (d.id.startsWith('demo_')) b.delete(d.reference);
      }
      await b.commit();
    }
  }

  // ---- Ekspor / impor ----

  Future<String> exportJson() async {
    final data = <String, dynamic>{};
    for (final n in _cols) {
      final s = await _c(n).get();
      data[n] = [for (final d in s.docs) {'id': d.id, ...d.data()}];
    }
    return const JsonEncoder.withIndent('  ', _enc).convert({
      'metadata': {'app': 'ritme', 'version': 1, 'exported_at': DateTime.now().toIso8601String()},
      'data': data,
    });
  }

  /// Memeriksa isi cadangan. Mengembalikan jumlah catatan, atau melempar FormatException.
  int validate(dynamic raw) {
    if (raw is! Map || raw['metadata'] is! Map || raw['data'] is! Map || raw['metadata']['app'] != 'ritme') {
      throw FormatException(tr('This is not a Lunera backup file.'));
    }
    var n = 0;
    for (final k in _cols) {
      final rows = raw['data'][k];
      if (rows == null) continue;
      if (rows is! List) throw FormatException(tr('The "{0}" section is invalid.', [k]));
      for (final r in rows) {
        if (r is! Map || r['id'] is! String) throw FormatException(tr('The "{0}" section is corrupted.', [k]));
      }
      n += rows.length;
    }
    return n;
  }

  /// [replace] true: hapus data sekarang dulu. false: gabungkan (id yang sama diperbarui, tidak dobel).
  Future<void> importData(Map raw, {required bool replace}) async {
    final ops = <void Function(WriteBatch)>[];
    if (replace) {
      for (final n in _cols) {
        final s = await _c(n).get();
        for (final d in s.docs) {
          ops.add((b) => b.delete(d.reference));
        }
      }
    }
    for (final n in _cols) {
      for (final r in (raw['data'][n] as List? ?? const [])) {
        final row = _dec(r) as Map<String, dynamic>;
        final id = row.remove('id') as String;
        ops.add((b) => b.set(_c(n).doc(id), row));
      }
    }
    for (var i = 0; i < ops.length; i += 400) {
      final b = FirebaseFirestore.instance.batch();
      for (final op in ops.sublist(i, math.min(i + 400, ops.length))) {
        op(b);
      }
      // Saat offline, penulisan tetap antre dan terkirim otomatis begitu online.
      await b.commit().timeout(_wait, onTimeout: () {});
    }
  }

  // ---- Cadangan awan (disimpan di akun yang sama) ----

  Stream<List<CloudBackup>> backups() => _c('backups').orderBy('at', descending: true).snapshots().map((s) => [
        for (final d in s.docs)
          CloudBackup(id: d.id, at: (d['at'] as Timestamp).toDate(), count: (d['count'] as num).toInt(), bytes: (d['bytes'] as num).toInt())
      ]);

  Future<void> saveBackup() async {
    final js = await exportJson();
    final bytes = utf8.encode(js).length;
    if (bytes > 900000) throw FormatException(tr('Your data is too large for a single cloud backup. Use file export instead.'));
    final id = _c('backups').doc().id;
    final b = FirebaseFirestore.instance.batch();
    b.set(_c('backups').doc(id), {'at': Timestamp.now(), 'bytes': bytes, 'count': validate(jsonDecode(js))});
    b.set(_c('backupData').doc(id), {'json': js});
    await b.commit().timeout(_wait);
  }

  Future<dynamic> backupJson(String id) async {
    final d = await _c('backupData').doc(id).get();
    return jsonDecode(d.get('json') as String);
  }

  Future<void> deleteBackup(String id) {
    final b = FirebaseFirestore.instance.batch();
    b.delete(_c('backups').doc(id));
    b.delete(_c('backupData').doc(id));
    return b.commit().timeout(_wait, onTimeout: () {});
  }
}

final userProvider = StreamProvider<User?>((_) => FirebaseAuth.instance.authStateChanges());
final repoProvider = Provider<Repo?>((ref) {
  final uid = ref.watch(userProvider.select((u) => u.value?.uid));
  return uid == null ? null : Repo(uid);
});
final therapiesProvider = StreamProvider<List<Therapy>>((r) => r.watch(repoProvider)?.therapies() ?? Stream.value(<Therapy>[]));
final logsProvider = StreamProvider<List<DoseLog>>((r) => r.watch(repoProvider)?.logs() ?? Stream.value(<DoseLog>[]));
final labsProvider = StreamProvider<List<Lab>>((r) => r.watch(repoProvider)?.labs() ?? Stream.value(<Lab>[]));
final suppliesProvider = StreamProvider<List<Supply>>((r) => r.watch(repoProvider)?.supplies() ?? Stream.value(<Supply>[]));
final targetsProvider =
    StreamProvider<Map<String, List<double>>>((r) => r.watch(repoProvider)?.targets() ?? Stream.value(<String, List<double>>{}));
final backupsProvider =
    StreamProvider<List<CloudBackup>>((r) => r.watch(repoProvider)?.backups() ?? Stream.value(<CloudBackup>[]));
final journalProvider = StreamProvider<List<JournalEntry>>((r) => r.watch(repoProvider)?.journal() ?? Stream.value([]));
final measurementsProvider =
    StreamProvider<List<BodyMeasurement>>((r) => r.watch(repoProvider)?.measurements() ?? Stream.value(<BodyMeasurement>[]));
final tabProvider = StateProvider<int>((_) => 0); // tab aktif di Shell
final prefsProvider = StreamProvider<Prefs>((r) => r.watch(repoProvider)?.prefs() ?? Stream.value(const Prefs()));
