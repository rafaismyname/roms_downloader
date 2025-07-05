import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

typedef FileCheckData = ({String filename, String downloadDir});
typedef FileCheckResult = ({bool hasFile, bool hasExtracted});

class DirectoryService {
  static final Map<String, List<FileSystemEntity>> _cachedDirsContent = {};

  Future<String> getDownloadDir() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDir = prefs.getString('downloadDir');

    if (savedDir != null && savedDir.isNotEmpty) {
      final dir = Directory(savedDir);
      if (await dir.exists()) {
        return savedDir;
      }
    }

    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir.path;
        }
      }
    }

    final downloadDir = await getDownloadsDirectory();
    if (downloadDir != null) {
      return downloadDir.path;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  Future<String?> selectDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isDenied) {
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              debugPrint('Storage permission denied');
              return null;
            }
          }
        }
      }

      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('downloadDir', selectedDirectory);
      return selectedDirectory;
    } catch (e) {
      debugPrint('Error selecting directory: $e');
      return null;
    }
  }

  Future<FileCheckResult> computeFileCheck(FileCheckData data) async {
    final expectedPath = path.join(data.downloadDir, data.filename);

    // Check: does the exact file exist or any file with the same base name?
    bool hasFile = File(expectedPath).existsSync();

    // Simple check: does a folder with the same name (without extension) exist?
    final filenameWithoutExt = path.basenameWithoutExtension(data.filename);
    final extractionDir = path.join(data.downloadDir, filenameWithoutExt);
    final directory = Directory(extractionDir);
    bool hasExtracted = directory.existsSync();

    // Check (one last time) if the file exists but with different extension
    if (!hasFile && !hasExtracted) {
      try {
        final dir = Directory(data.downloadDir);
        if (dir.existsSync()) {
          final filenameBase = path.basenameWithoutExtension(data.filename);
          final cachedContent = _cachedDirsContent[data.downloadDir];
          final content = cachedContent ?? dir.listSync();
          for (final entity in content) {
            if (entity is File) {
              final entityBase = path.basenameWithoutExtension(path.basename(entity.path));
              if (entityBase.trim() == filenameBase.trim()) {
                hasExtracted = true;
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    // TODO1: implement more complex checks like normalized title matching

    return (hasFile: hasFile, hasExtracted: hasExtracted);
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('Deleted file: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete file: $e');
      return false;
    }
  }

  static bool isCompressedFile(String filePath) {
    Set<String> extensions = {'.zip'};
    if (!Platform.isAndroid) {
      extensions.addAll({'.tar', '.gz', '.tar.gz', '.tgz', '.bz2', '.tar.bz2', '.tbz', '.xz', '.tar.xz', '.txz'});
    }
    return extensions.contains(path.extension(filePath).toLowerCase()) || extensions.contains(path.extension(filePath, 2).toLowerCase());
  }
}
