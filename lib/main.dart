import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/app.dart';
import 'package:roms_downloader/tasks/extraction_task.dart';

void main() {
  ExtractionTask.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: RomsDownloaderApp(),
    ),
  );
}
