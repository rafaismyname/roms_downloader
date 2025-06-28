import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

class ExtractionService {
  static const _supportedExtensions = {'.zip', '.tar', '.gz', '.tar.gz', '.tgz', '.bz2', '.tar.bz2', '.tbz', '.xz', '.tar.xz', '.txz'};

  bool isCompressedFile(String filePath) =>
      _supportedExtensions.contains(path.extension(filePath).toLowerCase()) || _supportedExtensions.contains(getInputExtension(filePath));

  bool isSupportedArchive(String filePath) => isCompressedFile(filePath);

  String getExtractionDirectory(String filePath) => path.join(path.dirname(filePath), path.basenameWithoutExtension(filePath));

  String getInputExtension(String inputPath) => path.extension(inputPath, 2).toLowerCase();

  Future<bool> extractFile({
    required String filePath,
    required Function(double progress) onProgress,
    required Function(String error) onError,
  }) async {
    if (!isSupportedArchive(filePath)) {
      onError('Unsupported archive format: ${path.extension(filePath)}');
      return false;
    }

    if (!File(filePath).existsSync()) {
      onError('Archive file does not exist: $filePath');
      return false;
    }

    final extractionDir = getExtractionDirectory(filePath);

    try {
      final receivePort = ReceivePort();
      final completer = Completer<bool>();
      
      receivePort.listen((message) {
        if (message['type'] == 'progress') {
          onProgress(message['value']);
        } else if (message['type'] == 'error') {
          onError(message['message']);
          completer.complete(false);
          receivePort.close();
        } else if (message['type'] == 'complete') {
          onProgress(1.0);
          completer.complete(true);
          receivePort.close();
        }
      });

      await Isolate.spawn(_extractInIsolate, {
        'filePath': filePath,
        'extractionDir': extractionDir,
        'sendPort': receivePort.sendPort,
      });

      return await completer.future;
    } catch (e) {
      onError('Failed to extract archive: $e');
      try {
        final dir = Directory(extractionDir);
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } catch (_) {}
      return false;
    }
  }

  static Future<void> _extractInIsolate(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    try {
      sendPort.send({'type': 'progress', 'value': 0.1});
      
      var count = 0;
      await extractFileToDisk(params['filePath'], params['extractionDir'], 
        callback: (_) {
          if (++count % 10 == 0) {
            sendPort.send({'type': 'progress', 'value': 0.1 + (count * 0.01)});
          }
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

  List<String> findSimilarContent(String filePath, String downloadDir) {
    final fileName = path.basenameWithoutExtension(filePath);
    final directory = Directory(downloadDir);
    final similarContent = <String>[];

    if (!directory.existsSync()) return similarContent;

    try {
      final contents = directory.listSync();

      for (final item in contents) {
        final itemName = path.basenameWithoutExtension(item.path);
        final itemBaseName = path.basename(item.path);

        if (_isNameSimilar(fileName, itemName) || _isNameSimilar(fileName, itemBaseName)) {
          similarContent.add(item.path);
        }
      }
    } catch (e) {
      debugPrint('Error finding similar content: $e');
    }

    return similarContent;
  }

  bool _isNameSimilar(String name1, String name2) {
    final clean1 = _cleanNameForComparison(name1);
    final clean2 = _cleanNameForComparison(name2);

    // Exact match
    if (clean1 == clean2) return true;

    // One contains the other
    if (clean1.contains(clean2) || clean2.contains(clean1)) return true;

    // Remove common patterns and check again
    final simpleName1 = _removeCommonPatterns(clean1);
    final simpleName2 = _removeCommonPatterns(clean2);

    if (simpleName1 == simpleName2) return true;
    if (simpleName1.contains(simpleName2) || simpleName2.contains(simpleName1)) return true;

    return false;
  }

  String _cleanNameForComparison(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  String _removeCommonPatterns(String name) {
    return name
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove parentheses content
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove brackets content
        .replaceAll(RegExp(r'disc\d+'), '') // Remove disc numbers
        .replaceAll(RegExp(r'cd\d+'), '') // Remove CD numbers
        .replaceAll(RegExp(r'part\d+'), '') // Remove part numbers
        .replaceAll(RegExp(r'v\d+(\.\d+)*'), '') // Remove version numbers
        .replaceAll(RegExp(r'rev\d+'), '') // Remove revision numbers
        .replaceAll(RegExp(r'\s+'), '') // Remove multiple spaces
        .trim();
  }
}
