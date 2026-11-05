import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/ui/app_changelog.dart';
import 'package:lunera/update_checker.dart';

void main() {
  group('Lunera App Metadata & Smoke Tests', () {
    test('UpdateCheckerService version check configuration', () {
      expect(UpdateCheckerService.currentVersion, equals('1.11.13'));
    });

    test('AppChangelog releases metadata is populated and ordered', () {
      expect(AppChangelog.releases, isNotEmpty);
      expect(AppChangelog.releases.first.version, equals('1.11.13'));
      expect(AppChangelog.releases.first.isCurrent, isTrue);
      expect(AppChangelog.releases.first.changes, isNotEmpty);
    });
  });
}
