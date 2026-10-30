import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/lock.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/sim.dart';
import 'package:lunera/ui/app_changelog.dart';
import 'package:lunera/update_checker.dart';

void main() {
  group('Lunera Model & Simulation Tests', () {
    test('Hormone preset conversion works properly', () {
      final e2 = presetOf('estradiol');
      expect(e2.toBase(100, 'pg/mL'), equals(100));
      expect(e2.toBase(367.1, 'pmol/L'), closeTo(100, 0.1));

      final t = presetOf('testosterone');
      expect(t.toBase(5, 'ng/mL'), equals(500));
    });

    test('Number parsing handles both comma and dot formats', () {
      expect(parseNum('12.5'), equals(12.5));
      expect(parseNum('12,5'), equals(12.5));
      expect(parseNum('  40  '), equals(40.0));
      expect(parseNum('abc'), isNull);
    });

    test('Pharmacokinetic profile lookup and dose conversion', () {
      final pk = pkOf('e2_valerate');
      expect(pk, isNotNull);
      expect(pk!.name, equals('Valerat'));

      // Test mgOf
      expect(mgOf(500, 'mcg'), equals(0.5));
      expect(mgOf(1, 'g'), equals(1000));
      expect(mgOf(5, 'mg'), equals(5));
    });

    test('DoseLog handles skipped doses properly', () {
      final log = DoseLog(
        id: '1',
        therapyId: 't1',
        at: DateTime(2026, 10, 29),
        skipped: true,
      );
      expect(log.skipped, isTrue);
      final map = log.toMap();
      expect(map['skipped'], isTrue);
      final reconstructed = DoseLog.from('1', map);
      expect(reconstructed.skipped, isTrue);
    });

    test('AppLockState default values', () {
      const state = AppLockState();
      expect(state.enabled, isFalse);
      expect(state.delayMin, equals(1));
    });

    test('UpdateCheckerService version check configuration', () {
      expect(UpdateCheckerService.currentVersion, equals('1.9.0'));
    });

    test('AppChangelog releases metadata is populated and ordered', () {
      expect(AppChangelog.releases, isNotEmpty);
      expect(AppChangelog.releases.first.version, equals('1.9.0'));
      expect(AppChangelog.releases.first.isCurrent, isTrue);
      expect(AppChangelog.releases.first.changes, isNotEmpty);
    });

    test('Prefs widgetHide and locale configuration', () {
      const prefs = Prefs();
      expect(prefs.widgetHide, isFalse);
      expect(prefs.locale, equals('en'));
      final updated = prefs.copy(widgetHide: true, locale: 'id');
      expect(updated.widgetHide, isTrue);
      expect(updated.locale, equals('id'));
      expect(updated.toMap()['widgetHide'], isTrue);
      expect(updated.toMap()['locale'], equals('id'));
    });

    test('ProfileState model initialization', () {
      const emptyState = ProfileState();
      expect(emptyState.nickname, isNull);
      expect(emptyState.photo, isNull);

      final state = ProfileState(
        nickname: 'Lunaria',
        photo: Uint8List.fromList([1, 2, 3]),
      );
      expect(state.nickname, equals('Lunaria'));
      expect(state.photo, isNotNull);
      expect(state.photo!.length, equals(3));
    });

    test('JournalEntry serialization and mood scores', () {
      final now = DateTime(2026, 10, 29, 12, 0);
      final entry = JournalEntry(
        id: 'j1',
        at: now,
        mood: 'happy',
        body: {'Skin': 'Smoother', 'Energy': 'High'},
        text: 'Hari yang sangat menyenangkan',
      );

      expect(entry.hasMood, isTrue);
      expect(entry.hasBody, isTrue);
      expect(entry.hasText, isTrue);
      expect(moodScore['happy'], equals(5.0));
      expect(moods.containsKey('happy'), isTrue);
      expect(bodyAreas.contains('Skin'), isTrue);

      final map = entry.toMap();
      final reconstructed = JournalEntry.from('j1', map);
      expect(reconstructed.id, equals('j1'));
      expect(reconstructed.mood, equals('happy'));
      expect(reconstructed.body['Skin'], equals('Smoother'));
      expect(reconstructed.text, equals('Hari yang sangat menyenangkan'));
    });
  });
}
