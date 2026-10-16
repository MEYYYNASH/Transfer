class LinkoraException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const LinkoraException(this.message, {this.code, this.details});

  @override
  String toString() => 'LinkoraException[$code]: $message';
}

class NetworkTransferException extends LinkoraException {
  const NetworkTransferException(super.message, {super.code, super.details});
}

class VerificationFailedException extends LinkoraException {
  final String expectedSha256;
  final String actualSha256;

  const VerificationFailedException({
    required this.expectedSha256,
    required this.actualSha256,
  }) : super(
          'Integrity verification failed. Expected: $expectedSha256, got: $actualSha256',
          code: 'HASH_MISMATCH',
        );
}

class PathTraversalException extends LinkoraException {
  const PathTraversalException(String rawPath)
      : super(
          'Security alert: Attempted path traversal with filename: $rawPath',
          code: 'PATH_TRAVERSAL_DETECTED',
        );
}

class CloudShareException extends LinkoraException {
  final int? statusCode;
  const CloudShareException(super.message, {this.statusCode, super.code});
}

class UpdateVerificationException extends LinkoraException {
  const UpdateVerificationException(super.message, {super.code});
}

class BluetoothUnsupportedException extends LinkoraException {
  const BluetoothUnsupportedException(super.message)
      : super(code: 'BLUETOOTH_UNSUPPORTED');
}
