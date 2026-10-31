import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/lock.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/sim.dart';
import 'package:lunera/ui/app_changelog.dart';
import 'package:lunera/ui/site_map.dart';
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
      expect(pk!.en, equals('Valerate'));
      expect(pk.name, isNotEmpty);

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

    test('AppLockState default values and decoyCalculator', () {
      const state = AppLockState();
      expect(state.enabled, isFalse);
      expect(state.delayMin, equals(1));
      expect(state.decoyCalculator, isFalse);

      const decoyState = AppLockState(enabled: true, decoyCalculator: true);
      expect(decoyState.decoyCalculator, isTrue);
    });

    test('UpdateCheckerService version check configuration', () {
      expect(UpdateCheckerService.currentVersion, equals('1.11.10'));
    });

    test('AppChangelog releases metadata is populated and ordered', () {
      expect(AppChangelog.releases, isNotEmpty);
      expect(AppChangelog.releases.first.version, equals('1.11.10'));
      expect(AppChangelog.releases.first.isCurrent, isTrue);
      expect(AppChangelog.releases.first.changes, isNotEmpty);
    });

    test('Prefs widgetHide, locale, discreetNotify, and geminiApiKey configuration', () {
      const prefs = Prefs();
      expect(prefs.widgetHide, isFalse);
      expect(prefs.locale, equals('en'));
      expect(prefs.discreetNotify, equals('off'));
      expect(prefs.geminiApiKey, equals(''));
      final updated = prefs.copy(widgetHide: true, locale: 'id', discreetNotify: 'wellness', geminiApiKey: 'test-api-key');
      expect(updated.widgetHide, isTrue);
      expect(updated.locale, equals('id'));
      expect(updated.discreetNotify, equals('wellness'));
      expect(updated.geminiApiKey, equals('test-api-key'));
      expect(updated.toMap()['widgetHide'], isTrue);
      expect(updated.toMap()['locale'], equals('id'));
      expect(updated.toMap()['discreetNotify'], equals('wellness'));
      expect(updated.toMap()['geminiApiKey'], equals('test-api-key'));
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

    test('BodyMeasurement and bra size calculations', () {
      final m = BodyMeasurement(
        id: 'm1',
        at: DateTime(2026, 10, 31),
        unit: 'cm',
        bust: 88,
        underbust: 74,
        waist: 68,
        hips: 92,
        thigh: 52,
        calf: 34,
        inseam: 76,
        footLength: 24.5,
      );

      final bra = m.braSize;
      expect(bra, isNotNull);
      expect(bra!.bandUs, equals(34));
      expect(bra.bandEu, equals(75));
      expect(bra.cup, equals('C'));
      expect(bra.usUk, equals('34C'));
      expect(bra.euId, equals('75C'));
      expect(bra.sisterTight, contains('32D'));
      expect(bra.sisterLoose, contains('36B'));

      expect(m.topSize, equals('M'));
      expect(m.bottomSize, equals('27–28 (S) / L30'));
      expect(m.thighCm, equals(52.0));
      expect(m.calfCm, equals(34.0));
      expect(m.inseamCm, equals(76.0));
      expect(m.footLengthCm, equals(24.5));
      expect(m.shoeSizeResult?.eu, equals('39'));
      expect(m.shoeSizeResult?.usWomen, equals('8.5'));
      expect(m.displayShoeSize, contains('EU 39'));
      expect(m.waistToHipRatio, closeTo(0.739, 0.01));

      final map = m.toMap();
      final recon = BodyMeasurement.from('m1', map);
      expect(recon.bust, equals(88.0));
      expect(recon.underbust, equals(74.0));
      expect(recon.thigh, equals(52.0));
      expect(recon.calf, equals(34.0));
      expect(recon.inseam, equals(76.0));
      expect(recon.footLength, equals(24.5));

      // Test backward-compatibility with legacy data (missing thigh, calf, inseam, footLength)
      final legacyMap = {
        'at': {r'$ts': '2026-10-31T00:00:00.000Z'},
        'unit': 'cm',
        'bust': 88.0,
        'underbust': 74.0,
        'waist': 68.0,
        'hips': 92.0,
      };
      final legacyRecon = BodyMeasurement.from('legacy1', legacyMap);
      expect(legacyRecon.bust, equals(88.0));
      expect(legacyRecon.thigh, isNull);
      expect(legacyRecon.calf, isNull);
      expect(legacyRecon.inseam, isNull);
      expect(legacyRecon.footLength, isNull);
      expect(legacyRecon.shoeSize, isNull);
      expect(legacyRecon.bottomSize, equals('27–28 (S)'));
    });

    test('Injection site status and rotation health computation', () {
      const prefs = Prefs(places: ['Left thigh', 'Right thigh', 'Left buttock']);
      final now = DateTime.now();

      final logs = [
        DoseLog(
          id: 'l1',
          therapyId: 't1',
          at: now.subtract(const Duration(days: 1)),
          places: ['Left thigh'],
        ),
        DoseLog(
          id: 'l2',
          therapyId: 't1',
          at: now.subtract(const Duration(days: 10)),
          places: ['Right thigh'],
        ),
      ];

      final statuses = getSiteStatuses(
        sites: prefs.places,
        logsDesc: logs,
        prefs: prefs,
        therapyId: 't1',
      );

      expect(statuses.containsKey('Left thigh'), isTrue);
      expect(statuses['Left thigh']!.isResting, isTrue); // Injected 1 day ago (resting)
      expect(statuses['Left thigh']!.daysSince, equals(1));

      expect(statuses.containsKey('Right thigh'), isTrue);
      expect(statuses['Right thigh']!.isResting, isFalse); // Injected 10 days ago (ready)
      expect(statuses['Right thigh']!.daysSince, equals(10));

      expect(statuses.containsKey('Left buttock'), isTrue);
      expect(statuses['Left buttock']!.isResting, isFalse); // Never used (ready)
      expect(statuses['Left buttock']!.daysSince, isNull);
    });

    test('Body overview silhouette proportions are bounded on tablets and mobile', () {
      const h = 420.0;

      // Phone screen (e.g. maxW = 340)
      const phoneMaxW = 340.0;
      const phoneDiagramW = phoneMaxW > 460.0 ? 440.0 : phoneMaxW;
      final phoneSw = (phoneDiagramW * .3).clamp(80.0, h * 0.25);
      final phoneCx = (phoneDiagramW * .2).clamp(55.0, phoneSw * 0.75);

      expect(phoneDiagramW, equals(340.0));
      expect(phoneSw, equals(102.0));
      expect(phoneCx, equals(68.0));

      // Tablet screen landscape (e.g. maxW = 1200)
      const tabletMaxW = 1200.0;
      const tabletDiagramW = tabletMaxW > 460.0 ? 440.0 : tabletMaxW;
      final tabletSw = (tabletDiagramW * .3).clamp(80.0, h * 0.25);
      final tabletCx = (tabletDiagramW * .2).clamp(55.0, tabletSw * 0.75);

      expect(tabletDiagramW, equals(440.0));
      expect(tabletSw, equals(105.0)); // Strictly bounded, preventing squashed/gepeng drawing
      expect(tabletCx, equals(78.75));
    });

    test('Prefs mode and key backward compatibility', () {
      const defaultPrefs = Prefs();
      expect(defaultPrefs.asteriaMode, equals('shared'));
      final personalPrefs = defaultPrefs.copy(asteriaMode: 'personal', geminiApiKey: 'my-key');
      expect(personalPrefs.asteriaMode, equals('personal'));
      expect(personalPrefs.geminiApiKey, equals('my-key'));

      final map = personalPrefs.toMap();
      final reconstructed = Prefs.from(map);
      expect(reconstructed.asteriaMode, equals('personal'));
      expect(reconstructed.geminiApiKey, equals('my-key'));
    });

    test('Decoy calculator number formatting and verification logic', () {
      String fmt(double v) {
        if (v.isNaN || v.isInfinite) return 'Error';
        if (v == v.roundToDouble()) return v.toInt().toString();
        return v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
      }

      expect(fmt(10.0), equals('10'));
      expect(fmt(12.5), equals('12.5'));
      expect(fmt(1 / 3), startsWith('0.333333'));
      expect(fmt(0.0), equals('0'));
    });
  });
}
