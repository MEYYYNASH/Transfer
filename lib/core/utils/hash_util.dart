import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashUtil {
  HashUtil._();

  /// Computes SHA-256 hash for a given file via stream without loading all into memory
  static Future<String> calculateFileSha256(File file) async {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    final stream = file.openRead();
    await for (final chunk in stream) {
      input.add(chunk);
    }
    input.close();

    return output.events.single.toString();
  }

  /// Computes SHA-256 hash from in-memory bytes
  static String calculateBytesSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Secure constant-time string comparison to mitigate timing attacks
  static bool verifyHash(String expected, String actual) {
    final exp = expected.toLowerCase().trim();
    final act = actual.toLowerCase().trim();
    if (exp.length != act.length) return false;

    var result = 0;
    for (var i = 0; i < exp.length; i++) {
      result |= exp.codeUnitAt(i) ^ act.codeUnitAt(i);
    }
    return result == 0;
  }
}
