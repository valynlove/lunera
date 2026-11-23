import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'l10n.dart';
import 'voice_pitch.dart';

/// Status sinkronisasi real-time otomatis latar belakang.
enum SyncStatus { idle, syncing, queuedOffline, synced, error }

class SyncState {
  static const _unset = Object();

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSynced,
    this.errorMessage,
    this.pendingCount = 0,
  });

  final SyncStatus status;
  final DateTime? lastSynced;
  final String? errorMessage;
  final int pendingCount;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSynced,
    Object? errorMessage = _unset,
    int? pendingCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSynced: lastSynced ?? this.lastSynced,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}

Object? _enc(dynamic o) {
  if (o is Timestamp) return {'\$ts': o.toDate().toUtc().toIso8601String()};
  throw UnsupportedError(tr('Unsupported type: {0}', [o]));
}

dynamic _dec(dynamic v) {
  if (v is Map) {
    if (v.length == 1 && v.containsKey('\$ts')) {
      return Timestamp.fromDate(DateTime.parse(v['\$ts'] as String));
    }
    return {for (final e in v.entries) e.key as String: _dec(e.value)};
  }
  if (v is List) return [for (final x in v) _dec(x)];
  return v;
}

const _wait = Duration(seconds: 10);

class Repo {
  Repo(this.uid);
  final String uid;
  static const _cols = [
    'therapies',
    'logs',
    'labs',
    'supplies',
    'targets',
    'prefs',
    'journal',
    'measurements',
    'voiceResults'
  ];
  CollectionReference<Map<String, dynamic>> _c(String n) =>
      FirebaseFirestore.instance.collection('users/$uid/$n');

  /// Notifier status sinkronisasi real-time yang dapat diakses secara global.
  static final syncStateNotifier = ValueNotifier<SyncState>(const SyncState());
  static const Duration writeTimeout = Duration(seconds: 4);
  static int _opSeq = 0;
  static int _eventSeq = 0;
  static final Set<int> _inFlightOps = <int>{};
  static final Set<int> _queuedOfflineOps = <int>{};
  static int _lastErrorEventSeq = 0;
  static int _lastErrorOpId = 0;
  static String? _lastErrorMessage;

  @visibleForTesting
  static void resetSyncStateForTest() {
    _opSeq = 0;
    _eventSeq = 0;
    _inFlightOps.clear();
    _queuedOfflineOps.clear();
    _lastErrorEventSeq = 0;
    _lastErrorOpId = 0;
    _lastErrorMessage = null;
    syncStateNotifier.value = const SyncState();
  }

  static String _formatSyncError(Object error) {
    if (error is FirebaseException) {
      return error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : error.code;
    }
    return error.toString();
  }

