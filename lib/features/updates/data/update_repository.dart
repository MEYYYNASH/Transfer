import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/hash_util.dart';
import '../../core/utils/version_comparator.dart';

class ReleaseArtifact {
  final String version;
  final String title;
  final String changelog;
  final String downloadUrl;
  final String fileName;
  final int sizeBytes;
  final String? sha256Checksum;

  ReleaseArtifact({
    required this.version,
    required this.title,
    required this.changelog,
    required this.downloadUrl,
    required this.fileName,
    required this.sizeBytes,
    this.sha256Checksum,
  });
}

class UpdateRepository {
  final String repoOwner;
  final String repoName;
  final http.Client _client;

  UpdateRepository({
    this.repoOwner = 'linkora-org',
    this.repoName = 'linkora',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Check latest release on GitHub
  Future<ReleaseArtifact?> checkForUpdate(String currentVersion) async {
    final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
    final response = await _client.get(url, headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'Linkora-Updater-1.0',
    });

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = data['tag_name'] as String;
    final title = data['name'] as String? ?? tagName;
    final body = data['body'] as String? ?? '';
    final assets = data['assets'] as List<dynamic>? ?? [];

    if (!VersionComparator.isUpdateAvailable(currentVersion, tagName)) {
      return null; // Already latest or newer
    }

    // Identify platform asset
    String targetExtension;
    if (Platform.isAndroid) {
      targetExtension = '.apk';
    } else if (Platform.isWindows) {
      targetExtension = '.exe';
    } else {
      return null;
    }

    final matchingAsset = assets.firstWhere(
      (asset) => (asset['name'] as String).toLowerCase().endsWith(targetExtension),
      orElse: () => null,
    );

    if (matchingAsset == null) return null;

    return ReleaseArtifact(
      version: tagName,
      title: title,
      changelog: body,
      downloadUrl: matchingAsset['browser_download_url'] as String,
      fileName: matchingAsset['name'] as String,
      sizeBytes: matchingAsset['size'] as int,
    );
  }

  /// Download and verify integrity of update artifact
  Future<File> downloadAndVerifyUpdate({
    required ReleaseArtifact artifact,
    required String destinationDir,
    required void Function(int received, int total) onProgress,
  }) async {
    final saveFile = File('$destinationDir/${artifact.fileName}');
    final request = http.Request('GET', Uri.parse(artifact.downloadUrl));
    final response = await _client.send(request);

    final sink = saveFile.openWrite();
    var bytesReceived = 0;

    await for (final chunk in response.stream) {
      sink.add(chunk);
      bytesReceived += chunk.length;
      onProgress(bytesReceived, artifact.sizeBytes);
    }
    await sink.flush();
    await sink.close();

    // Verify SHA-256 if provided in manifest
    if (artifact.sha256Checksum != null && artifact.sha256Checksum!.isNotEmpty) {
      final actualSha = await HashUtil.calculateFileSha256(saveFile);
      if (!HashUtil.verifyHash(artifact.sha256Checksum!, actualSha)) {
        await saveFile.delete();
        throw UpdateVerificationException(
          'Update verification failed: SHA-256 checksum does not match official release signature.',
        );
      }
    }

    return saveFile;
  }

  /// Execute platform update installer
  Future<void> installUpdate(File installerFile) async {
    if (Platform.isWindows) {
      // Execute the Inno Setup / NSIS installer
      await Process.start(
        installerFile.path,
        ['/SILENT', '/SP-', '/CLOSEAPPLICATIONS'],
        mode: ProcessStartMode.detached,
      );
    } else if (Platform.isAndroid) {
      // Prompt Android Package Installer via Intent
      await OpenFilex.open(installerFile.path);
    }
  }
}
