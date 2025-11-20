import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A custom implementation of [PathProviderPlatform] for Linux/PortMaster.
/// This bypasses the standard `path_provider_linux` which relies on GLib/XDG
/// and often fails in minimal environments.
class LinuxPathProvider extends PathProviderPlatform {
  final String _basePath = Directory.current.path;

  @override
  Future<String?> getTemporaryPath() async {
    final dir = Directory('$_basePath/cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory('$_basePath/data');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getLibraryPath() async {
    final dir = Directory('$_basePath/data');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = Directory('$_basePath/Documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return getApplicationDocumentsPath();
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    final path = await getTemporaryPath();
    return path != null ? [path] : [];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    final path = await getApplicationDocumentsPath();
    return path != null ? [path] : [];
  }

  @override
  Future<String?> getDownloadsPath() async {
    final dir = Directory('$_basePath/Downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}
