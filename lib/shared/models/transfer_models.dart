enum TransferStatus {
  idle,
  queued,
  preparing,
  connecting,
  running,
  paused,
  verifying,
  completed,
  cancelled,
  failed,
}

enum TransferDirection {
  outgoing,
  incoming,
}

enum TransferTransport {
  localNetwork,
  bluetooth,
  cloud,
}

class TransferItemModel {
  final String id;
  final String transferId;
  final String displayName;
  final int expectedSize;
  final String? savedPath;
  final String? expectedSha256;
  final String? actualSha256;
  final String verificationStatus; // 'pending', 'verified', 'mismatched'

  const TransferItemModel({
    required this.id,
    required this.transferId,
    required this.displayName,
    required this.expectedSize,
    this.savedPath,
    this.expectedSha256,
    this.actualSha256,
    this.verificationStatus = 'pending',
  });

  TransferItemModel copyWith({
    String? id,
    String? transferId,
    String? displayName,
    int? expectedSize,
    String? savedPath,
    String? expectedSha256,
    String? actualSha256,
    String? verificationStatus,
  }) {
    return TransferItemModel(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      displayName: displayName ?? this.displayName,
      expectedSize: expectedSize ?? this.expectedSize,
      savedPath: savedPath ?? this.savedPath,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
      actualSha256: actualSha256 ?? this.actualSha256,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

class TransferRecordModel {
  final String id;
  final TransferDirection direction;
  final TransferTransport transport;
  final TransferStatus status;
  final int totalBytes;
  final int transferredBytes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorCode;
  final String? peerName;
  final List<TransferItemModel> items;

  const TransferRecordModel({
    required this.id,
    required this.direction,
    required this.transport,
    required this.status,
    required this.totalBytes,
    this.transferredBytes = 0,
    required this.createdAt,
    this.completedAt,
    this.errorCode,
    this.peerName,
    this.items = const [],
  });

  double get progressPercentage {
    if (totalBytes <= 0) return 0.0;
    final p = (transferredBytes / totalBytes) * 100.0;
    return p.clamp(0.0, 100.0);
  }

  TransferRecordModel copyWith({
    String? id,
    TransferDirection? direction,
    TransferTransport? transport,
    TransferStatus? status,
    int? totalBytes,
    int? transferredBytes,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorCode,
    String? peerName,
    List<TransferItemModel>? items,
  }) {
    return TransferRecordModel(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      transport: transport ?? this.transport,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorCode: errorCode ?? this.errorCode,
      peerName: peerName ?? this.peerName,
      items: items ?? this.items,
    );
  }
}
