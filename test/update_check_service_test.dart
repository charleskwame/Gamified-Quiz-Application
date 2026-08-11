import 'package:flutter_test/flutter_test.dart';
import 'package:gamified_quiz_app/services/update_check_service.dart';

void main() {
  group('normalizeVersion', () {
    test('strips a leading v', () {
      expect(normalizeVersion('v1.2.0'), '1.2.0');
    });

    test('strips a build suffix', () {
      expect(normalizeVersion('1.1.0+3'), '1.1.0');
    });

    test('strips a leading v and build suffix', () {
      expect(normalizeVersion('v1.2.0+45'), '1.2.0');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeVersion(' 1.2.0 '), '1.2.0');
    });
  });

  group('compareVersions', () {
    test('equal versions compare to zero', () {
      expect(compareVersions('1.2.0', '1.2.0'), 0);
    });

    test('lower patch version is smaller', () {
      expect(compareVersions('1.2.0', '1.2.1'), lessThan(0));
    });

    test('higher patch version is larger', () {
      expect(compareVersions('1.2.1', '1.2.0'), greaterThan(0));
    });

    test('lower minor version is smaller', () {
      expect(compareVersions('1.1.0', '1.2.0'), lessThan(0));
    });

    test('higher major version is larger', () {
      expect(compareVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('different segment counts compare correctly', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2', '1.3.0'), lessThan(0));
    });

    test('non-numeric segments are treated as zero', () {
      expect(compareVersions('1.2.x', '1.2.0'), 0);
    });

    test('pre-release suffix compares by its core version', () {
      expect(compareVersions('1.2.0-rc1', '1.2.0'), 0);
    });
  });
}
