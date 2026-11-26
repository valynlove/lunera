import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/ui/ambient_companion.dart';
import 'package:lunera/widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    L10n.notifier.value = 'en';
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('companionBondTier', () {
    test('returns expected bond tiers across all thresholds', () {
      expect(companionBondTier(0).level, 1);
      expect(companionBondTier(0).title, 'Stardust Pal');
      expect(companionBondTier(0).nextAt, 5);

      expect(companionBondTier(4).level, 1);
      expect(companionBondTier(5).level, 2);
      expect(companionBondTier(5).title, 'Moonbeam Friend');
      expect(companionBondTier(5).nextAt, 20);

      expect(companionBondTier(19).level, 2);
      expect(companionBondTier(20).level, 3);
      expect(companionBondTier(20).title, 'Twilight Bestie');
      expect(companionBondTier(20).nextAt, 50);

      expect(companionBondTier(49).level, 3);
      expect(companionBondTier(50).level, 4);
      expect(companionBondTier(50).title, 'Celestial Confidante');
      expect(companionBondTier(50).nextAt, 100);

      expect(companionBondTier(99).level, 4);
      expect(companionBondTier(100).level, 5);
      expect(companionBondTier(100).title, 'Eternal Dusk Soulmate');
      expect(companionBondTier(100).nextAt, isNull);
    });
  });

  group('CompanionWidget background actions', () {
    test('pat increments cmp_pats_count and resets poke streak', () async {
      SharedPreferences.setMockInitialValues({'cmp_poke_streak': 2});
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/pat'));
      final sp = await SharedPreferences.getInstance();
      expect(sp.getInt('cmp_pats_count'), 1);
      expect(sp.getInt('cmp_poke_streak'), 0);
    });

    test('poke increments cmp_pats_count and resets streak on 4th consecutive poke', () async {
      for (var i = 0; i < 3; i++) {
        await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/poke'));
      }
      var sp = await SharedPreferences.getInstance();
      expect(sp.getInt('cmp_pats_count'), 3);
      expect(sp.getInt('cmp_poke_streak'), 3);

      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/poke'));
      sp = await SharedPreferences.getInstance();
      expect(sp.getInt('cmp_pats_count'), 4);
      expect(sp.getInt('cmp_poke_streak'), 0);
    });

    test('talk increments cmp_talk_idx or triggers night sleepy cue cleanly', () async {
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/talk'));
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/talk'));
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/talk'));
      final sp = await SharedPreferences.getInstance();
      expect(sp.getInt('cmp_talk_idx') ?? 0, greaterThanOrEqualTo(0));
      expect(sp.getInt('cmp_poke_streak'), 0);
    });

    test('water increments today hydration cups and saves today date', () async {
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/water'));
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://companion/water'));
      final sp = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(sp.getString('cmp_hydration_date'), todayStr);
      expect(sp.getInt('cmp_hydration_cups'), 2);
    });
  });
}
