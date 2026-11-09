import 'package:flutter_test/flutter_test.dart';
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
            {'id': 'lab1', 'hormoneId': 'estradiol', 'value': 200, 'at': '2026-11-01T08:00:00.000Z'}
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

      expect(repo.validate(validLunera), equals(7));

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
    });

    test('SyncState model and debounce auto-sync queue transitions', () async {
      const initial = SyncState();
      expect(initial.status, equals(SyncStatus.idle));
      expect(initial.lastSynced, isNull);
      expect(initial.pendingCount, equals(0));

      final syncing = initial.copyWith(
        status: SyncStatus.syncing,
        pendingCount: 2,
      );
      expect(syncing.status, equals(SyncStatus.syncing));
      expect(syncing.pendingCount, equals(2));

      Repo.scheduleDebounceSync();
      expect(Repo.syncStateNotifier, isNotNull);
    });
  });
}

