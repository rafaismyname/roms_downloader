import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_model.dart';

class EmulatorService {
  static Future<void> launchGame(WidgetRef ref, Game game) async {
    debugPrint('Launching game: ${game.title} on console: ${game.consoleId}');
  }
}
