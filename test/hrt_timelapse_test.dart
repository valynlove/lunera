import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/sanctuary/hrt_timelapse_page.dart';

void main() {
  setUp(() {
    L10n.notifier.value = 'en';
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  test('all 11 HRT Time-Lapse PNG assets exist and have valid PNG signatures',
      () {
    const expectedFiles = <String>[
      'assets/images/timelapse/portal_frame.png',
      'assets/images/timelapse/mtf_stage_0.png',
      'assets/images/timelapse/mtf_stage_1.png',
      'assets/images/timelapse/mtf_stage_2.png',
      'assets/images/timelapse/mtf_stage_3.png',
      'assets/images/timelapse/mtf_stage_4.png',
      'assets/images/timelapse/ftm_stage_0.png',
      'assets/images/timelapse/ftm_stage_1.png',
      'assets/images/timelapse/ftm_stage_2.png',
      'assets/images/timelapse/ftm_stage_3.png',
      'assets/images/timelapse/ftm_stage_4.png',
    ];
    const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

    for (final path in expectedFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing asset: $path');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(1024),
          reason: 'Asset too small: $path');
      expect(bytes.sublist(0, 8), equals(pngSignature),
          reason: 'Invalid PNG signature: $path');
    }
  });

  testWidgets(
      'HrtTimelapsePage scrubs across all 5 MtF stages and switches to FtM',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const HrtTimelapsePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HRT Time-Lapse'), findsOneWidget);
    expect(find.text('Feminizing (MtF)'), findsOneWidget);
    expect(find.text('Masculinizing (FtM)'), findsOneWidget);
    expect(find.text('Baseline'), findsOneWidget);

    const mtfSteps = <(String, String)>[
      ('1–3 Mo', 'Early Spark'),
      ('3–6 Mo', 'Softening Contours'),
      ('6–12 Mo', 'Deepening Bloom'),
      ('12–24+ Mo', 'Steady Horizon'),
    ];
    for (final (label, title) in mtfSteps) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.text('Masculinizing (FtM)'));
    await tester.pumpAndSettle();
    expect(find.text('Grounded Horizon'), findsOneWidget);

    const ftmSteps = <(String, String)>[
      ('Day 1', 'Baseline'),
      ('1–3 Mo', 'First Shift'),
      ('3–6 Mo', 'Emerging Definition'),
      ('6–12 Mo', 'Steady Strength'),
    ];
    for (final (label, title) in ftmSteps) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });
}
