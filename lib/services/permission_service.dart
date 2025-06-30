import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roms_downloader/app.dart';

class PermissionService {
  static const String _lastPermissionRequestKey = 'last_permission_request';
  static const int _permissionCooldownDays = 7;

  static final Map<Permission, String> permissionDescriptions = {
    Permission.notification: 'Notifications',
    Permission.manageExternalStorage: 'Storage management',
  };

  static final List<Permission> requiredPermissions = [
    Permission.notification,
    Permission.manageExternalStorage,
  ];

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final permanentlyDeniedPermissions = <Permission>[];
      bool allGranted = true;

      for (final permission in requiredPermissions) {
        final status = await permission.status;
        debugPrint('Permission $permission status: $status');
        if (!status.isGranted) {
          allGranted = false;
          debugPrint('Requesting permission: $permission');
          final result = await permission.request();
          debugPrint('Permission $permission result: $result');
          if (!result.isGranted && result.isPermanentlyDenied) {
            permanentlyDeniedPermissions.add(permission);
          }
        }
      }

      if (permanentlyDeniedPermissions.isNotEmpty) {
        final canAskAgain = await _canAskForAppSettings();
        if (canAskAgain) {
          final shouldOpenSettings = await _showPermissionSettingsDialog(permanentlyDeniedPermissions);
          if (shouldOpenSettings) {
            await openAppSettings();
          }
          await _saveLastPermissionRequest();
        }
      }

      return allGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  Future<bool> _canAskForAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRequest = prefs.getInt(_lastPermissionRequestKey);

    if (lastRequest == null) return true;

    final lastRequestDate = DateTime.fromMillisecondsSinceEpoch(lastRequest);
    final now = DateTime.now();
    final daysSinceLastRequest = now.difference(lastRequestDate).inDays;

    return daysSinceLastRequest >= _permissionCooldownDays;
  }

  Future<void> _saveLastPermissionRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPermissionRequestKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _showPermissionSettingsDialog(List<Permission> missingPermissions) async {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    final missingNames = missingPermissions.map((p) => permissionDescriptions[p] ?? p.toString()).toList();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The following permissions are required for the app to function properly:'),
                const SizedBox(height: 8),
                ...missingNames.map((name) => Text('• $name')),
                const SizedBox(height: 12),
                const Text('Open settings to grant permissions?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
