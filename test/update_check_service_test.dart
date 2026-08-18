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

  group('isImplementationCommit', () {
    test('keeps feature commits', () {
      expect(isImplementationCommit('feat: add quiz sound effects'), isTrue);
    });

    test('keeps fix and refactor commits', () {
      expect(isImplementationCommit('fix: crash on startup'), isTrue);
      expect(isImplementationCommit('refactor: clean up auth flow'), isTrue);
    });

    test('filters out version bump commits', () {
      expect(
        isImplementationCommit('chore: bump version to 1.2.7+10207'),
        isFalse,
      );
      expect(isImplementationCommit('Bump version to 1.2.7'), isFalse);
      expect(isImplementationCommit('chore(release): 1.2.7'), isFalse);
    });

    test('filters out merge commits', () {
      expect(isImplementationCommit('Merge branch main'), isFalse);
      expect(
        isImplementationCommit('Merge pull request #42 from feature/x'),
        isFalse,
      );
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
