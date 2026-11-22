import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lunera/guides_data.dart';
import 'package:lunera/l10n.dart';
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
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('On-device voice pitch detection & categories', () {
    test('detects low, neutral, and high sine frequencies accurately', () {
      final lowPcm = synthesizePcm16Sine(frequencyHz: 120.0, durationMs: 80);
      final lowHz = detectPitchFromPcm16(lowPcm);
      expect(lowHz, isNotNull);
      expect(lowHz!, closeTo(120.0, 4.0));
      expect(categorizePitchHz(lowHz), equals(VoicePitchCategory.low));

      final midPcm = synthesizePcm16Sine(frequencyHz: 170.0, durationMs: 80);
      final midHz = detectPitchFromPcm16(midPcm);
      expect(midHz, isNotNull);
      expect(midHz!, closeTo(170.0, 4.0));
      expect(categorizePitchHz(midHz), equals(VoicePitchCategory.neutral));

      final highPcm = synthesizePcm16Sine(frequencyHz: 220.0, durationMs: 80);
      final highHz = detectPitchFromPcm16(highPcm);
      expect(highHz, isNotNull);
      expect(highHz!, closeTo(220.0, 5.0));
      expect(categorizePitchHz(highHz), equals(VoicePitchCategory.high));
    });

    test('returns null on silence', () {
      final silent =
          synthesizePcm16Sine(frequencyHz: 180.0, durationMs: 80, amplitude: 0);
      expect(detectPitchFromPcm16(silent), isNull);
    });
  });

  group('VoiceStore unlock & numeric-only results', () {
    test('starts locked and persists unlock, save, delete, and clear',
        () async {
      expect(await VoiceStore.isUnlocked(), isFalse);
      await VoiceStore.setUnlocked(true);
      expect(await VoiceStore.isUnlocked(), isTrue);

      final item = VoiceTestResult(
        id: 'r1',
        at: DateTime(2026, 11, 22, 19, 30),
        avgHz: 196.4,
        minHz: 184.0,
        maxHz: 212.0,
        category: VoicePitchCategory.high,
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
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start live voice check'));
      await tester.pump();

      controller.add(synthesizePcm16Sine(frequencyHz: 210.0, durationMs: 120));
      await tester.pump();
      await controller.close();
      await tester.pumpAndSettle();

      expect(find.text('Save result (numbers only)'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save result (numbers only)'));
      await tester.pumpAndSettle();

      expect(find.text('Result saved (numbers only)'), findsOneWidget);
      final saved = await VoiceStore.loadResults();
      expect(saved.length, equals(1));
      expect(saved.first.category, equals(VoicePitchCategory.high));
    });
  });
}
