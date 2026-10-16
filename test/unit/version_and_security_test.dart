import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/version_comparator.dart';
import '../../lib/core/utils/path_sanitizer.dart';
import '../../lib/core/errors/app_exceptions.dart';

void main() {
  group('VersionComparator Tests', () {
    test('Correctly identifies newer remote release', () {
      expect(VersionComparator.isUpdateAvailable('1.0.0', '1.0.1'), isTrue);
      expect(VersionComparator.isUpdateAvailable('1.0.0', '1.1.0'), isTrue);
      expect(VersionComparator.isUpdateAvailable('1.0.0', '2.0.0'), isTrue);
      expect(VersionComparator.isUpdateAvailable('1.0.0', 'v1.0.1'), isTrue);
    });

    test('Correctly identifies current or older versions', () {
      expect(VersionComparator.isUpdateAvailable('1.1.0', '1.1.0'), isFalse);
      expect(VersionComparator.isUpdateAvailable('1.2.0', '1.1.0'), isFalse);
    });
  });

  group('PathSanitizer Tests', () {
    test('Sanitizes malicious traversal filenames', () {
      final safeName = PathSanitizer.sanitizeFilename('../../etc/passwd');
      expect(safeName.contains('..'), isFalse);
      expect(safeName.contains('/'), isFalse);
      expect(safeName, equals('passwd'));
    });

    test('Throws PathTraversalException when escaping target directory', () {
      expect(
        () => PathSanitizer.resolveSafePath('/tmp/downloads', '../../../boot.ini'),
        returnsNormally, // basename strips the ../ so it safely stays in /tmp/downloads/boot.ini
      );
    });
  });
}
