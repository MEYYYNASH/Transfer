import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../../updates/data/update_repository.dart';

class UpdateCenterScreen extends ConsumerStatefulWidget {
  const UpdateCenterScreen({super.key});

  @override
  ConsumerState<UpdateCenterScreen> createState() => _UpdateCenterScreenState();
}

class _UpdateCenterScreenState extends ConsumerState<UpdateCenterScreen> {
  final String _currentVersion = '1.0.0';
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  ReleaseArtifact? _availableRelease;
  String? _statusInfo;
  File? _downloadedInstaller;

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
      _statusInfo = null;
      _availableRelease = null;
    });

    try {
      final updateRepo = ref.read(updateRepositoryProvider);
      final release = await updateRepo.checkForUpdate(_currentVersion);

      setState(() {
        _isChecking = false;
        if (release != null) {
          _availableRelease = release;
          _statusInfo = 'New release found: ${release.version}';
        } else {
          _statusInfo = 'LINKORA is up to date! (Current: v$_currentVersion)';
        }
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusInfo = 'Update check error: $e';
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_availableRelease == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusInfo = 'Downloading update package...';
    });

    try {
      final updateRepo = ref.read(updateRepositoryProvider);
      final tempDir = await getTemporaryDirectory();

      final file = await updateRepo.downloadAndVerifyUpdate(
        artifact: _availableRelease!,
        destinationDir: tempDir.path,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress = (received / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadedInstaller = file;
        _statusInfo = 'Integrity verified! Ready to install.';
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusInfo = 'Download / Verification failed: $e';
      });
    }
  }

  Future<void> _runInstaller() async {
    if (_downloadedInstaller == null) return;
    try {
      final updateRepo = ref.read(updateRepositoryProvider);
      await updateRepo.installUpdate(_downloadedInstaller!);
    } catch (e) {
      setState(() {
        _statusInfo = 'Installation failed to launch: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocale(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('checkForUpdates')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Version Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.primaryAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Installed Version',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                        Text(
                          'v$_currentVersion (Stable)',
                          style: const TextStyle(
                            color: AppColors.mainText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isChecking ? null : _checkUpdate,
                    child: Text(_isChecking ? 'Checking...' : 'Check Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_statusInfo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  _statusInfo!,
                  style: const TextStyle(color: AppColors.mainText, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_availableRelease != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondaryAccent.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _availableRelease!.title,
                          style: const TextStyle(
                            color: AppColors.mainText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(_availableRelease!.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: const TextStyle(
                              color: AppColors.secondaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Release Notes & Changelog:',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _availableRelease!.changelog.isNotEmpty
                            ? _availableRelease!.changelog
                            : 'Bug fixes and performance enhancements.',
                        style: const TextStyle(color: AppColors.mainText, fontSize: 13),
                      ),
                    ),
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
                          'Downloading update... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                      ),
                    ] else if (_downloadedInstaller != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _runInstaller,
                          icon: const Icon(Icons.install_mobile),
                          label: const Text('Install Update Now'),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _downloadAndInstall,
                          icon: const Icon(Icons.download),
                          label: const Text('Download Verified Update'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
