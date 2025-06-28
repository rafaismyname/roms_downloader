import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart' as path;

class ExtractionService {
  bool isCompressedFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.zip' || extension == '.rar' || extension == '.7z' || extension == '.gz' || extension == '.tar.gz';
  }

  bool isSupportedArchive(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.zip';
  }

  String getExtractionDirectory(String filePath) {
    final dir = path.dirname(filePath);
    final fileName = path.basenameWithoutExtension(filePath);
    return path.join(dir, fileName);
  }

  Future<bool> extractFile({
    required String filePath,
    required Function(double progress) onProgress,
    required Function(String error) onError,
  }) async {
    if (!isSupportedArchive(filePath)) {
      onError('Unsupported archive format: ${path.extension(filePath)}');
      return false;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      onError('Archive file does not exist: $filePath');
      return false;
    }

    final extractionDir = getExtractionDirectory(filePath);
    final destinationDir = Directory(extractionDir);

    try {
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }

      debugPrint('Extracting $filePath to $extractionDir');

      var lastProgress = 0.0;

      await ZipFile.extractToDirectory(
        zipFile: file,
        destinationDir: destinationDir,
        onExtracting: (zipEntry, progress) {
          if (progress > lastProgress) {
            lastProgress = progress;
            onProgress(progress / 100.0);
          }

          debugPrint('Extracting: ${zipEntry.name} (${progress.toStringAsFixed(1)}%)');
          return ZipFileOperation.includeItem;
        },
      );

      onProgress(1.0);

      debugPrint('Extraction completed: $filePath');
      return true;
    } catch (e) {
      debugPrint('Extraction failed: $e');
      onError('Failed to extract archive: $e');

      if (destinationDir.existsSync()) {
        try {
          destinationDir.deleteSync(recursive: true);
        } catch (cleanupError) {
          debugPrint('Failed to cleanup partial extraction: $cleanupError');
        }
      }

      return false;
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
