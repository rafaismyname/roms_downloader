import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/app.dart';
import 'package:roms_downloader/utils/handheld_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize handheld detection for optimized experience
  await HandheldDetector.initialize();
  
  runApp(
    const ProviderScope(
      child: RomsDownloaderApp(),
    ),
  );
}
