import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

class ExtractionService {
  static const _supportedExtensions = {'.zip', '.tar', '.gz', '.tar.gz', '.tgz', '.bz2', '.tar.bz2', '.tbz', '.xz', '.tar.xz', '.txz'};

  bool isCompressedFile(String filePath) =>
      _supportedExtensions.contains(path.extension(filePath).toLowerCase()) || _supportedExtensions.contains(path.extension(filePath, 2).toLowerCase());

  String getExtractionDirectory(String filePath) => path.join(path.dirname(filePath), path.basenameWithoutExtension(filePath));

  Future<void> extractFile({
    required String filePath,
    required Function(double progress) onProgress,
    required Function(String error) onError,
  }) async {
    if (!isCompressedFile(filePath)) {
      onError('Unsupported archive format: ${path.extension(filePath)}');
      return;
    }

    if (!File(filePath).existsSync()) {
      onError('Archive file does not exist: $filePath');
      return;
    }

    final extractionDir = getExtractionDirectory(filePath);

    try {
      final receivePort = ReceivePort();

      receivePort.listen((message) {
        if (message['type'] == 'progress') {
          onProgress(message['value']);
        } else if (message['type'] == 'error') {
          onError(message['message']);
          receivePort.close();
        } else if (message['type'] == 'complete') {
          onProgress(1.0);
          receivePort.close();
        }
      });

      await Isolate.spawn(_extractInIsolate, {
        'filePath': filePath,
        'extractionDir': extractionDir,
        'sendPort': receivePort.sendPort,
      });
    } catch (e) {
      onError('Failed to extract archive: $e');
      try {
        final dir = Directory(extractionDir);
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  static Future<void> _extractInIsolate(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    try {
      sendPort.send({'type': 'progress', 'value': 0.1});
      var extractedFiles = 0;
      await extractFileToDisk(params['filePath'], params['extractionDir'], callback: (archiveFile) {
        final progress = (0.1 + (++extractedFiles / 4) * 0.85).clamp(0.1, 0.95);
        sendPort.send({'type': 'progress', 'value': progress});
      });
      sendPort.send({'type': 'complete'});
    } catch (e) {
      sendPort.send({'type': 'error', 'message': 'Failed to extract: $e'});
    }
  }

  Future<bool> deleteOriginalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('Deleted original archive: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete original archive: $e');
      return false;
    }
  }

  bool hasExtractedContent(String filePath) {
    final extractionDir = getExtractionDirectory(filePath);
    final directory = Directory(extractionDir);

    if (!directory.existsSync()) return false;

    try {
      final contents = directory.listSync();
      return contents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
