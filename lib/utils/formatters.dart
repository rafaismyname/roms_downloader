import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roms_downloader/models/app_models.dart';

String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const k = 1024;
  final dm = decimals < 0 ? 0 : decimals;
  final sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (math.log(bytes) / math.log(k)).floor();
  return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
}

String formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond < 1024) {
    return '$bytesPerSecond B/s';
  } else if (bytesPerSecond < 1024 * 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
  } else if (bytesPerSecond < 1024 * 1024 * 1024) {
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  } else {
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }
}

Color getStatusColor(BuildContext context, GameDownloadStatus status) {
  switch (status) {
    case GameDownloadStatus.ready:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case GameDownloadStatus.queued:
      return Theme.of(context).colorScheme.tertiary;
    case GameDownloadStatus.error:
      return Theme.of(context).colorScheme.error;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}
