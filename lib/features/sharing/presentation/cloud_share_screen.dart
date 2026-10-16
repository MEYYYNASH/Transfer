import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hash_util.dart';
import '../../../shared/providers/app_providers.dart';

class CloudShareScreen extends ConsumerStatefulWidget {
  const CloudShareScreen({super.key});

  @override
  ConsumerState<CloudShareScreen> createState() => _CloudShareScreenState();
}

class _CloudShareScreenState extends ConsumerState<CloudShareScreen> {
  File? _selectedFile;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _maxDownloadsController = TextEditingController(text: '20');
  int _expiryHours = 48;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _generatedShareUrl;
  String? _shareToken;
  String? _errorMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _generatedShareUrl = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _startCloudUpload() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final cloudService = ref.read(cloudTransferServiceProvider);
      final fileName = p.basename(_selectedFile!.path);
      final fileSize = await _selectedFile!.length();
      final sha256 = await HashUtil.calculateFileSha256(_selectedFile!);

      final maxDownloads = int.tryParse(_maxDownloadsController.text.trim()) ?? 20;
      final password = _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null;

      // 1. Create upload session via backend
      final session = await cloudService.createUploadSession(
        fileName: fileName,
        fileSizeBytes: fileSize,
        sha256Checksum: sha256,
        password: password,
        maxDownloads: maxDownloads,
        expiryHours: _expiryHours,
      );

      final uploadUrl = session['upload_url'] as String;
      final shareToken = session['share_token'] as String;
      final shareUrl = session['share_url'] as String;

      // 2. Stream chunked upload
      await cloudService.uploadFileWithProgress(
        file: _selectedFile!,
        uploadUrl: uploadUrl,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = (sent / total).clamp(0.0, 1.0);
          });
        },
      );

      setState(() {
        _generatedShareUrl = shareUrl;
        _shareToken = shareToken;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
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
        title: Text(l10n.translate('cloudUpload')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected File Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_upload, color: AppColors.primaryAccent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile != null
                                  ? p.basename(_selectedFile!.path)
                                  : 'No file selected for Cloud Upload',
                              style: const TextStyle(
                                color: AppColors.mainText,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFile != null
                                  ? '${(_selectedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB'
                                  : 'Upload files up to 10 GB with presigned S3 URLs',
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile != null ? 'Change File' : 'Browse File'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share Options
            const Text(
              'Security & Expiration Settings',
              style: TextStyle(
                color: AppColors.mainText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Optional Password Protection',
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryAccent),
                      hintText: 'Leave empty for direct link access',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _maxDownloadsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Downloads',
                            prefixIcon: Icon(Icons.file_download_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _expiryHours,
                          decoration: const InputDecoration(
                            labelText: 'Link Expiry',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          dropdownColor: AppColors.elevatedSurface,
                          items: const [
                            DropdownMenuItem(value: 12, child: Text('12 Hours')),
                            DropdownMenuItem(value: 24, child: Text('24 Hours')),
                            DropdownMenuItem(value: 48, child: Text('48 Hours')),
                            DropdownMenuItem(value: 168, child: Text('7 Days')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _expiryHours = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.elevatedSurface,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryAccent),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Uploading to Cloud... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_generatedShareUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          'Share Link Ready!',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _generatedShareUrl!,
                          version: QrVersions.auto,
                          size: 160,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _generatedShareUrl!,
                              style: const TextStyle(color: AppColors.mainText, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppColors.primaryAccent, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _generatedShareUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Share Link copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_selectedFile == null || _isUploading) ? null : _startCloudUpload,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Generate Secure Cloud Share Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
