import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lunera/guides_data.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/article_page.dart';
import 'package:lunera/ui/sanctuary/sanctuary_page.dart';
import 'package:lunera/ui/sanctuary/voice_pitch_page.dart';
import 'package:lunera/voice_pitch.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    L10n.notifier.value = 'en';
    SharedPreferences.setMockInitialValues({});
    VoiceStore.resetSessionStateForTest();
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('On-device voice pitch detection & categories', () {
    test('detects sine frequencies and maps all 8 plain-language categories',
        () {
      final deepPcm = synthesizePcm16Sine(frequencyHz: 115.0, durationMs: 80);
      final deepHz = detectPitchFromPcm16(deepPcm);
      expect(deepHz, isNotNull);
      expect(deepHz!, closeTo(115.0, 4.0));
      expect(categorizePitchHz(deepHz), equals(VoicePitchCategory.deep));

      final midPcm = synthesizePcm16Sine(frequencyHz: 180.0, durationMs: 80);
      final midHz = detectPitchFromPcm16(midPcm);
      expect(midHz, isNotNull);
      expect(midHz!, closeTo(180.0, 4.0));
      expect(categorizePitchHz(midHz), equals(VoicePitchCategory.neutral));

      final brightPcm = synthesizePcm16Sine(frequencyHz: 230.0, durationMs: 80);
      final brightHz = detectPitchFromPcm16(brightPcm);
      expect(brightHz, isNotNull);
      expect(brightHz!, closeTo(230.0, 5.0));
      expect(categorizePitchHz(brightHz), equals(VoicePitchCategory.bright));

      // Verify exact threshold mapping & plain-language descriptions across all 8 tiers
      expect(categorizePitchHz(90), equals(VoicePitchCategory.veryDeep));
      expect(categorizePitchHz(115), equals(VoicePitchCategory.deep));
      expect(categorizePitchHz(140), equals(VoicePitchCategory.low));
      expect(categorizePitchHz(160), equals(VoicePitchCategory.midLow));
      expect(categorizePitchHz(180), equals(VoicePitchCategory.neutral));
      expect(categorizePitchHz(205), equals(VoicePitchCategory.softHigh));
      expect(categorizePitchHz(230), equals(VoicePitchCategory.bright));
      expect(categorizePitchHz(260), equals(VoicePitchCategory.veryHigh));
      for (final c in VoicePitchCategory.values) {
        expect(c.label, isNotEmpty);
        expect(c.description, isNotEmpty);
        expect(c.rangeHint, isNotEmpty);
      }

      // Legacy category keys preserve backward compatibility
      expect(VoicePitchCategoryMeta.fromKey('low'),
          equals(VoicePitchCategory.low));
      expect(VoicePitchCategoryMeta.fromKey('neutral'),
          equals(VoicePitchCategory.neutral));
      expect(VoicePitchCategoryMeta.fromKey('high'),
          equals(VoicePitchCategory.softHigh));
    });

    test('provides bilingual article passages and session metrics', () {
      expect(voiceReadingPassages.length, greaterThanOrEqualTo(5));
      for (final p in voiceReadingPassages) {
        L10n.notifier.value = 'en';
        expect(p.title.trim(), isNotEmpty);
        expect(p.topic.trim(), isNotEmpty);
        expect(p.body.split(' ').length, greaterThanOrEqualTo(45));
        L10n.notifier.value = 'id';
        expect(p.title.trim(), isNotEmpty);
        expect(p.topic.trim(), isNotEmpty);
        expect(p.body.split(' ').length, greaterThanOrEqualTo(45));
      }
      L10n.notifier.value = 'en';

      final metrics = computeVoiceSessionMetrics(
        const [170, 185, 200, 210],
        VoiceTargetRange.feminine, // 185..230
      )!;
      expect(metrics.inTargetPercent, closeTo(75.0, 0.1));
      expect(metrics.spreadHz, closeTo(40.0, 0.1));
      expect(metrics.intonationLabel, equals('Natural Inflection'));
    });

    test('returns null on silence', () {
      final silent =
          synthesizePcm16Sine(frequencyHz: 180.0, durationMs: 80, amplitude: 0);
      expect(detectPitchFromPcm16(silent), isNull);
    });
  });

  group('VoiceStore unlock & numeric-only results', () {
    test(
        'starts locked and persists unlock, target range, save, delete, and clear',
        () async {
      expect(await VoiceStore.isUnlocked(), isFalse);
      await VoiceStore.setUnlocked(true);
      expect(await VoiceStore.isUnlocked(), isTrue);

      expect(
          await VoiceStore.loadTargetRange(), equals(const VoiceTargetRange()));
      final savedRange = await VoiceStore.saveTargetRange(
        const VoiceTargetRange(minHz: 190, maxHz: 225),
      );
      expect(
          savedRange, equals(const VoiceTargetRange(minHz: 190, maxHz: 225)));
      expect(await VoiceStore.loadTargetRange(), equals(savedRange));

      final item = VoiceTestResult(
        id: 'r1',
        at: DateTime(2026, 11, 22, 19, 30),
        avgHz: 196.4,
        minHz: 184.0,
        maxHz: 212.0,
        category: VoicePitchCategory.softHigh,
      );
      final afterSave = await VoiceStore.saveResult(item);
      expect(afterSave.length, equals(1));
      expect(afterSave.first.avgHz, closeTo(196.4, 0.1));

      final afterDelete = await VoiceStore.deleteResult('r1');
      expect(afterDelete, isEmpty);

      await VoiceStore.saveResult(item);
      await VoiceStore.clearResults();
      expect(await VoiceStore.loadResults(), isEmpty);
    });

    test(
        'VoiceTestResult toMap/tryFrom supports Timestamp, DateTime, ISO, and \$ts',
        () {
      final at = DateTime.utc(2026, 11, 22, 18, 45, 30);
      final original = VoiceTestResult(
        id: 'sync_1',
        at: at,
        avgHz: 205.44,
        minHz: 188.12,
        maxHz: 224.89,
        category: VoicePitchCategory.softHigh,
      );

      final firestoreMap = original.toMap();
      expect(firestoreMap['at'], isA<Timestamp>());
      expect(firestoreMap['avgHz'], equals(205.4));
      expect(firestoreMap['minHz'], equals(188.1));
      expect(firestoreMap['maxHz'], equals(224.9));
      expect(firestoreMap['category'], equals('softHigh'));
      expect(firestoreMap.containsKey('audio'), isFalse);

      expect(VoiceTestResult.tryFrom('sync_1', firestoreMap)?.avgHz,
          equals(205.4));
      expect(
        VoiceTestResult.tryFrom('sync_2', {...firestoreMap, 'at': at})?.at,
        equals(at),
      );
      expect(
        VoiceTestResult.tryFrom(
            'sync_3', {...firestoreMap, 'at': at.toIso8601String()})?.category,
        equals(VoicePitchCategory.softHigh),
      );
      expect(
        VoiceTestResult.tryFrom('sync_4', {
          ...firestoreMap,
          'at': {r'$ts': at.toIso8601String()},
        })?.maxHz,
        equals(224.9),
      );
      expect(
        VoiceTestResult.tryFrom(
            'legacy_1', {...firestoreMap, 'category': 'high'})?.category,
        equals(VoicePitchCategory.softHigh),
      );

      // Invalid entries return null safely
      expect(VoiceTestResult.tryFrom(' ', firestoreMap), isNull);
      expect(
          VoiceTestResult.tryFrom('x', {...firestoreMap, 'avgHz': 0}), isNull);
      expect(
          VoiceTestResult.tryFrom('x', {...firestoreMap, 'at': 'bad'}), isNull);

      // Optional contextTag round-trips cleanly while remaining backward compatible
      final withTag = VoiceTestResult(
        id: 'tag_1',
        at: at,
        avgHz: 198.0,
        minHz: 185.0,
        maxHz: 210.0,
        category: VoicePitchCategory.softHigh,
        contextTag: 'warmed_up',
      );
      expect(withTag.toMap()['contextTag'], equals('warmed_up'));
      expect(
        VoiceTestResult.fromJson(withTag.toJson())?.contextTag,
        equals('warmed_up'),
      );
      expect(
        VoiceTestResult.tryFrom('tag_1', withTag.toMap())?.contextTag,
        equals('warmed_up'),
      );
      expect(original.toMap().containsKey('contextTag'), isFalse);
      expect(VoiceTestResult.tryFrom('no_tag', firestoreMap)?.contextTag, isNull);
    });

    test('analyzes resonance brightness, vocal weight, warmup steps, and tags',
        () {
      final silent =
          synthesizePcm16Sine(frequencyHz: 140.0, durationMs: 90, amplitude: 0);
      expect(analyzeVoiceToneFromPcm16(silent), isNull);

      final pureWarm = synthesizePcm16Sine(frequencyHz: 140.0, durationMs: 90);
      final warmAnalysis = analyzeVoiceToneFromPcm16(pureWarm, f0Hz: 140.0);
      expect(warmAnalysis, isNotNull);
      expect(warmAnalysis!.brightnessScore, lessThan(0.36));
      expect(warmAnalysis.weightScore, lessThan(0.36));
      expect(warmAnalysis.brightnessLabel, isNotEmpty);
      expect(warmAnalysis.weightLabel, isNotEmpty);

      // Heavy & bright upper-harmonic waveform at 200 Hz -> up to 2400 Hz
      final brightHeavyPcm = synthesizePcm16Harmonic(
        frequencyHz: 200.0,
        harmonicWeights: const [0.25, 0.5, 0.7, 0.9, 1.0, 1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7],
        durationMs: 90,
      );
      final brightHeavyAnalysis =
          analyzeVoiceToneFromPcm16(brightHeavyPcm, f0Hz: 200.0);
      expect(brightHeavyAnalysis, isNotNull);
      expect(brightHeavyAnalysis!.brightnessScore, greaterThan(0.60));
      expect(brightHeavyAnalysis.weightScore, greaterThan(0.55));

      expect(voiceWarmupSteps.length, equals(4));
      expect(voiceReferenceTones.length, equals(4));
      for (final step in voiceWarmupSteps) {
        L10n.notifier.value = 'en';
        expect(step.title, isNotEmpty);
        expect(step.subtitle, isNotEmpty);
        expect(step.tip, isNotEmpty);
        expect(step.durationSeconds, greaterThan(0));
        L10n.notifier.value = 'id';
        expect(step.title, isNotEmpty);
        expect(step.tip, isNotEmpty);
      }
      L10n.notifier.value = 'en';
      expect(voiceContextTagLabel('warmed_up'), equals('Warmed up'));
      L10n.notifier.value = 'id';
      expect(voiceContextTagLabel('warmed_up'), equals('Sudah pemanasan'));
      L10n.notifier.value = 'en';
      expect(voiceContextTagLabel(null), isNull);
    });

    test(
        'reconcileWithRemote uploads legacy items, propagates deletes, and auto-unlocks',
        () async {
      final legacyLocal = VoiceTestResult(
        id: 'local_1',
        at: DateTime(2026, 11, 22, 10, 0),
        avgHz: 172.0,
        minHz: 158.0,
        maxHz: 185.0,
        category: VoicePitchCategory.neutral,
      );
      final remoteItem = VoiceTestResult(
        id: 'remote_1',
        at: DateTime(2026, 11, 22, 12, 0),
        avgHz: 215.0,
        minHz: 198.0,
        maxHz: 235.0,
        category: VoicePitchCategory.bright,
      );

      // Simulate existing local item never uploaded before, plus a remote item from device B.
      await VoiceStore.saveResult(legacyLocal);
      final uploaded = <VoiceTestResult>[];
      final merged = await VoiceStore.reconcileWithRemote(
        [remoteItem],
        uploadMissing: (r) async => uploaded.add(r),
      );
      expect(uploaded.map((e) => e.id), equals(['local_1']));
      expect(merged.map((e) => e.id), equals(['remote_1', 'local_1']));
      // Auto-unlocked on a fresh device because sanctuary.voice_unlocked was unset.
      expect(await VoiceStore.isUnlocked(), isTrue);

      // Now simulate local_1 echoed in remote, then remote_1 deleted on Device B.
      await VoiceStore.reconcileWithRemote([remoteItem, legacyLocal]);
      final afterRemoteDelete =
          await VoiceStore.reconcileWithRemote([legacyLocal]);
      expect(afterRemoteDelete.map((e) => e.id), equals(['local_1']));

      // Stale remote snapshot must not resurrect a same-session local delete.
      await VoiceStore.deleteResult('local_1');
      final afterStale = await VoiceStore.reconcileWithRemote([legacyLocal]);
      expect(afterStale, isEmpty);

      // Same-session clearResults guards against stale non-empty snapshot, then resets on empty.
      await VoiceStore.saveResult(legacyLocal);
      await VoiceStore.clearResults(knownIds: ['local_1']);
      expect(await VoiceStore.reconcileWithRemote([legacyLocal]), isEmpty);
      expect(await VoiceStore.reconcileWithRemote(const []), isEmpty);

      // Explicit hide (setUnlocked(false)) must not be overridden when synced results arrive.
      await VoiceStore.setUnlocked(false);
      await VoiceStore.reconcileWithRemote([remoteItem]);
      expect(await VoiceStore.isUnlocked(), isFalse);
    });
  });

  group('Voice Pitch Studio easter egg & widget tests', () {
    testWidgets(
        '5 taps on Voice Resonance card unlocks Voice Pitch Studio in Sanctuary',
        (tester) async {
      final voiceArticle = guideById('voice_training')!;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: ArticlePage(article: voiceArticle),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Voice Resonance & Pacing Studio'),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Voice Resonance & Pacing Studio'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(await VoiceStore.isUnlocked(), isTrue);
      expect(find.text('Open Voice Pitch Studio'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const SanctuaryPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Voice Pitch Studio'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Voice Pitch Studio'), findsOneWidget);
    });

    testWidgets(
        'VoicePitchPage measures injected PCM stream and saves numeric result',
        (tester) async {
      late StreamController<Uint8List> controller;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: VoicePitchPage(
            streamBuilder: () {
              controller = StreamController<Uint8List>();
              return controller.stream;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reading prompt'), findsOneWidget);

      // Switch to Article passage mode and verify editorial passage renders cleanly
      await tester.tap(find.text('Article passage'));
      await tester.pumpAndSettle();
      expect(find.textContaining('read'), findsWidgets);

      // Expand target range editor and select Feminine preset without layout overflow
      await tester.scrollUntilVisible(
        find.text('Adjust target'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Adjust target'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adjust target'));
      await tester.pumpAndSettle();
      expect(find.text('Target zone'), findsOneWidget);
      await tester.ensureVisible(find.text('Feminine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Feminine'));
      await tester.pumpAndSettle();
      expect(find.text('Target: 185–230 Hz'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Start live voice check'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Start live voice check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start live voice check'));
      await tester.pump();

      controller.add(synthesizePcm16Sine(frequencyHz: 205.0, durationMs: 120));
      await tester.pump();
      await controller.close();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Voice Size / Resonance'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Voice Size / Resonance'), findsOneWidget);
      expect(find.text('Vocal Weight'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Warmed up'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Warmed up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Warmed up'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Save result (numbers only)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Save result (numbers only)'));
      await tester.pumpAndSettle();
      expect(find.text('Save result (numbers only)'), findsOneWidget);
      await tester.tap(find.text('Save result (numbers only)'));
      await tester.pumpAndSettle();

      expect(find.text('Result saved (numbers only)'), findsOneWidget);
      final saved = await VoiceStore.loadResults();
      expect(saved.length, equals(1));
      expect(saved.first.category, equals(VoicePitchCategory.softHigh));
      expect(saved.first.contextTag, equals('warmed_up'));
    });

    testWidgets(
        'Quiet Warm-up tab guides through 4 SOVTE steps cleanly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const VoicePitchPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quiet Warm-up'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Neck, Jaw & Shoulder Release'), findsOneWidget);
      expect(find.text('20s'), findsOneWidget);

      await tester.ensureVisible(find.text('Start step'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start step'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('19s'), findsOneWidget);

      await tester.ensureVisible(find.text('Pause warm-up'));
      await tester.pump();
      await tester.tap(find.text('Pause warm-up'));
      await tester.pump();
      expect(find.text('Start step'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Next step'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next step'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('SOVTE: Straw or Lip Trill'), findsOneWidget);
    });

    testWidgets(
        'SanctuaryPage auto-unlocks and VoicePitchPage syncs saves, trend chart, and deletes via Repo',
        (tester) async {
      final fakeRepo = _FakeVoiceRepo();
      addTearDown(fakeRepo.dispose);

      // Device starts locked locally.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repoProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const SanctuaryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Voice Pitch Studio'), findsNothing);

      // Two remote synced results arrive -> unlocks Studio automatically & feeds trend chart.
      final olderRemote = VoiceTestResult(
        id: 'cloud_0',
        at: DateTime(2026, 11, 21, 15, 0),
        avgHz: 188.0,
        minHz: 175.0,
        maxHz: 200.0,
        category: VoicePitchCategory.neutral,
      );
      final remoteItem = VoiceTestResult(
        id: 'cloud_1',
        at: DateTime(2026, 11, 22, 16, 0),
        avgHz: 204.2,
        minHz: 190.0,
        maxHz: 220.0,
        category: VoicePitchCategory.softHigh,
      );
      fakeRepo.emit([remoteItem, olderRemote]);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Voice Pitch Studio'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Voice Pitch Studio'), findsOneWidget);

      // Open VoicePitchPage under the same ProviderScope with synthetic PCM stream.
      late StreamController<Uint8List> pcmController;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repoProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: VoicePitchPage(
              streamBuilder: () {
                pcmController = StreamController<Uint8List>();
                return pcmController.stream;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      fakeRepo.emit([remoteItem, olderRemote]);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Progress trend'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Progress trend'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('204 Hz'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('204 Hz'), findsOneWidget);

      // Scroll back up to live check, record, and save -> uploaded to Repo.
      await tester.scrollUntilVisible(
        find.text('Start live voice check'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Start live voice check'));
      await tester.pump();
      pcmController
          .add(synthesizePcm16Sine(frequencyHz: 230.0, durationMs: 120));
      await tester.pump();
      await pcmController.close();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save result (numbers only)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save result (numbers only)'));
      await tester.pumpAndSettle();

      expect(fakeRepo.saved.length, equals(1));
      expect(fakeRepo.saved.first.category, equals(VoicePitchCategory.bright));

      // Delete one item via delete icon -> calls Repo.deleteVoiceResult.
      await tester.scrollUntilVisible(
        find.byTooltip('Delete').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();
      expect(fakeRepo.deletedIds.length, equals(1));

      // Clear remaining -> propagates knownIds to Repo.clearVoiceResults.
      await tester.scrollUntilVisible(
        find.text('Clear all'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(fakeRepo.clearedCount, equals(1));
      expect(fakeRepo.lastClearedIds, isNotEmpty);
    });
  });
}

class _FakeVoiceRepo extends Repo {
  _FakeVoiceRepo() : super('fake_uid');

  final _controller = StreamController<List<VoiceTestResult>>.broadcast();
  final List<VoiceTestResult> saved = [];
  final List<String> deletedIds = [];
  int clearedCount = 0;
  List<String> lastClearedIds = const [];

  void emit(List<VoiceTestResult> items) {
    if (!_controller.isClosed) _controller.add(items);
  }

  @override
  Stream<List<VoiceTestResult>> voiceResults() => _controller.stream;

  @override
  Future<void> saveVoiceResult(VoiceTestResult r) async {
    saved.add(r);
  }

  @override
  Future<void> deleteVoiceResult(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> clearVoiceResults({Iterable<String> knownIds = const []}) async {
    clearedCount++;
    lastClearedIds = knownIds.toList();
  }

  Future<void> dispose() => _controller.close();
}
