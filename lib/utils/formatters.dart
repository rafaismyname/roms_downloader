import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/task_queue_model.dart';

String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const k = 1024;
  final dm = decimals < 0 ? 0 : decimals;
  final sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (math.log(bytes) / math.log(k)).floor();
  return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
}

String formatNetworkSpeed(double megabytesPerSecond) {
  if (megabytesPerSecond <= 0) return '-- MB/s';
  if (megabytesPerSecond >= 1) {
    return '${megabytesPerSecond.toStringAsFixed(1)} MB/s';
  } else {
    return '${(megabytesPerSecond * 1000).toStringAsFixed(0)} KB/s';
  }
}

String formatTimeRemaining(Duration duration) {
  if (duration <= Duration.zero) return '';

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

String formatTaskTime(QueuedTask task) {
  final now = DateTime.now();
  final duration = task.completedAt != null
      ? task.completedAt!.difference(task.createdAt)
      : now.difference(task.createdAt);

  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  } else {
    return '${duration.inSeconds}s';
  }
}

Color getStatusColor(BuildContext context, GameStatus status) {
  switch (status) {
    case GameStatus.init:
    case GameStatus.loading:
      return Theme.of(context).colorScheme.secondary;
    case GameStatus.ready:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case GameStatus.downloadQueued:
      return Theme.of(context).colorScheme.secondary;
    case GameStatus.downloading:
      return Theme.of(context).colorScheme.primary;
    case GameStatus.downloadPaused:
      return Theme.of(context).colorScheme.secondary;
    case GameStatus.downloaded:
      return Theme.of(context).colorScheme.primary;
    case GameStatus.extractionQueued:
      return Theme.of(context).colorScheme.secondary;
    case GameStatus.extracting:
      return Theme.of(context).colorScheme.secondary;
    case GameStatus.extracted:
      return Theme.of(context).colorScheme.primary;
    case GameStatus.downloadFailed:
    case GameStatus.extractionFailed:
    case GameStatus.error:
      return Theme.of(context).colorScheme.error;
    case GameStatus.processing:
      return Theme.of(context).colorScheme.secondary;
  }
}

Color getTaskStatusColor(BuildContext context, TaskQueueStatus status) {
  switch (status) {
    case TaskQueueStatus.waiting:
      return Theme.of(context).colorScheme.secondary;
    case TaskQueueStatus.running:
      return Theme.of(context).colorScheme.primary;
    case TaskQueueStatus.completed:
      return Theme.of(context).colorScheme.tertiary;
    case TaskQueueStatus.failed:
      return Theme.of(context).colorScheme.error;
    case TaskQueueStatus.cancelled:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
