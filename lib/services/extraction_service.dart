import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart' as virtual_archive;
import 'package:flutter_archive/flutter_archive.dart';
import 'dart:async';

class ExtractionService {
  static const String progressDataType = 'extraction_progress';
  static const String errorDataType = 'extraction_error';
  static const String completionDataType = 'extraction_completed';
  static final Set<String> _activeTasks = {};
  static final Map<String, Function(String taskId, double progress)> _onProgressCallbacks = {};
  static final Map<String, Function(String taskId, String error, String extractionDir)> _onErrorCallbacks = {};
  static final Map<String, Function(String taskId, String extractionDir)> _onCompleteCallbacks = {};
  static Timer? _serviceStopTimer;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      iosNotificationOptions: const IOSNotificationOptions(),
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'extraction_foreground_service',
        channelName: 'Extraction Service',
        channelDescription: 'Foreground service for file extraction',
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.once(),
      ),
    );

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  static void _cleanup(String taskId) {
    _activeTasks.remove(taskId);
    _onProgressCallbacks.remove(taskId);
    _onErrorCallbacks.remove(taskId);
    _onCompleteCallbacks.remove(taskId);
    _debouncedStopServiceIfAllDone();
  }

  static void _debouncedStopServiceIfAllDone() {
    if (_activeTasks.isEmpty) {
      _serviceStopTimer?.cancel();
      _serviceStopTimer = Timer(const Duration(seconds: 30), () {
        FlutterForegroundTask.stopService();
        debugPrint('Foreground service stopped');
      });
    } else {
      _serviceStopTimer?.cancel();
      debugPrint('Cannot stop service, active tasks: ${_activeTasks.length}');
    }
  }

  static void _onReceiveTaskData(Object data) {
    if (data is Map) {
      final type = data['type'] as String?;
      final taskId = data['taskId'] as String?;
      final extractionDir = data['extractionDir'] ?? '';
      if (taskId == null) return;

      switch (type) {
        case ExtractionService.progressDataType:
          final progress = data['value'] as double?;
          if (progress != null) _onProgressCallbacks[taskId]?.call(taskId, progress);
          break;
        case ExtractionService.errorDataType:
          final error = data['message'] as String?;
          if (error != null) {
            _onErrorCallbacks[taskId]?.call(taskId, error, extractionDir);
            _cleanup(taskId);
          }
          break;
        case ExtractionService.completionDataType:
          _onCompleteCallbacks[taskId]?.call(taskId, extractionDir);
          _cleanup(taskId);
          break;
      }
    }
  }

  static Future<void> startExtraction({
    required String taskId,
    required String filePath,
    required String extractionDir,
    required Function(String taskId, double progress) onProgress,
    required Function(String taskId, String extractionDir) onComplete,
    required Function(String taskId, String error, String extractionDir) onError,
  }) async {
    // Foreground service is only supported on Android, so we use an isolate for extraction on other platforms.
    // Also Android is the only platform that supports native unzip, the other platforms must use virtual
    if (!Platform.isAndroid) {
      return extractInIsolate(
        taskId,
        filePath,
        extractionDir,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );
    }

    _activeTasks.add(taskId);
    _onProgressCallbacks[taskId] = onProgress;
    _onErrorCallbacks[taskId] = onError;
    _onCompleteCallbacks[taskId] = onComplete;

    // Reset the stop timer avoiding closing the background service too early
    _serviceStopTimer?.cancel();

    final fileName = path.basename(filePath);

    // If first task, (re)start foreground service
    if (_activeTasks.length == 1) {
      await FlutterForegroundTask.startService(
        serviceId: 1,
        notificationTitle: 'Extracting Archive',
        notificationText: 'Extracting $fileName...',
        notificationIcon: const NotificationIcon(metaDataName: 'ic_notification'),
        callback: extractionTaskCallback,
      );
    } else {
      // if not the first task, just update the notification
      FlutterForegroundTask.updateService(notificationText: 'Extracting $fileName...');
    }

    debugPrint('Sending extraction task to foreground service: $filePath');

    FlutterForegroundTask.sendDataToTask({
      'action': 'extract',
      'taskId': taskId,
      'filePath': filePath,
      'extractionDir': extractionDir,
    });
  }

  static Future<void> extractInIsolate(
    String taskId,
    String filePath,
    String extractionDir, {
    required Function(String taskId, double progress) onProgress,
    required Function(String taskId, String extractionDir) onComplete,
    required Function(String taskId, String error, String extractionDir) onError,
  }) async {
    final receivePort = ReceivePort();

    receivePort.listen((message) {
      if (message['type'] == 'progress') {
        onProgress(taskId, message['value']);
      } else if (message['type'] == 'error') {
        onError(taskId, message['message'], extractionDir);
        receivePort.close();
      } else if (message['type'] == 'complete') {
        onComplete(taskId, extractionDir);
        receivePort.close();
      }
    });

    await Isolate.spawn(_extractInIsolate, {
      'taskId': taskId,
      'filePath': filePath,
      'extractionDir': extractionDir,
      'sendPort': receivePort.sendPort,
    });
  }

  static Future<void> _extractInIsolate(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    try {
      sendPort.send({'type': 'progress', 'value': 0.1});
      var extractedFiles = 0;
      await virtual_archive.extractFileToDisk(params['filePath'], params['extractionDir'], callback: (archiveFile) {
        final progress = (0.1 + (++extractedFiles / 4) * 0.85).clamp(0.1, 0.95);
        sendPort.send({'type': 'progress', 'value': progress});
      });
      sendPort.send({'type': 'complete'});
    } catch (e) {
      debugPrint('Extraction error: $e');
      sendPort.send({'type': 'error', 'message': 'Failed to extract: $e'});
    }
  }
}

@pragma('vm:entry-point')
void extractionTaskCallback() {
  FlutterForegroundTask.setTaskHandler(ExtractionTaskHandler());
}

class ExtractionTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await FlutterForegroundTask.updateService(notificationText: 'Ready to extract...');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['action'] == 'extract') {
      final taskId = data['taskId'] as String;
      final filePath = data['filePath'] as String;
      final extractionDir = data['extractionDir'] as String;
      FlutterForegroundTask.updateService(notificationText: 'Extracting $taskId...');
      FlutterForegroundTask.sendDataToMain({
        'type': ExtractionService.progressDataType,
        'taskId': taskId,
        'value': 0.1,
      });

      ZipFile.extractToDirectory(
        zipFile: File(filePath),
        destinationDir: Directory(extractionDir),
        onExtracting: (zipEntry, progress) => ZipFileOperation.includeItem,
      ).then((_) {
        FlutterForegroundTask.updateService(notificationText: 'Extraction completed for $taskId');
        FlutterForegroundTask.sendDataToMain({
          'type': ExtractionService.completionDataType,
          'taskId': taskId,
          'extractionDir': extractionDir,
        });
      }).catchError((e) {
        debugPrint('Extraction error: $e');
        FlutterForegroundTask.sendDataToMain({
          'type': ExtractionService.errorDataType,
          'taskId': taskId,
          'extractionDir': extractionDir,
          'message': 'Failed to extract: $e',
        });
        FlutterForegroundTask.updateService(notificationText: 'Extraction failed');
      });
    }
  }
}