  /// Memverifikasi pada cache lokal Firestore bahwa dokumen target benar-benar memiliki pending writes.
  static Future<bool> hasPendingWritesForDocs(
      List<DocumentReference<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return false;
    try {
      for (final doc in docs) {
        final snap = await doc.get(const GetOptions(source: Source.cache));
        if (snap.exists && snap.metadata.hasPendingWrites) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Melacak satu operasi tulis per-opId: membedakan syncing, queuedOffline (terverifikasi),
  /// synced (konfirmasi server), dan error tanpa timpa-menimpa akibat race condition.
  static Future<void> trackWrite(
    Future<void> Function() writeOp, {
    Future<bool> Function()? verifyQueued,
    Duration timeout = writeTimeout,
  }) async {
    final opId = ++_opSeq;
    final startEventSeq = ++_eventSeq;
    _inFlightOps.add(opId);

    syncStateNotifier.value = SyncState(
      status: SyncStatus.syncing,
      lastSynced: syncStateNotifier.value.lastSynced,
      pendingCount: _inFlightOps.length + _queuedOfflineOps.length,
    );

    final Future<void> writeFuture;
    try {
      writeFuture = writeOp();
    } catch (e) {
      _inFlightOps.remove(opId);
      _lastErrorEventSeq = ++_eventSeq;
      _lastErrorOpId = opId;
      _lastErrorMessage = _formatSyncError(e);
      debugPrint('[Repo] Safe write sync throw (op=$opId): $e');
      syncStateNotifier.value = SyncState(
        status: _inFlightOps.isNotEmpty ? SyncStatus.syncing : SyncStatus.error,
        lastSynced: syncStateNotifier.value.lastSynced,
        errorMessage: _lastErrorMessage,
        pendingCount: _inFlightOps.length + _queuedOfflineOps.length,
      );
      return;
    }

    var settled = false;
    var timedOut = false;

    final completionFuture = writeFuture.then((_) {
      settled = true;
      _inFlightOps.remove(opId);
      _queuedOfflineOps.remove(opId);

      // Pulih dari error hanya jika error sebelumnya milik op ini sendiri atau terjadi sebelum op ini dimulai.
      if (_lastErrorEventSeq > 0 &&
          (_lastErrorOpId == opId || startEventSeq > _lastErrorEventSeq)) {
        _lastErrorEventSeq = 0;
        _lastErrorOpId = 0;
        _lastErrorMessage = null;
      }

      final pending = _inFlightOps.length + _queuedOfflineOps.length;
      if (_lastErrorEventSeq > startEventSeq && _lastErrorOpId != opId) {
        syncStateNotifier.value = SyncState(
          status:
              _inFlightOps.isNotEmpty ? SyncStatus.syncing : SyncStatus.error,
          lastSynced: syncStateNotifier.value.lastSynced,
          errorMessage: _lastErrorMessage,
          pendingCount: pending,
        );
        return;
      }

      if (_inFlightOps.isNotEmpty) {
        syncStateNotifier.value = SyncState(
          status: SyncStatus.syncing,
          lastSynced: syncStateNotifier.value.lastSynced,
          pendingCount: pending,
        );
      } else if (_queuedOfflineOps.isNotEmpty) {
        syncStateNotifier.value = SyncState(
          status: SyncStatus.queuedOffline,
          lastSynced: syncStateNotifier.value.lastSynced,
          pendingCount: pending,
        );
      } else {
        syncStateNotifier.value = SyncState(
          status: SyncStatus.synced,
          lastSynced: DateTime.now(),
          pendingCount: 0,
        );
      }
    }, onError: (Object e, StackTrace _) {
      settled = true;
      _inFlightOps.remove(opId);
      _queuedOfflineOps.remove(opId);
      _lastErrorEventSeq = ++_eventSeq;
      _lastErrorOpId = opId;
      _lastErrorMessage = _formatSyncError(e);
      debugPrint('[Repo] Safe write failed (op=$opId): $e');

      final pending = _inFlightOps.length + _queuedOfflineOps.length;
      syncStateNotifier.value = SyncState(
        status: _inFlightOps.isNotEmpty ? SyncStatus.syncing : SyncStatus.error,
        lastSynced: syncStateNotifier.value.lastSynced,
        errorMessage: _lastErrorMessage,
        pendingCount: pending,
      );
    });

    try {
      await completionFuture.timeout(timeout);
    } on TimeoutException {
      timedOut = true;
    }

    if (!timedOut || settled) return;

    var queuedLocally = false;
    if (verifyQueued != null) {
      try {
        queuedLocally = await verifyQueued();
      } catch (e) {
        debugPrint('[Repo] Offline queue verification failed (op=$opId): $e');
      }
    }

    if (settled) return;

    _inFlightOps.remove(opId);
    if (queuedLocally) {
      _queuedOfflineOps.add(opId);
      final pending = _inFlightOps.length + _queuedOfflineOps.length;
      if (_inFlightOps.isNotEmpty) {
        syncStateNotifier.value = SyncState(
          status: SyncStatus.syncing,
          lastSynced: syncStateNotifier.value.lastSynced,
          pendingCount: pending,
        );
      } else if (_lastErrorEventSeq > startEventSeq && _lastErrorOpId != opId) {
        syncStateNotifier.value = SyncState(
          status: SyncStatus.error,
          lastSynced: syncStateNotifier.value.lastSynced,
          errorMessage: _lastErrorMessage,
          pendingCount: pending,
        );
      } else {
        syncStateNotifier.value = SyncState(
          status: SyncStatus.queuedOffline,
          lastSynced: syncStateNotifier.value.lastSynced,
          pendingCount: pending,
        );
      }
    } else {
      _lastErrorEventSeq = ++_eventSeq;
      _lastErrorOpId = opId;
      _lastErrorMessage = tr('Sync timed out before confirmation.');
      final pending = _inFlightOps.length + _queuedOfflineOps.length;
      syncStateNotifier.value = SyncState(
        status: _inFlightOps.isNotEmpty ? SyncStatus.syncing : SyncStatus.error,
        lastSynced: syncStateNotifier.value.lastSynced,
        errorMessage: _lastErrorMessage,
        pendingCount: pending,
      );
    }
  }

  /// Eksekusi penulisan dengan proteksi timeout & verifikasi antrean offline pada dokumen target.
  Future<void> _safeWrite(
    Future<void> Function() writeOp, {
    List<DocumentReference<Map<String, dynamic>>> targetDocs = const [],
  }) =>
      trackWrite(
        writeOp,
        verifyQueued: targetDocs.isEmpty
            ? null
            : () => hasPendingWritesForDocs(targetDocs),
      );

  Stream<List<T>> _watch<T>(
          String n, T Function(String, Map<String, dynamic>) f) =>
      _c(n)
          .snapshots()
          .map((s) => s.docs.map((d) => f(d.id, d.data())).toList());

  Stream<List<Therapy>> therapies() => _watch('therapies', Therapy.from);
  Stream<List<DoseLog>> logs() => _watch('logs', DoseLog.from);
  Stream<List<Lab>> labs() => _watch('labs', Lab.from);
  Stream<List<Supply>> supplies() => _watch('supplies', Supply.from);
  Stream<List<JournalEntry>> journal() => _watch('journal', JournalEntry.from);
  Stream<List<BodyMeasurement>> measurements() =>
      _watch('measurements', BodyMeasurement.from);
  Stream<List<VoiceTestResult>> voiceResults() =>
      _c('voiceResults').snapshots().map((s) {
        final out = <VoiceTestResult>[
          for (final d in s.docs)
            if (VoiceTestResult.tryFrom(d.id, d.data()) case final r?) r,
        ];
        out.sort((a, b) => b.at.compareTo(a.at));
        return out;
      });
  Stream<Map<String, List<double>>> targets() =>
      _c('targets').snapshots().map((s) => {
            for (final d in s.docs)
              d.id: [
                (d['low'] as num).toDouble(),
                (d['high'] as num).toDouble()
              ]
          });

  // Operasi tulis non-blocking (dilindungi pelacakan per-operasi, verifikasi antrean offline, dan timeout 4 detik)
  Future<void> addTherapy(Therapy t) {
    final ref = _c('therapies').doc();
    return _safeWrite(() => ref.set(t.toMap()), targetDocs: [ref]);
  }

  Future<void> addLab(Lab l) {
    final ref = _c('labs').doc();
    return _safeWrite(() => ref.set(l.toMap()), targetDocs: [ref]);
  }

  Future<void> addSupply(Supply s) {
    final ref = _c('supplies').doc();
    return _safeWrite(() => ref.set(s.toMap()), targetDocs: [ref]);
  }

  Future<void> addMeasurement(BodyMeasurement m) {
    final ref = _c('measurements').doc();
    return _safeWrite(() => ref.set(m.toMap()), targetDocs: [ref]);
  }

  Future<void> updateMeasurement(BodyMeasurement m) {
    final ref = _c('measurements').doc(m.id);
    return _safeWrite(() => ref.set(m.toMap()), targetDocs: [ref]);
  }

  Future<void> deleteMeasurement(String id) =>
      _safeWrite(() => _c('measurements').doc(id).delete());

  Future<void> saveVoiceResult(VoiceTestResult r) {
    final id = r.id.trim();
    final ref =
        id.isEmpty ? _c('voiceResults').doc() : _c('voiceResults').doc(id);
    return _safeWrite(() => ref.set(r.toMap()), targetDocs: [ref]);
  }

  Future<void> deleteVoiceResult(String id) =>
      _safeWrite(() => _c('voiceResults').doc(id).delete());

  Future<void> clearVoiceResults(
      {Iterable<String> knownIds = const []}) async {
    final refs = <String, DocumentReference<Map<String, dynamic>>>{
      for (final id in knownIds)
        if (id.trim().isNotEmpty) id: _c('voiceResults').doc(id),
    };
    try {
      final s = await _c('voiceResults').get().timeout(_wait);
      for (final d in s.docs) {
        refs[d.id] = d.reference;
      }
    } catch (_) {
      // Offline or timed out fetching doc list: knownIds still get queued for deletion.
    }
    if (refs.isEmpty) return;
    final list = refs.values.toList();
    for (var i = 0; i < list.length; i += 400) {
      final chunk = list.sublist(i, math.min(i + 400, list.length));
      await _safeWrite(() {
        final b = FirebaseFirestore.instance.batch();
        for (final ref in chunk) {
          b.delete(ref);
        }
        return b.commit();
      });
    }
  }

  Future<void> setTarget(String h, double lo, double hi) {
    final ref = _c('targets').doc(h);
    return _safeWrite(() => ref.set({'low': lo, 'high': hi}),
        targetDocs: [ref]);
  }

  Future<void> adjustSupply(String id, double delta) {
    final ref = _c('supplies').doc(id);
    return _safeWrite(() => ref.update({'qty': FieldValue.increment(delta)}),
        targetDocs: [ref]);
  }

  Future<void> updateTherapy(Therapy t) {
    final ref = _c('therapies').doc(t.id);
    return _safeWrite(() => ref.set(t.toMap()), targetDocs: [ref]);
  }

  Future<void> deleteTherapy(String id) =>
      _safeWrite(() => _c('therapies').doc(id).delete());

  Future<void> updateSupply(Supply s) {
    final ref = _c('supplies').doc(s.id);
    return _safeWrite(() => ref.set(s.toMap()), targetDocs: [ref]);
  }

  Future<void> deleteSupply(String id) =>
      _safeWrite(() => _c('supplies').doc(id).delete());

  Future<void> addJournal(JournalEntry e) {
    final ref = _c('journal').doc();
    return _safeWrite(() => ref.set(e.toMap()), targetDocs: [ref]);
  }

  Future<void> updateJournal(JournalEntry e) {
    final ref = _c('journal').doc(e.id);
    return _safeWrite(() => ref.set(e.toMap()), targetDocs: [ref]);
  }

  Future<void> deleteJournal(String id) =>
      _safeWrite(() => _c('journal').doc(id).delete());

  Future<void> updateLab(Lab l) {
    final ref = _c('labs').doc(l.id);
    return _safeWrite(() => ref.set(l.toMap()), targetDocs: [ref]);
  }

  Future<void> deleteLab(String id) =>
      _safeWrite(() => _c('labs').doc(id).delete());

  /// Menulis DoseLog dengan perlindungan agar catatan dosis tidak hilang bila supply terkait sudah terhapus.
  @visibleForTesting
  static Future<void> executeDoseLogWrite(
    DoseLog log, {
    Set<String>? existingSupplies,
    required Future<void> Function(
            DoseLog logToSave, Map<String, double> validUsed)
        commitBatch,
    required Future<void> Function(DoseLog logToSave) commitLogOnly,
    Future<bool> Function(String supplyId)? supplyExists,
    Future<void> Function(String supplyId, double delta)? decrementSupply,
  }) async {
    final filteredUsed = existingSupplies == null
        ? <String, double>{
            for (final e in log.used.entries)
              if (e.value != 0) e.key: e.value,
          }
        : <String, double>{
            for (final e in log.used.entries)
              if (existingSupplies.contains(e.key) && e.value != 0)
                e.key: e.value,
          };

    if (filteredUsed.isEmpty) {
      final cleanLog =
          log.used.isEmpty ? log : log.copy(usedSupplies: const {});
      await commitLogOnly(cleanLog);
      return;
    }

    final initialLog = filteredUsed.length == log.used.length
        ? log
        : log.copy(usedSupplies: filteredUsed);
    try {
      await commitBatch(initialLog, filteredUsed);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      // Salah satu dokumen supply tidak ditemukan di server/cache: selamatkan DoseLog dulu,
      // lalu kurangi stok hanya untuk supply yang masih ada.
      final survivingUsed = <String, double>{};
      for (final entry in filteredUsed.entries) {
        var exists = true;
        if (supplyExists != null) {
          try {
            exists = await supplyExists(entry.key);
          } catch (_) {
            exists = false;
          }
        }
        if (exists) {
          survivingUsed[entry.key] = entry.value;
        }
      }

      await commitLogOnly(log.copy(usedSupplies: survivingUsed));
      if (decrementSupply != null) {
        for (final entry in survivingUsed.entries) {
          try {
            await decrementSupply(entry.key, -entry.value);
          } on FirebaseException catch (se) {
            if (se.code != 'not-found') rethrow;
          }
        }
      }
    }
  }

  /// Simpan catatan dosis dan kurangi stok sesuai `used` (tetap aman bila supply sudah dihapus).
  Future<void> logDose(DoseLog l, {Set<String>? existingSupplies}) {
    final logRef = _c('logs').doc();
    return _safeWrite(
      () => executeDoseLogWrite(
        l,
        existingSupplies: existingSupplies,
        commitBatch: (logToSave, validUsed) {
          final b = FirebaseFirestore.instance.batch();
          b.set(logRef, logToSave.toMap());
          for (final e in validUsed.entries) {
            b.update(_c('supplies').doc(e.key),
                {'qty': FieldValue.increment(-e.value)});
          }
          return b.commit();
        },
        commitLogOnly: (logToSave) => logRef.set(logToSave.toMap()),
        supplyExists: (id) async => (await _c('supplies').doc(id).get()).exists,
        decrementSupply: (id, delta) =>
            _c('supplies').doc(id).update({'qty': FieldValue.increment(delta)}),
      ),
      targetDocs: [logRef],
    );
  }

  /// Mengubah catatan tidak mengubah stok.
  Future<void> updateLog(DoseLog l) {
    final ref = _c('logs').doc(l.id);
    return _safeWrite(() => ref.set(l.toMap()), targetDocs: [ref]);
  }

  /// Hapus catatan; stok yang terpakai dikembalikan (jika stoknya masih ada).
  Future<void> deleteLog(DoseLog l, Set<String> existingSupplies) =>
      _safeWrite(() {
        final b = FirebaseFirestore.instance.batch();
        b.delete(_c('logs').doc(l.id));
        for (final e in l.used.entries) {
          if (existingSupplies.contains(e.key)) {
            b.update(_c('supplies').doc(e.key),
                {'qty': FieldValue.increment(e.value)});
          }
        }
        return b.commit();
      });

  /// Impor/gabungkan daftar riwayat dosis tanpa menghapus riwayat lama dan tanpa memotong stok.
  Future<void> importDoseLogs(List<DoseLog> logs) async {
    if (logs.isEmpty) return;
    for (var i = 0; i < logs.length; i += 400) {
      final chunk = logs.sublist(i, math.min(i + 400, logs.length));
      final refs = [for (final l in chunk) _c('logs').doc(l.id)];
      await _safeWrite(() {
        final b = FirebaseFirestore.instance.batch();
        for (var j = 0; j < chunk.length; j++) {
          b.set(refs[j], chunk[j].toMap());
        }
        return b.commit();
      }, targetDocs: refs);
    }
  }

  Stream<Prefs> prefs() => _c('prefs')
      .doc('main')
      .snapshots()
      .map((d) => d.exists ? Prefs.from(d.data()!) : const Prefs());
  Future<void> setPrefs(Prefs p) {
    final ref = _c('prefs').doc('main');
    return _safeWrite(() => ref.set(p.toMap()), targetDocs: [ref]);
  }

  // ---- Data contoh (id berawalan 'demo_') ----
  Future<void> addDemo() {
    final b = FirebaseFirestore.instance.batch();
    final n = DateTime.now();
    DateTime ago(int d, [int h = 20]) =>
        DateTime(n.year, n.month, n.day - d, h);
    b.set(
        _c('supplies').doc('demo_vial'),
        Supply(
                id: '',
                name: tr('Estradiol valerate 40 mg/mL (sample)'),
                qty: 8,
                initial: 10,
                perDose: 0.1,
                unitLabel: 'mL',
                dosePerUnit: 40,
                expiry: DateTime(n.year + 1, n.month, n.day))
            .toMap());
    b.set(
        _c('supplies').doc('demo_syringe'),
        Supply(
                id: '',
                name: tr('Syringe (sample)'),
                qty: 12,
                initial: 20,
                kind: 'generic',
                gtype: 'syringe')
            .toMap());
    b.set(
        _c('supplies').doc('demo_wipe'),
        Supply(
                id: '',
                name: tr('Alcohol wipe (sample)'),
                qty: 3,
                initial: 50,
                kind: 'generic',
                gtype: 'wipe')
            .toMap());
    b.set(
        _c('therapies').doc('demo_inj'),
        Therapy(
            id: '',
            hormoneId: 'estradiol',
            name: tr('Estradiol valerate (sample)'),
            dose: 4,
            doseUnit: 'mg',
            start: ago(35, 0),
            everyDays: 7,
            supplyId: 'demo_vial',
            route: 'inj',
            pk: 'e2_valerate',
            rolling: true,
            injType: 'im',
            times: const ['20:00']).toMap());
    b.set(
        _c('therapies').doc('demo_pill'),
        Therapy(
            id: '',
            hormoneId: 'other',
            name: tr('Spironolactone (sample)'),
            dose: 50,
            doseUnit: 'mg',
            start: ago(35, 0),
            route: 'oral',
            times: const ['09:00']).toMap());
    for (var i = 0; i < 5; i++) {
      b.set(
          _c('logs').doc('demo_log$i'),
          DoseLog(
                  id: '',
                  therapyId: 'demo_inj',
                  at: ago(35 - 7 * i),
                  places: [defaultPlaces[i % defaultPlaces.length]],
                  dose: 4,
                  injType: 'im')
              .toMap());
    }
    b.set(
        _c('labs').doc('demo_lab1'),
        Lab(
                id: '',
                hormoneId: 'estradiol',
                at: ago(21, 9),
                value: 180,
                unit: 'pg/mL')
            .toMap());
    b.set(
        _c('labs').doc('demo_lab2'),
        Lab(
                id: '',
                hormoneId: 'estradiol',
                at: ago(7, 9),
                value: 240,
                unit: 'pg/mL')
            .toMap());
    b.set(
        _c('labs').doc('demo_lab3'),
        Lab(
                id: '',
                hormoneId: 'testosterone',
                at: ago(21, 9),
                value: 35,
                unit: 'ng/dL')
            .toMap());
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
      data[n] = [
        for (final d in s.docs) {'id': d.id, ...d.data()}
      ];
    }
    return const JsonEncoder.withIndent('  ', _enc).convert({
      // Kompatibilitas cadangan: mendukung tanda pengenal Lunera dan 'ritme' untuk backup lama.
      'metadata': {
        'app': 'lunera',
        'legacy_app': 'ritme',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String()
      },
      'data': data,
    });
  }

  static bool _isValidDocId(dynamic id) {
    if (id is! String) return false;
    final s = id.trim();
    if (s.isEmpty || s.length > 128 || s == '.' || s == '..' || s.contains('/')) {
      return false;
    }
    return true;
  }

  static double? _finiteNum(dynamic v) {
    if (v is num) {
      final d = v.toDouble();
      return d.isFinite ? d : null;
    }
    if (v is String) {
      final d = double.tryParse(v);
      return (d != null && d.isFinite) ? d : null;
    }
    return null;
  }

  static bool _isValidDate(dynamic d) {
    if (d == null) return false;
    if (d is Timestamp || d is DateTime) return true;
    if (d is String) return DateTime.tryParse(d) != null;
    if (d is Map && d.containsKey(r'$ts')) {
      final ts = d[r'$ts'];
      return ts is String && DateTime.tryParse(ts) != null;
    }
    return false;
  }

  static bool _isValidRow(String col, Map r) {
    switch (col) {
      case 'therapies':
        final doseOk = r['dose'] == null ||
            (_finiteNum(r['dose']) != null && _finiteNum(r['dose'])! >= 0);
        return r['name'] is String && r['hormoneId'] is String && doseOk;
      case 'logs':
        return r['therapyId'] is String && _isValidDate(r['at']);
      case 'labs':
        final val = _finiteNum(r['value']);
        final cmp = r['cmp'];
        final cmpOk = cmp == null || cmp == '<' || cmp == '>';
        return r['hormoneId'] is String &&
            _isValidDate(r['at']) &&
            val != null &&
            val >= 0 &&
            cmpOk;
      case 'supplies':
        final qty = _finiteNum(r['qty']);
        return r['name'] is String && qty != null && qty >= 0;
      case 'journal':
      case 'measurements':
        return _isValidDate(r['at']);
      case 'voiceResults':
        final avg = _finiteNum(r['avgHz']);
        final min = _finiteNum(r['minHz']);
        final max = _finiteNum(r['maxHz']);
        final cat = r['category'];
        return _isValidDate(r['at']) &&
            avg != null &&
            avg > 0 &&
            min != null &&
            min > 0 &&
            max != null &&
            max > 0 &&
            (cat == null || cat is String);
      case 'targets':
        return _finiteNum(r['low']) != null && _finiteNum(r['high']) != null;
      default:
        return true;
    }
  }

  /// Memeriksa isi cadangan. Mengembalikan jumlah catatan, atau melempar FormatException.
  int validate(dynamic raw) {
    final app =
        (raw is Map && raw['metadata'] is Map) ? raw['metadata']['app'] : null;
    if (raw is! Map ||
        raw['metadata'] is! Map ||
        raw['data'] is! Map ||
        (app != 'lunera' && app != 'ritme')) {
      throw FormatException(tr('This is not a Lunera backup file.'));
    }
    var n = 0;
    for (final k in _cols) {
      final rows = raw['data'][k];
      if (rows == null) continue;
      if (rows is! List) {
        throw FormatException(tr('The "{0}" section is invalid.', [k]));
      }
      for (final r in rows) {
        if (r is! Map || !_isValidDocId(r['id']) || !_isValidRow(k, r)) {
          throw FormatException(tr('The "{0}" section is corrupted.', [k]));
        }
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
        if (n == 'prefs') {
          row.remove('geminiApiKey');
          row.remove('asteriaMode');
        }
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

  Stream<List<CloudBackup>> backups() =>
      _c('backups').orderBy('at', descending: true).snapshots().map((s) => [
            for (final d in s.docs)
              CloudBackup(
                  id: d.id,
                  at: (d['at'] as Timestamp).toDate(),
                  count: (d['count'] as num).toInt(),
                  bytes: (d['bytes'] as num).toInt())
          ]);

  Future<void> saveBackup() async {
    final js = await exportJson();
    final bytes = utf8.encode(js).length;
    if (bytes > 900000) {
      throw FormatException(tr(
          'Your data is too large for a single cloud backup. Use file export instead.'));
    }
    final id = _c('backups').doc().id;
    final b = FirebaseFirestore.instance.batch();
    b.set(_c('backups').doc(id), {
      'at': Timestamp.now(),
      'bytes': bytes,
      'count': validate(jsonDecode(js))
    });
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

final userProvider =
    StreamProvider<User?>((_) => FirebaseAuth.instance.authStateChanges());
final repoProvider = Provider<Repo?>((ref) {
  final uid = ref.watch(userProvider.select((u) => u.value?.uid));
  return uid == null ? null : Repo(uid);
});
final therapiesProvider = StreamProvider<List<Therapy>>(
    (r) => r.watch(repoProvider)?.therapies() ?? Stream.value(<Therapy>[]));
final logsProvider = StreamProvider<List<DoseLog>>(
    (r) => r.watch(repoProvider)?.logs() ?? Stream.value(<DoseLog>[]));
final labsProvider = StreamProvider<List<Lab>>(
    (r) => r.watch(repoProvider)?.labs() ?? Stream.value(<Lab>[]));
final suppliesProvider = StreamProvider<List<Supply>>(
    (r) => r.watch(repoProvider)?.supplies() ?? Stream.value(<Supply>[]));
final targetsProvider = StreamProvider<Map<String, List<double>>>((r) =>
    r.watch(repoProvider)?.targets() ?? Stream.value(<String, List<double>>{}));
final backupsProvider = StreamProvider<List<CloudBackup>>(
    (r) => r.watch(repoProvider)?.backups() ?? Stream.value(<CloudBackup>[]));
final journalProvider = StreamProvider<List<JournalEntry>>(
    (r) => r.watch(repoProvider)?.journal() ?? Stream.value([]));
final measurementsProvider = StreamProvider<List<BodyMeasurement>>((r) =>
    r.watch(repoProvider)?.measurements() ?? Stream.value(<BodyMeasurement>[]));
final voiceResultsProvider = StreamProvider<List<VoiceTestResult>>((r) =>
    r.watch(repoProvider)?.voiceResults() ?? Stream.value(<VoiceTestResult>[]));
final tabProvider = StateProvider<int>(
    (_) => 2); // tab aktif di Shell (default: 2 = Beranda/Home)
final prefsProvider = StreamProvider<Prefs>(
    (r) => r.watch(repoProvider)?.prefs() ?? Stream.value(const Prefs()));

/// Reads [repoProvider] when a [ProviderScope] ancestor exists; returns null in standalone widget trees/tests.
Repo? maybeRepoFrom(BuildContext context) {
  try {
    return ProviderScope.containerOf(context, listen: false).read(repoProvider);
  } catch (_) {
    return null;
  }
}

/// Notifier reaktif untuk memantau status antrean sinkronisasi latar belakang.
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    Repo.syncStateNotifier.addListener(_onStateChange);
    ref.onDispose(() => Repo.syncStateNotifier.removeListener(_onStateChange));
    return Repo.syncStateNotifier.value;
  }

  void _onStateChange() {
    state = Repo.syncStateNotifier.value;
  }
}

final syncStateProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
