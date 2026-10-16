import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';

class ReceiveFilesScreen extends ConsumerStatefulWidget {
  const ReceiveFilesScreen({super.key});

  @override
  ConsumerState<ReceiveFilesScreen> createState() => _ReceiveFilesScreenState();
}

class _ReceiveFilesScreenState extends ConsumerState<ReceiveFilesScreen> {
  String _localIp = '127.0.0.1';
  final int _port = 8888;
  bool _isListening = false;
  String _saveDir = '';

  @override
  void initState() {
    super.initState();
    _initNetworkAndListener();
  }

  Future<void> _initNetworkAndListener() async {
    try {
      final info = NetworkInfo();
      final wifiIp = await info.getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty) {
        _localIp = wifiIp;
      } else {
        // Fallback to checking local network interfaces
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        );
        if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
          _localIp = interfaces.first.addresses.first.address;
        }
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final targetSaveDir = '${docsDir.path}${Platform.pathSeparator}LinkoraDownloads';
      final dir = Directory(targetSaveDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _saveDir = targetSaveDir;

      setState(() {});

      // Auto start listener
      await _startListener();
    } catch (_) {}
  }

  Future<void> _startListener() async {
    final networkService = ref.read(localNetworkServiceProvider);
    final queueNotifier = ref.read(transferQueueProvider.notifier);

    networkService.setSaveDirectory(_saveDir);

    await networkService.startListening(
      port: _port,
      onIncomingPrompt: (peerIp, fileName, fileSize) async {
        return await _showIncomingDialog(peerIp, fileName, fileSize);
      },
      onProgress: (record) {
        queueNotifier.updateRecord(record);
      },
    );

    setState(() {
      _isListening = true;
    });
  }

  Future<bool> _showIncomingDialog(String peerIp, String fileName, int fileSize) async {
    final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryAccent),
        ),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.secondaryAccent),
            SizedBox(width: 10),
            Text('Incoming Transfer Request', style: TextStyle(color: AppColors.mainText)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sender: $peerIp', style: const TextStyle(color: AppColors.secondaryText)),
            const SizedBox(height: 8),
            Text('File: $fileName', style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Size: $sizeMB MB', style: const TextStyle(color: AppColors.secondaryText)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept & Receive'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocale(locale);

    final pairingJson = jsonEncode({
      'ip': _localIp,
      'port': _port,
      'protocol': 'linkora-v1',
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('receiveFiles')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR Code Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: pairingJson,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Pairing Metadata
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Local IP Address', style: TextStyle(color: AppColors.secondaryText)),
                      Text(
                        _localIp,
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TCP Listening Port', style: TextStyle(color: AppColors.secondaryText)),
                      Text(
                        '$_port',
                        style: const TextStyle(
                          color: AppColors.mainText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(color: AppColors.secondaryText)),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isListening ? AppColors.success : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isListening ? 'Listening for Transfers' : 'Stopped',
                            style: TextStyle(
                              color: _isListening ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Download Path info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Save Directory:', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _saveDir.isNotEmpty ? _saveDir : 'Default App Storage',
                    style: const TextStyle(color: AppColors.mainText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
