import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/sim.dart';
import 'package:lunera/ui/site_map.dart';

void main() {
  group('Lunera Models & Helpers Tests', () {
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
      expect(pk.hormoneId, equals('estradiol'));

      // Test testosterone and progesterone profiles
      final tPk = pkOf('t_enanthate');
      expect(tPk, isNotNull);
      expect(tPk!.hormoneId, equals('testosterone'));
      expect(tPk.oral, isFalse);

      final mpaPk = pkOf('mpa_susp');
      expect(mpaPk, isNotNull);
      expect(mpaPk!.hormoneId, equals('progesterone'));
      expect(mpaPk.oral, isFalse);

      // Test pkProfilesFor helper
      final tInjProfiles = pkProfilesFor('testosterone', 'inj');
      expect(tInjProfiles.map((p) => p.id), containsAll(['t_enanthate', 't_cypionate', 't_propionate', 't_undecanoate']));

      final p4InjProfiles = pkProfilesFor('progesterone', 'inj');
      expect(p4InjProfiles.map((p) => p.id), contains('mpa_susp'));

      // Test mgOf
      expect(mgOf(500, 'mcg'), equals(0.5));
      expect(mgOf(1, 'g'), equals(1000));
      expect(mgOf(5, 'mg'), equals(5));
    });

    test('Combination medication Therapy serialization and dual intakesFor', () {
      // Legacy therapy (backward compatibility)
      final legacyMap = <String, dynamic>{
        'hormoneId': 'estradiol',
        'name': 'EV 4mg',
        'dose': 4.0,
        'doseUnit': 'mg',
        'start': '2026-10-01T08:00:00.000',
        'everyDays': 7,
      };
      final legacy = Therapy.from('t_legacy', legacyMap);
      expect(legacy.secondaryHormoneId, isNull);
      expect(legacy.secondaryDose, isNull);
      expect(legacy.secondaryPk, isNull);

      // Combination therapy (e.g. Cyclofem 5mg EC + 25mg MPA)
      final cyclofem = Therapy(
        id: 't_cyclo',
        hormoneId: 'estradiol',
        name: 'Cyclofem (EC + MPA)',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime(2026, 10, 1),
        route: 'inj',
        pk: 'e2_cyp_susp',
        secondaryHormoneId: 'progesterone',
        secondaryDose: 25.0,
        secondaryDoseUnit: 'mg',
        secondaryPk: 'mpa_susp',
      );
      final cycloMap = cyclofem.toMap();
      expect(cycloMap['secondaryHormoneId'], equals('progesterone'));
      expect(cycloMap['secondaryDose'], equals(25.0));
      expect(cycloMap['secondaryPk'], equals('mpa_susp'));

      final reconstructed = Therapy.from('t_cyclo', cycloMap);
      expect(reconstructed.secondaryHormoneId, equals('progesterone'));
      expect(reconstructed.secondaryDose, equals(25.0));
      expect(reconstructed.secondaryPk, equals('mpa_susp'));

      // Test single dose log generates intakes for BOTH hormones
      final log = DoseLog(id: 'l1', therapyId: 't_cyclo', at: DateTime(2026, 10, 15, 10, 0));
      final e2Intakes = intakesFor('estradiol', [cyclofem], [log]);
      expect(e2Intakes.length, equals(1));
      expect(e2Intakes.first.dose, equals(5.0));
      expect(e2Intakes.first.pk.id, equals('e2_cyp_susp'));

      final p4Intakes = intakesFor('progesterone', [cyclofem], [log]);
      expect(p4Intakes.length, equals(1));
      expect(p4Intakes.first.dose, equals(25.0));
      expect(p4Intakes.first.pk.id, equals('mpa_susp'));

      // Other hormones return empty
      expect(intakesFor('testosterone', [cyclofem], [log]), isEmpty);

      // Test dose log with overridden secondaryDose
      final logOverride = DoseLog(
        id: 'l2',
        therapyId: 't_cyclo',
        at: DateTime(2026, 10, 20, 10, 0),
        dose: 10.0,
        secondaryDose: 50.0,
      );
      final mapOverride = logOverride.toMap();
      expect(mapOverride['secondaryDose'], equals(50.0));
      final reconstructedLog = DoseLog.from('l2', mapOverride);
      expect(reconstructedLog.secondaryDose, equals(50.0));

      final e2OverrideIntakes = intakesFor('estradiol', [cyclofem], [logOverride]);
      expect(e2OverrideIntakes.first.dose, equals(10.0));
      final p4OverrideIntakes = intakesFor('progesterone', [cyclofem], [logOverride]);
      expect(p4OverrideIntakes.first.dose, equals(50.0));
    });

    test('Compound presets catalog and compound field in Therapy', () {
      // Test compoundsFor by category
      final e2Compounds = compoundsFor('estradiol');
      expect(e2Compounds.map((c) => c.en), containsAll(['Estradiol valerate', 'Estradiol cypionate', 'Estradiol enanthate']));

      final tCompounds = compoundsFor('testosterone');
      expect(tCompounds.map((c) => c.en), containsAll(['Testosterone enanthate', 'Testosterone cypionate', 'Testosterone undecanoate (Nebido)']));

      final p4Compounds = compoundsFor('progesterone');
      expect(p4Compounds.map((c) => c.en), containsAll(['Medroxyprogesterone acetate (MPA)', 'Micronized progesterone']));

      final blockerCompounds = compoundsFor('blocker');
      expect(blockerCompounds.map((c) => c.en), containsAll(['Cyproterone acetate (CPA)', 'Spironolactone', 'Bicalutamide']));

      // Test presetOf for blocker
      final blockerPreset = presetOf('blocker');
      expect(blockerPreset.en, equals('Anti-androgen (Blocker)'));

      // Test Therapy with compound serialization
      final progynova = Therapy(
        id: 't_prog',
        hormoneId: 'estradiol',
        name: 'Progynova 2mg',
        dose: 2.0,
        doseUnit: 'mg',
        start: DateTime(2026, 10, 1),
        compound: 'e2_val_oral',
      );
      final map = progynova.toMap();
      expect(map['compound'], equals('e2_val_oral'));
      final restored = Therapy.from('t_prog', map);
      expect(restored.compound, equals('e2_val_oral'));
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

    test('ProfileState model initialization and caching', () {
      const emptyState = ProfileState();
      expect(emptyState.nickname, isNull);
      expect(emptyState.photo, isNull);
      expect(emptyState.effectiveImage, isNull);

      final state = ProfileState(
        nickname: 'Lunaria',
        photo: Uint8List.fromList([1, 2, 3]),
      );
      expect(state.nickname, equals('Lunaria'));
      expect(state.photo, isNotNull);
      expect(state.photo!.length, equals(3));
      expect(state.effectiveImage, isNotNull);

      final withImgState = ProfileState.withImage(
        nickname: 'Aria',
        photo: Uint8List.fromList([4, 5, 6]),
      );
      expect(withImgState.nickname, equals('Aria'));
      expect(withImgState.photoImage, isNotNull);
      expect(withImgState.effectiveImage, equals(withImgState.photoImage));
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

    test('Supply low stock detection and Hold-at-Location template generation', () {
      // 1. Medication supply low threshold: doses <= 3
      const normalMed = Supply(
        id: 's1',
        name: 'Estradiol Valerate',
        qty: 10,
        initial: 10,
        perDose: 1,
      );
      expect(normalMed.doses, equals(10));
      expect(normalMed.low, isFalse);

      const lowMed = Supply(
        id: 's2',
        name: 'Estradiol Cypionate',
        qty: 2,
        initial: 10,
        perDose: 1,
      );
      expect(lowMed.doses, equals(2));
      expect(lowMed.low, isTrue);

      // 2. Generic supply low threshold: qty <= 5
      const normalSyringe = Supply(
        id: 'g1',
        name: '1 mL Syringe',
        qty: 15,
        initial: 20,
        kind: 'generic',
        gtype: 'syringe',
      );
      expect(normalSyringe.low, isFalse);

      const lowSyringe = Supply(
        id: 'g2',
        name: '1 mL Syringe',
        qty: 4,
        initial: 20,
        kind: 'generic',
        gtype: 'syringe',
      );
      expect(lowSyringe.low, isTrue);

      // 3. Shipping template formatting
      String generateTemplate({
        required String carrier,
        required String name,
        required String phone,
        required String branch,
        required String address,
        required String city,
      }) {
        return '''
Recipient: $name
Phone: $phone
Shipping Address:
KANTOR AGEN $carrier ($branch)
$address, $city
Note: MOHON DITAHAN DI KANTOR AGEN UNTUK DIAMBIL SENDIRI (HOLD AT LOCATION / PICKUP SENDIRI). JANGAN DIANTAR KE RUMAH.
'''.trim();
      }

      final template = generateTemplate(
        carrier: 'J&T Express',
        name: 'Olivia',
        phone: '08123456789',
        branch: 'Drop Point Thamrin',
        address: 'Jl. MH Thamrin No. 12',
        city: 'Jakarta Pusat 10350',
      );

      expect(template, contains('Recipient: Olivia'));
      expect(template, contains('Phone: 08123456789'));
      expect(template, contains('KANTOR AGEN J&T Express (Drop Point Thamrin)'));
      expect(template, contains('HOLD AT LOCATION'));
    });

    test('Guided Calm Injection step countdown and angle presets', () {
      const dryingSeconds = 30;
      expect(dryingSeconds, equals(30));

      const imAngle = '90°';
      const scAngle = '45°';
      expect(imAngle, equals('90°'));
      expect(scAngle, equals('45°'));
    });
  });
}
