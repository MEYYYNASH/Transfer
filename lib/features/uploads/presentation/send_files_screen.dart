import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/models/transfer_models.dart';

class SendFilesScreen extends ConsumerStatefulWidget {
  const SendFilesScreen({super.key});

  @override
  ConsumerState<SendFilesScreen> createState() => _SendFilesScreenState();
}

class _SendFilesScreenState extends ConsumerState<SendFilesScreen> {
  final List<File> _selectedFiles = [];
  final TextEditingController _targetIpController = TextEditingController(text: '192.168.1.');
  final TextEditingController _targetPortController = TextEditingController(text: '8888');
  bool _isSending = false;
  String? _statusMessage;

  int get _totalSize => _selectedFiles.fold(0, (sum, file) {
        try {
          return sum + file.lengthSync();
        } catch (_) {
          return sum;
        }
      });

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        for (final path in result.paths) {
          if (path != null) {
            final f = File(path);
            if (!_selectedFiles.any((existing) => existing.path == f.path)) {
              _selectedFiles.add(f);
            }
          }
        }
      });
    }
  }

  Future<void> _startLocalSend() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select files first.')),
      );
      return;
    }

    final targetIp = _targetIpController.text.trim();
    final targetPort = int.tryParse(_targetPortController.text.trim()) ?? 8888;

    if (targetIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target IP address.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Connecting to $targetIp:$targetPort...';
    });

    final networkService = ref.read(localNetworkServiceProvider);
    final queueNotifier = ref.read(transferQueueProvider.notifier);

    final transferId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    await networkService.sendFiles(
      targetIp: targetIp,
      targetPort: targetPort,
      files: _selectedFiles,
      transferId: transferId,
      onProgress: (progress) {
        queueNotifier.updateRecord(progress);
        setState(() {
          _statusMessage = '${progress.status.name.toUpperCase()}: ${progress.progressPercentage.toStringAsFixed(0)}%';
        });
      },
    );

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocale(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('sendFiles')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target IP and Port config
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receiver Destination (Wi-Fi / LAN)',
                    style: TextStyle(
                      color: AppColors.mainText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _targetIpController,
                          decoration: const InputDecoration(
                            labelText: 'Receiver IP Address',
                            prefixIcon: Icon(Icons.wifi, color: AppColors.secondaryAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _targetPortController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // File selection action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Files (${_selectedFiles.length})',
                  style: const TextStyle(
                    color: AppColors.mainText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _pickFiles,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.translate('selectFiles')),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_selectedFiles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: AppColors.secondaryText),
                    SizedBox(height: 8),
                    Text(
                      'No files selected yet. Tap above to pick.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  final sizeMB = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file, color: AppColors.primaryAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.basename(file.path),
                                style: const TextStyle(
                                  color: AppColors.mainText,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$sizeMB MB',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                          onPressed: _isSending
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Submit Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _startLocalSend,
                icon: const Icon(Icons.wifi_tethering),
                label: Text(
                  _isSending ? 'Sending...' : 'Send via Local Wi-Fi (${(_totalSize / (1024 * 1024)).toStringAsFixed(1)} MB)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
