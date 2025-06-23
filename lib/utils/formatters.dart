import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roms_downloader/services/game_state_service.dart';

String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const k = 1024;
  final dm = decimals < 0 ? 0 : decimals;
  final sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (math.log(bytes) / math.log(k)).floor();
  return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
}

Color getStatusColor(BuildContext context, GameDownloadStatus status) {
  switch (status) {
    case GameDownloadStatus.ready:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case GameDownloadStatus.queued:
      return Theme.of(context).colorScheme.tertiary;
    case GameDownloadStatus.downloading:
      return Theme.of(context).colorScheme.primary;
    case GameDownloadStatus.paused:
      return Theme.of(context).colorScheme.secondary;
    case GameDownloadStatus.completed:
    case GameDownloadStatus.inLibrary:
      return Theme.of(context).colorScheme.primary;
    case GameDownloadStatus.error:
      return Theme.of(context).colorScheme.error;
    default:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
