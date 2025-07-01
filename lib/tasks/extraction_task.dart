import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';

class ExtractionTask {
  static const String progressDataType = 'extraction_progress';
  static const String errorDataType = 'extraction_error';
  static const String completionDataType = 'extraction_completed';
  static final Set<String> _activeTasks = {};
  static final Map<String, Function(String taskId, double progress)> _onProgressCallbacks = {};
  static final Map<String, Function(String taskId, String error, String extractionDir)> _onErrorCallbacks = {};
  static final Map<String, Function(String taskId, String extractionDir)> _onCompleteCallbacks = {};

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
    _stopServiceIfAllDone();
  }

  static void _stopServiceIfAllDone() {
    if (_activeTasks.isEmpty) {
      FlutterForegroundTask.stopService();
      debugPrint('Foreground service stopped');
    } else {
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
        case ExtractionTask.progressDataType:
          final progress = data['value'] as double?;
          if (progress != null) _onProgressCallbacks[taskId]?.call(taskId, progress);
          break;
        case ExtractionTask.errorDataType:
          final error = data['message'] as String?;
          if (error != null) {
            _onErrorCallbacks[taskId]?.call(taskId, error, extractionDir);
            _cleanup(taskId);
          }
          break;
        case ExtractionTask.completionDataType:
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
    if (!Platform.isAndroid) {
      extractInIsolate(
        taskId,
        filePath,
        extractionDir,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );
      return;
    }

    _activeTasks.add(taskId);
    _onProgressCallbacks[taskId] = onProgress;
    _onErrorCallbacks[taskId] = onError;
    _onCompleteCallbacks[taskId] = onComplete;

    final fileName = path.basename(filePath);
    await FlutterForegroundTask.startService(
      serviceId: _activeTasks.length,
      notificationTitle: 'Extracting Archive',
      notificationText: 'Extracting $fileName...',
      callback: extractionTaskCallback,
    );

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
      await extractFileToDisk(params['filePath'], params['extractionDir'], callback: (archiveFile) {
        final progress = (0.1 + (++extractedFiles / 4) * 0.85).clamp(0.1, 0.95);
        sendPort.send({'type': 'progress', 'value': progress});
      });
      sendPort.send({'type': 'complete'});
    } catch (e) {
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
      FlutterForegroundTask.updateService(notificationText: 'Starting extraction of $taskId...');
      FlutterForegroundTask.sendDataToMain({
        'type': ExtractionTask.progressDataType,
        'taskId': taskId,
        'value': 0.1,
      });
      try {
        ExtractionTask.extractInIsolate(
          taskId,
          filePath,
          extractionDir,
          onProgress: (taskId, progress) {
            FlutterForegroundTask.updateService(
              notificationText: 'Extracting $taskId... ${(progress * 100).toInt()}%',
            );

            FlutterForegroundTask.sendDataToMain({
              'type': ExtractionTask.progressDataType,
              'taskId': taskId,
              'value': progress,
            });
          },
          onComplete: (taskId, extractionDir) {
            FlutterForegroundTask.sendDataToMain({
              'type': ExtractionTask.completionDataType,
              'taskId': taskId,
              'extractionDir': extractionDir,
            });
          },
          onError: (taskId, error, extractionDir) {
            FlutterForegroundTask.sendDataToMain({
              'type': ExtractionTask.errorDataType,
              'taskId': taskId,
              'extractionDir': extractionDir,
              'message': error,
            });
            FlutterForegroundTask.updateService(notificationText: 'Extraction failed: $error');
          },
        );
      } catch (e) {
        FlutterForegroundTask.sendDataToMain({
          'type': ExtractionTask.errorDataType,
          'taskId': taskId,
          'extractionDir': extractionDir,
          'message': 'Failed to extract: $e',
        });
        FlutterForegroundTask.updateService(notificationText: 'Extraction failed');
      }
    }
  }
}
