import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/models.dart';
import 'package:lunera/repo.dart';

void main() {
  group('Lunera Repository & Backup Validation Tests', () {
    test('Repo backup validation supports lunera and legacy ritme metadata and checks row schema', () {
      final repo = Repo('dummy_uid');

      final validLunera = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'therapies': [
            {'id': 't1', 'name': 'Estradiol Valerate', 'hormoneId': 'estradiol', 'dose': 4, 'start': '2026-11-01T00:00:00.000Z'}
          ],
          'logs': [
            {'id': 'l1', 'therapyId': 't1', 'at': '2026-11-01T12:00:00.000Z'}
          ],
          'labs': [
            {'id': 'lab1', 'hormoneId': 'estradiol', 'value': 200, 'at': '2026-11-01T08:00:00.000Z'},
            {'id': 'lab2', 'hormoneId': 'testosterone', 'value': 15, 'cmp': '<', 'at': '2026-11-01T08:00:00.000Z'},
            {'id': 'lab3', 'hormoneId': 'estradiol', 'value': 1000, 'cmp': '>', 'at': '2026-11-01T08:00:00.000Z'},
          ],
          'supplies': [
            {'id': 's1', 'name': 'EV Vial', 'qty': 10}
          ],
          'journal': [
            {'id': 'j1', 'at': '2026-11-01T12:00:00.000Z'}
          ],
          'measurements': [
            {'id': 'm1', 'at': '2026-11-01T12:00:00.000Z'}
          ],
          'targets': [
            {'id': 'estradiol', 'low': 100, 'high': 200}
          ],
        }
      };

      expect(repo.validate(validLunera), equals(9));

      // Test legacy 'ritme' metadata compatibility
      final validLegacy = {
        'metadata': {'app': 'ritme', 'version': 1},
        'data': {
          'supplies': [
            {'id': 's1', 'name': 'EV Vial', 'qty': 10}
          ]
        }
      };
      expect(repo.validate(validLegacy), equals(1));

      // Rejects unknown app metadata
      expect(
        () => repo.validate({'metadata': {'app': 'unknown'}, 'data': {}}),
        throwsFormatException,
      );

      // Rejects corrupted row (missing vital field)
      final corruptedData = {
        'metadata': {'app': 'lunera'},
        'data': {
          'logs': [
            {'id': 'l1', 'at': '2026-11-01T12:00:00.000Z'} // missing therapyId
          ]
        }
      };
      expect(() => repo.validate(corruptedData), throwsFormatException);

      // Rejects path-traversal/invalid document IDs and non-finite or negative numbers
      expect(
        () => repo.validate({
          'metadata': {'app': 'lunera'},
          'data': {
            'supplies': [
              {'id': 'bad/id', 'name': 'Vial', 'qty': 1}
            ]
          }
        }),
        throwsFormatException,
      );
      expect(
        () => repo.validate({
          'metadata': {'app': 'lunera'},
          'data': {
            'supplies': [
              {'id': '..', 'name': 'Vial', 'qty': 1}
            ]
          }
        }),
        throwsFormatException,
      );
      expect(
        () => repo.validate({
          'metadata': {'app': 'lunera'},
          'data': {
            'supplies': [
              {'id': 's1', 'name': 'Vial', 'qty': -1}
            ]
          }
        }),
        throwsFormatException,
      );
      expect(
        () => repo.validate({
          'metadata': {'app': 'lunera'},
          'data': {
            'labs': [
              {'id': 'lab1', 'hormoneId': 'estradiol', 'value': double.nan, 'at': '2026-11-01T08:00:00.000Z'}
            ]
          }
        }),
        throwsFormatException,
      );
      expect(
        () => repo.validate({
          'metadata': {'app': 'lunera'},
          'data': {
            'labs': [
              {'id': 'lab1', 'hormoneId': 'estradiol', 'value': 100, 'cmp': '~', 'at': '2026-11-01T08:00:00.000Z'}
            ]
          }
        }),
        throwsFormatException,
      );
      expect(
        () => repo.validate({
          'metadata': {'app': 'lunera'},
          'data': {
            'labs': [
              {'id': 'lab1', 'hormoneId': 'estradiol', 'value': 100, 'cmp': 123, 'at': '2026-11-01T08:00:00.000Z'}
            ]
          }
        }),
        throwsFormatException,
      );
    });

    test('SyncState copyWith clears errorMessage cleanly and trackWrite transitions idle -> syncing -> synced', () async {
      Repo.resetSyncStateForTest();
      addTearDown(Repo.resetSyncStateForTest);

      const initial = SyncState();
      expect(initial.status, equals(SyncStatus.idle));
      expect(initial.lastSynced, isNull);
      expect(initial.pendingCount, equals(0));

      final errored = initial.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Network failure',
      );
      expect(errored.errorMessage, equals('Network failure'));
      final cleared = errored.copyWith(status: SyncStatus.synced, errorMessage: null);
      expect(cleared.errorMessage, isNull);

      final completer = Completer<void>();
      final writeFuture = Repo.trackWrite(() => completer.future);

      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.syncing));
      expect(Repo.syncStateNotifier.value.pendingCount, equals(1));

      completer.complete();
      await writeFuture;

      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.synced));
      expect(Repo.syncStateNotifier.value.pendingCount, equals(0));
      expect(Repo.syncStateNotifier.value.lastSynced, isNotNull);
    });

    test('trackWrite transitions to queuedOffline only when local queue is verified and recovers on server ack', () async {
      Repo.resetSyncStateForTest();
      addTearDown(Repo.resetSyncStateForTest);

      final serverAck = Completer<void>();
      await Repo.trackWrite(
        () => serverAck.future,
        verifyQueued: () async => true,
        timeout: const Duration(milliseconds: 20),
      );

      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.queuedOffline));
      expect(Repo.syncStateNotifier.value.pendingCount, equals(1));
      expect(Repo.syncStateNotifier.value.lastSynced, isNull);

      serverAck.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.synced));
      expect(Repo.syncStateNotifier.value.pendingCount, equals(0));
      expect(Repo.syncStateNotifier.value.lastSynced, isNotNull);
    });

    test('trackWrite refuses queuedOffline on timeout without local queue verification', () async {
      Repo.resetSyncStateForTest();
      addTearDown(Repo.resetSyncStateForTest);

      final hangingOp = Completer<void>();
      await Repo.trackWrite(
        () => hangingOp.future,
        verifyQueued: () async => false,
        timeout: const Duration(milliseconds: 20),
      );

      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.error));
      expect(Repo.syncStateNotifier.value.errorMessage, isNotEmpty);

      // Server eventually resolves later -> cleanly recovers from timeout error
      hangingOp.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.synced));
    });

    test('trackWrite protects active Error state from stale ops and recovers on subsequent successful write', () async {
      Repo.resetSyncStateForTest();
      addTearDown(Repo.resetSyncStateForTest);

      final op1 = Completer<void>();
      final op2 = Completer<void>();

      final f1 = Repo.trackWrite(() => op1.future, timeout: const Duration(seconds: 2));
      final f2 = Repo.trackWrite(() => op2.future, timeout: const Duration(seconds: 2));

      expect(Repo.syncStateNotifier.value.pendingCount, equals(2));

      // Newer op2 fails before older op1 completes
      op2.completeError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'Denied'));
      await f2;
      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.syncing)); // op1 still running

      // Older op1 started BEFORE op2 failed, so op1 completing must NOT overwrite op2's error
      op1.complete();
      await f1;
      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.error));
      expect(Repo.syncStateNotifier.value.errorMessage, equals('Denied'));

      // Subsequent fresh write started AFTER the error succeeds and recovers to synced
      await Repo.trackWrite(() async {});
      expect(Repo.syncStateNotifier.value.status, equals(SyncStatus.synced));
      expect(Repo.syncStateNotifier.value.errorMessage, isNull);
      expect(Repo.syncStateNotifier.value.pendingCount, equals(0));
    });

    test('executeDoseLogWrite rescues DoseLog when referenced supplies no longer exist', () async {
      final log = DoseLog(
        id: '',
        therapyId: 't1',
        at: DateTime(2026, 11, 15, 9, 0),
        dose: 4.0,
        used: {'sup_ok': 1.0, 'sup_deleted': 2.0},
      );

      // Case 1: existingSupplies filters missing supply before batch runs
      DoseLog? capturedBatchLog;
      Map<String, double>? capturedUsed;
      await Repo.executeDoseLogWrite(
        log,
        existingSupplies: {'sup_ok'},
        commitBatch: (l, used) async {
          capturedBatchLog = l;
          capturedUsed = used;
        },
        commitLogOnly: (_) async => fail('Should not fall back when pre-filtered'),
      );
      expect(capturedUsed, equals({'sup_ok': 1.0}));
      expect(capturedBatchLog?.used, equals({'sup_ok': 1.0}));

      // Case 2: Stale local set causes server not-found -> falls back to logOnly + surviving supply decrement
      DoseLog? rescuedLog;
      final decremented = <String, double>{};
      await Repo.executeDoseLogWrite(
        log,
        commitBatch: (_, __) async => throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        commitLogOnly: (l) async => rescuedLog = l,
        supplyExists: (id) async => id == 'sup_ok',
        decrementSupply: (id, delta) async => decremented[id] = delta,
      );
      expect(rescuedLog, isNotNull);
      expect(rescuedLog!.used, equals({'sup_ok': 1.0}));
      expect(decremented, equals({'sup_ok': -1.0}));
    });
  });
}

