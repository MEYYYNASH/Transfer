import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/errors/app_exceptions.dart';
import '../../features/local_transfer/domain/transport_interfaces.dart';

class CloudTransferService implements CloudTransferTransport {
  final Dio _dio;
  final String baseUrl;

  CloudTransferService({required this.baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  @override
  Future<Map<String, dynamic>> createUploadSession({
    required String fileName,
    required int fileSizeBytes,
    required String sha256Checksum,
    String? password,
    int? maxDownloads,
    int? expiryHours,
  }) async {
    try {
      final response = await _dio.post('/api/v1/uploads', data: {
        'file_name': fileName,
        'file_size_bytes': fileSizeBytes,
        'sha256_checksum': sha256Checksum,
        'password': password,
        'max_downloads': maxDownloads,
        'expiry_hours': expiryHours ?? 48,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw CloudShareException(
        e.response?.data?['detail'] ?? e.message ?? 'Failed to create upload session',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> uploadFileWithProgress({
    required File file,
    required String uploadUrl,
    required void Function(int sentBytes, int totalBytes) onProgress,
  }) async {
    try {
      final fileLength = await file.length();
      final stream = file.openRead();

      // Put directly to S3/R2 presigned URL
      final response = await _dio.put(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileLength,
            'Content-Type': 'application/octet-stream',
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw CloudShareException('Upload to storage failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw CloudShareException('Upload failed: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchShareMetadata(String shareToken) async {
    try {
      final response = await _dio.get('/api/v1/shares/$shareToken');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw CloudShareException(
        e.response?.data?['detail'] ?? 'Share link not found or expired',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> downloadFileWithProgress({
    required String downloadUrl,
    required String targetPath,
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    try {
      await _dio.download(
        downloadUrl,
        targetPath,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      throw CloudShareException('Download failed: ${e.message}');
    }
  }
}
