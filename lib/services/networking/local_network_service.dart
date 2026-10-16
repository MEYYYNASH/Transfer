import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/hash_util.dart';
import '../../core/utils/path_sanitizer.dart';
import '../../shared/models/transfer_models.dart';
import '../../features/local_transfer/domain/transport_interfaces.dart';

class LocalNetworkService implements LocalNetworkTransport {
  ServerSocket? _serverSocket;
  bool _isListening = false;
  String _saveDirectory = '';

  bool get isListening => _isListening;

  void setSaveDirectory(String dir) {
    _saveDirectory = dir;
  }

  @override
  Future<void> startListening({
    required int port,
    required Future<bool> Function(String peerIp, String fileName, int fileSize) onIncomingPrompt,
    required void Function(TransferRecordModel record) onProgress,
  }) async {
    if (_isListening) return;

    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _isListening = true;

    _serverSocket!.listen((Socket client) async {
      final peerIp = client.remoteAddress.address;
      await _handleIncomingClient(client, peerIp, onIncomingPrompt, onProgress);
    });
  }

  Future<void> _handleIncomingClient(
    Socket client,
    String peerIp,
    Future<bool> Function(String peerIp, String fileName, int fileSize) onIncomingPrompt,
    void Function(TransferRecordModel record) onProgress,
  ) async {
    final transferId = 'rx_${DateTime.now().millisecondsSinceEpoch}';
    TransferRecordModel record = TransferRecordModel(
      id: transferId,
      direction: TransferDirection.incoming,
      transport: TransferTransport.localNetwork,
      status: TransferStatus.connecting,
      totalBytes: 0,
      transferredBytes: 0,
      createdAt: DateTime.now(),
      peerName: peerIp,
    );
    onProgress(record);

    try {
      // 1. Read metadata header line terminated by \n
      final List<int> headerBuffer = [];
      var headerDone = false;
      StreamSubscription? sub;
      final completer = Completer<void>();

      Map<String, dynamic>? metadata;
      IOSink? fileSink;
      File? tempFile;
      String? safeDestPath;
      int receivedBytes = 0;
      int totalExpectedBytes = 0;
      final digestSink = AccumulatorSink<Digest>();
      final shaSink = sha256.startChunkedConversion(digestSink);

      sub = client.listen(
        (data) async {
          if (!headerDone) {
            for (var i = 0; i < data.length; i++) {
              if (data[i] == 10) { // '\n'
                headerDone = true;
                final headerStr = utf8.decode(headerBuffer);
                metadata = jsonDecode(headerStr) as Map<String, dynamic>;

                final fileName = metadata!['fileName'] as String;
                totalExpectedBytes = metadata!['fileSize'] as int;
                final expectedHash = metadata!['sha256'] as String?;

                record = record.copyWith(
                  status: TransferStatus.preparing,
                  totalBytes: totalExpectedBytes,
                );
                onProgress(record);

                // Prompt receiver confirmation
                final accepted = await onIncomingPrompt(peerIp, fileName, totalExpectedBytes);
                if (!accepted) {
                  client.write('REJECTED\n');
                  await client.flush();
                  await client.close();
                  record = record.copyWith(status: TransferStatus.cancelled);
                  onProgress(record);
                  completer.complete();
                  return;
                }

                client.write('ACCEPTED\n');
                await client.flush();

                safeDestPath = PathSanitizer.resolveSafePath(_saveDirectory, fileName);
                tempFile = File('$safeDestPath.part');
                fileSink = tempFile!.openWrite();

                record = record.copyWith(status: TransferStatus.running);
                onProgress(record);

                // Add remaining bytes of this chunk after header
                final remaining = data.sublist(i + 1);
                if (remaining.isNotEmpty) {
                  shaSink.add(remaining);
                  fileSink!.add(remaining);
                  receivedBytes += remaining.length;
                  record = record.copyWith(transferredBytes: receivedBytes);
                  onProgress(record);
                }
                break;
              } else {
                headerBuffer.add(data[i]);
              }
            }
          } else {
            // Streaming file chunks
            shaSink.add(data);
            fileSink!.add(data);
            receivedBytes += data.length;
            record = record.copyWith(
              transferredBytes: receivedBytes,
              status: TransferStatus.running,
            );
            onProgress(record);
          }
        },
        onError: (err) {
          record = record.copyWith(
            status: TransferStatus.failed,
            errorCode: err.toString(),
          );
          onProgress(record);
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () async {
          try {
            if (fileSink != null) {
              await fileSink!.flush();
              await fileSink!.close();
              shaSink.close();

              record = record.copyWith(status: TransferStatus.verifying);
              onProgress(record);

              final calculatedSha = digestSink.events.single.toString();
              final expectedHash = metadata?['sha256'] as String?;

              if (expectedHash != null && expectedHash.isNotEmpty) {
                if (!HashUtil.verifyHash(expectedHash, calculatedSha)) {
                  throw VerificationFailedException(
                    expectedSha256: expectedHash,
                    actualSha256: calculatedSha,
                  );
                }
              }

              // Rename temporary file to safe destination
              await tempFile!.rename(safeDestPath!);

              record = record.copyWith(
                status: TransferStatus.completed,
                completedAt: DateTime.now(),
              );
              onProgress(record);
            }
          } catch (e) {
            record = record.copyWith(
              status: TransferStatus.failed,
              errorCode: e.toString(),
            );
            onProgress(record);
          } finally {
            if (!completer.isCompleted) completer.complete();
          }
        },
      );

      await completer.future;
      await sub.cancel();
    } catch (e) {
      record = record.copyWith(
        status: TransferStatus.failed,
        errorCode: e.toString(),
      );
      onProgress(record);
    }
  }

  @override
  Future<void> sendFiles({
    required String targetIp,
    required int targetPort,
    required List<File> files,
    required String transferId,
    required void Function(TransferRecordModel progress) onProgress,
  }) async {
    for (final file in files) {
      if (!await file.exists()) continue;

      final fileName = p.basename(file.path);
      final fileSize = await file.length();

      var record = TransferRecordModel(
        id: transferId,
        direction: TransferDirection.outgoing,
        transport: TransferTransport.localNetwork,
        status: TransferStatus.preparing,
        totalBytes: fileSize,
        transferredBytes: 0,
        createdAt: DateTime.now(),
        peerName: targetIp,
      );
      onProgress(record);

      // Pre-compute SHA-256 for integrity check
      final fileSha256 = await HashUtil.calculateFileSha256(file);

      record = record.copyWith(status: TransferStatus.connecting);
      onProgress(record);

      Socket socket;
      try {
        socket = await Socket.connect(targetIp, targetPort, timeout: const Duration(seconds: 10));
      } catch (e) {
        record = record.copyWith(
          status: TransferStatus.failed,
          errorCode: 'CONNECTION_REFUSED: $e',
        );
        onProgress(record);
        return;
      }

      // 1. Send metadata JSON header
      final metadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'sha256': fileSha256,
      };
      socket.write('${jsonEncode(metadata)}\n');
      await socket.flush();

      // 2. Wait for handshake response (ACCEPTED / REJECTED)
      final handshakeCompleter = Completer<bool>();
      late StreamSubscription socketSub;
      final buffer = <int>[];

      socketSub = socket.listen((data) {
        buffer.addAll(data);
        final str = String.fromCharCodes(buffer);
        if (str.contains('ACCEPTED\n')) {
          handshakeCompleter.complete(true);
        } else if (str.contains('REJECTED\n')) {
          handshakeCompleter.complete(false);
        }
      });

      final accepted = await handshakeCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
      await socketSub.cancel();

      if (!accepted) {
        socket.destroy();
        record = record.copyWith(
          status: TransferStatus.cancelled,
          errorCode: 'REJECTED_OR_TIMED_OUT',
        );
        onProgress(record);
        return;
      }

      // 3. Stream bounded chunks (64 KB)
      record = record.copyWith(status: TransferStatus.running);
      onProgress(record);

      const chunkSize = 64 * 1024;
      final raf = await file.open(mode: FileMode.read);
      var bytesSent = 0;

      try {
        while (bytesSent < fileSize) {
          final toRead = (fileSize - bytesSent) > chunkSize ? chunkSize : (fileSize - bytesSent);
          final chunk = await raf.read(toRead);
          socket.add(chunk);
          await socket.flush();

          bytesSent += chunk.length;
          record = record.copyWith(transferredBytes: bytesSent);
          onProgress(record);
        }

        record = record.copyWith(
          status: TransferStatus.completed,
          completedAt: DateTime.now(),
        );
        onProgress(record);
      } catch (e) {
        record = record.copyWith(
          status: TransferStatus.failed,
          errorCode: e.toString(),
        );
        onProgress(record);
      } finally {
        await raf.close();
        await socket.close();
      }
    }
  }

  @override
  Future<void> stopListening() async {
    if (_serverSocket != null) {
      await _serverSocket!.close();
      _serverSocket = null;
    }
    _isListening = false;
  }
}
