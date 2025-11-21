import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:path/path.dart' as path;

class DirectoryService {
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
      if (await Permission.storage.status.isGranted) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir.path;
        }
      }
    }

    if (Platform.isLinux) {
      final dir = Directory('Downloads');
      if (!await dir.exists()) {
        await dir.create();
      }
      return dir.absolute.path;
    }

    final downloadDir = await getDownloadsDirectory();
    if (downloadDir != null) {
      return downloadDir.path;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  Future<String?> selectDownloadDirectory([BuildContext? context]) async {
    try {
      String? selectedDirectory;
      if (Platform.isLinux && context != null) {
        selectedDirectory = await FilesystemPicker.open(
          title: 'Select Directory',
          context: context,
          rootDirectory: Directory('/'),
          fsType: FilesystemType.folder,
          pickText: 'Select this folder',
          folderIconColor: Theme.of(context).colorScheme.primary,
        );
      } else {
        selectedDirectory = await FilePicker.platform.getDirectoryPath();
      }

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

  static Future<int> getFreeSpace(String dirPath) async {
    if (Platform.isMacOS || Platform.isLinux) {
      try {
        final result = await Process.run('df', ['-k', dirPath]);
        if (result.exitCode != 0) return 0;
        final output = result.stdout.toString().trim();
        final lines = output.split('\n');
        if (lines.length < 2) return 0;
        final parts = lines[1].split(RegExp(r"\s+"));
        if (parts.length < 4) return 0;
        final availKb = int.tryParse(parts[3]) ?? 0;
        return availKb * 1024;
      } catch (_) {
        return 0;
      }
    }

    double? freeDiskSpaceForPath = await DiskSpace.getFreeDiskSpaceForPath(dirPath);
    int freeInMb = freeDiskSpaceForPath?.toInt() ?? 0;
    int freeInBytes = freeInMb * 1024 * 1024;
    return freeInBytes;
  }
}
