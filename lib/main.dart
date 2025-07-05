import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/app.dart';
import 'package:roms_downloader/services/extraction_service.dart';

void main() {
  ExtractionService.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: RomsDownloaderApp(),
    ),
  );
}
