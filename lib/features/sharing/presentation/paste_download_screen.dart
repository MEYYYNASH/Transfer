import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hash_util.dart';
import '../../../core/utils/path_sanitizer.dart';
import '../../../shared/providers/app_providers.dart';

class PasteDownloadScreen extends ConsumerStatefulWidget {
  const PasteDownloadScreen({super.key});

  @override
  ConsumerState<PasteDownloadScreen> createState() => _PasteDownloadScreenState();
}

class _PasteDownloadScreenState extends ConsumerState<PasteDownloadScreen> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoadingMetadata = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Map<String, dynamic>? _metadata;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _fetchMetadata() async {
    final rawInput = _linkController.text.trim();
    if (rawInput.isEmpty) return;

    // Extract token if full URL was pasted
    var token = rawInput;
    if (rawInput.contains('/')) {
      token = rawInput.split('/').last;
    }

    setState(() {
      _isLoadingMetadata = true;
      _errorMessage = null;
      _metadata = null;
    });

    try {
      final cloudService = ref.read(cloudTransferServiceProvider);
      final meta = await cloudService.fetchShareMetadata(token);
      setState(() {
        _metadata = meta;
        _isLoadingMetadata = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    if (_metadata == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final cloudService = ref.read(cloudTransferServiceProvider);
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadDir = '${docsDir.path}${Platform.pathSeparator}LinkoraDownloads';
      final dir = Directory(downloadDir);
      if (!await dir.exists()) await dir.create(recursive: true);

      final safePath = PathSanitizer.resolveSafePath(
        downloadDir,
        _metadata!['file_name'] as String,
      );

      final downloadUrl = _metadata!['download_url'] as String;

      await cloudService.downloadFileWithProgress(
        downloadUrl: downloadUrl,
        targetPath: safePath,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress = (received / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      // Verify SHA-256
      final expectedSha = _metadata!['sha256_checksum'] as String?;
      if (expectedSha != null && expectedSha.isNotEmpty) {
        final actualSha = await HashUtil.calculateFileSha256(File(safePath));
        if (!HashUtil.verifyHash(expectedSha, actualSha)) {
          throw Exception('Downloaded file integrity failed: SHA-256 mismatch!');
        }
      }

      setState(() {
        _isDownloading = false;
        _successMessage = 'File successfully downloaded and verified to: $safePath';
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocale(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('pasteToDownload')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Link input card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      labelText: 'Share URL or Token',
                      hintText: 'https://linkora.app/s/abc123xyz',
                      prefixIcon: const Icon(Icons.link, color: AppColors.secondaryAccent),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: AppColors.primaryAccent),
                        onPressed: _isLoadingMetadata ? null : _fetchMetadata,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingMetadata ? null : _fetchMetadata,
                      child: Text(_isLoadingMetadata ? 'Inspecting Link...' : 'Inspect & Preview'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
              ),

            if (_metadata != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Safe File Metadata',
                          style: TextStyle(
                            color: AppColors.mainText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMetaRow('File Name', _metadata!['file_name'] ?? 'Unknown'),
                    _buildMetaRow(
                      'Size',
                      '${((_metadata!['file_size_bytes'] ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB',
                    ),
                    _buildMetaRow('Downloads Allowed', '${_metadata!['remaining_downloads'] ?? 'Unlimited'} left'),
                    _buildMetaRow(
                      'SHA-256',
                      _metadata!['sha256_checksum'] != null
                          ? '${(_metadata!['sha256_checksum'] as String).substring(0, 16)}...'
                          : 'Not provided',
                    ),
                    if (_metadata!['requires_password'] == true) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password Required',
                          prefixIcon: Icon(Icons.lock, color: AppColors.warning),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    if (_isDownloading) ...[
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: AppColors.elevatedSurface,
                        valueColor: const AlwaysStoppedAnimation(AppColors.secondaryAccent),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Downloading & Verifying... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _downloadFile,
                          icon: const Icon(Icons.download),
                          label: Text(l10n.translate('downloadNow')),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _successMessage!,
                      style: const TextStyle(color: AppColors.mainText, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText)),
          Text(value, style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
