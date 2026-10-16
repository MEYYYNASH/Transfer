import 'dart:async';
import 'dart:io';
import '../../../shared/models/transfer_models.dart';

abstract class LocalNetworkTransport {
  Future<void> startListening({
    required int port,
    required Future<bool> Function(String peerIp, String fileName, int fileSize) onIncomingPrompt,
    required void Function(TransferRecordModel record) onProgress,
  });

  Future<void> stopListening();

  Future<void> sendFiles({
    required String targetIp,
    required int targetPort,
    required List<File> files,
    required String transferId,
    required void Function(TransferRecordModel progress) onProgress,
  });
}

abstract class BluetoothTransport {
  Future<bool> isSupported();
  Future<bool> isEnabled();
  Future<List<String>> discoverDevices();
  Future<void> sendFile({
    required String deviceAddress,
    required File file,
    required void Function(TransferRecordModel progress) onProgress,
  });
}

abstract class CloudTransferTransport {
  Future<Map<String, dynamic>> createUploadSession({
    required String fileName,
    required int fileSizeBytes,
    required String sha256Checksum,
    String? password,
    int? maxDownloads,
    int? expiryHours,
  });

  Future<void> uploadFileWithProgress({
    required File file,
    required String uploadUrl,
    required void Function(int sentBytes, int totalBytes) onProgress,
  });

  Future<Map<String, dynamic>> fetchShareMetadata(String shareToken);

  Future<void> downloadFileWithProgress({
    required String downloadUrl,
    required String targetPath,
    required void Function(int receivedBytes, int totalBytes) onProgress,
  });
}
