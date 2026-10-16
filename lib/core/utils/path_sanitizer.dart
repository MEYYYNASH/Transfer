import 'package:path/path.dart' as p;
import '../errors/app_exceptions.dart';

class PathSanitizer {
  PathSanitizer._();

  static final RegExp _illegalChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// Sanitizes untrusted incoming filenames and guarantees they cannot escape target directory
  static String sanitizeFilename(String filename) {
    var clean = filename.trim();

    // Check for directory traversal attempts
    if (clean.contains('..') || clean.contains('/') || clean.contains('\\')) {
      clean = p.basename(clean);
    }

    // Strip illegal characters
    clean = clean.replaceAll(_illegalChars, '_');

    // Ensure not empty
    if (clean.isEmpty || clean == '.' || clean == '..') {
      clean = 'unnamed_file_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Limit length
    if (clean.length > 255) {
      final ext = p.extension(clean);
      clean = '${clean.substring(0, 240)}$ext';
    }

    return clean;
  }

  /// Resolves the file destination within a base directory and verifies it doesn't escape
  static String resolveSafePath(String baseDir, String untrustedFilename) {
    final safeName = sanitizeFilename(untrustedFilename);
    final canonicalBase = p.canonicalize(baseDir);
    final targetPath = p.canonicalize(p.join(canonicalBase, safeName));

    if (!targetPath.startsWith(canonicalBase)) {
      throw PathTraversalException(untrustedFilename);
    }

    return targetPath;
  }
}
