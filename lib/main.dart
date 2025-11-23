import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:roms_downloader/app.dart';
import 'package:roms_downloader/services/extraction_service.dart';
import 'package:roms_downloader/utils/linux_path_provider.dart';

void main() {
  if (Platform.isLinux) {
    PathProviderPlatform.instance = LinuxPathProvider();
  }

  ExtractionService.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  runApp(
    const ProviderScope(
      child: RomsDownloaderApp(),
    ),
  );
}
