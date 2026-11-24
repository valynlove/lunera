import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunera/moments.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/ui/moments_page.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('Moment Model & Serialization Tests', () {
    test('round-trip serialization toMap and fromMap preserves fields', () {
      final now = DateTime(2026, 11, 24, 10, 0);
      final moment = Moment(
        id: 'm1',
        at: now,
        title: 'Six Months on Estradiol!',
        note: 'Feeling peaceful and aligned with myself.',
        photoBase64: 'fake_base64_data',
        category: 'milestone',
      );

      final map = moment.toMap();
      final restored = Moment.fromMap(map);

      expect(restored.id, 'm1');
      expect(restored.title, 'Six Months on Estradiol!');
      expect(restored.note, 'Feeling peaceful and aligned with myself.');
      expect(restored.photoBase64, 'fake_base64_data');
      expect(restored.category, 'milestone');
      expect(restored.hasPhoto, isTrue);
      expect(restored.hasNote, isTrue);
    });

    test('categoryOfMoment fallback defaults to first category', () {
      final cat = categoryOfMoment('unknown_category');
      expect(cat.id, 'milestone');
    });
  });

  group('MomentsPage Widget Tests', () {
    testWidgets('renders empty state and allows opening new moment editor',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value(const [])),
            logsProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(
            home: MomentsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lunera Moments'), findsOneWidget);
      expect(find.text('No visual moments yet'), findsOneWidget);
      expect(find.text('Create First Moment'), findsOneWidget);

      // Tap Create First Moment button: opens editor sheet
      await tester.tap(find.text('Create First Moment'));
      await tester.pumpAndSettle();

      expect(find.text('Add Visual Moment'), findsOneWidget);
      expect(find.text('Moment Title'), findsOneWidget);
      expect(find.text('Save Moment'), findsOneWidget);
    });

    testWidgets('renders existing moments in list with category badge',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final existingMoment = Moment(
        id: 'm_test',
        at: now,
        title: 'First Affirming Haircut',
        note: 'Loved the new texture!',
        category: 'style',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userProvider.overrideWith((ref) => Stream.value(null)),
          therapiesProvider.overrideWith((ref) => Stream.value(const [])),
          logsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      container.read(momentsProvider.notifier).addMoment(existingMoment);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MomentsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('First Affirming Haircut'), findsOneWidget);
      expect(find.text('Loved the new texture!'), findsOneWidget);
      expect(find.text('Affirming Style & Self'), findsWidgets);
    });
  });
}
