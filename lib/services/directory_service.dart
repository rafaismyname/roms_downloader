import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
