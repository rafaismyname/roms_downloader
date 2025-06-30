import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roms_downloader/services/permission_service.dart';

class PermissionsSetting extends StatefulWidget {
  const PermissionsSetting({super.key});

  @override
  State<PermissionsSetting> createState() => _PermissionsSettingState();
}

class _PermissionsSettingState extends State<PermissionsSetting> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    if (!Platform.isAndroid) return;

    setState(() => _loading = true);
    
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in PermissionService.requiredPermissions) {
      statuses[permission] = await permission.status;
    }
    
    setState(() {
      _permissionStatuses = statuses;
      _loading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    setState(() => _loading = true);
    
    final status = await permission.request();
    
    setState(() {
      _permissionStatuses[permission] = status;
      _loading = false;
    });

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showSettingsDialog(permission);
      }
    }
  }

  Future<void> _showSettingsDialog(Permission permission) async {
    final description = PermissionService.permissionDescriptions[permission] ?? permission.toString();
    
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text('$description permission is required. Open app settings to grant it manually?'),
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
    );

    if (shouldOpen == true) {
      await openAppSettings();
      _loadPermissionStatuses();
    }
  }

  Widget _buildPermissionTile(Permission permission, PermissionStatus status) {
    final description = PermissionService.permissionDescriptions[permission] ?? permission.toString();
    final isGranted = status.isGranted;
    final isPermanentlyDenied = status.isPermanentlyDenied;

    return ListTile(
      leading: Icon(
        isGranted ? Icons.check_circle : Icons.error,
        color: isGranted ? Colors.green : Colors.red,
      ),
      title: Text(description),
      subtitle: Text(
        isGranted ? 'Granted' : isPermanentlyDenied ? 'Denied - Open settings' : 'Not granted',
        style: TextStyle(
          color: isGranted ? Colors.green : Colors.red,
          fontSize: 12,
        ),
      ),
      trailing: !isGranted
          ? FilledButton.tonal(
              onPressed: _loading ? null : () => _requestPermission(permission),
              child: Text(isPermanentlyDenied ? 'Settings' : 'Request'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    if (_loading && _permissionStatuses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.security),
              SizedBox(width: 12),
              Text('Permissions'),
              Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.security),
                  const SizedBox(width: 12),
                  Text(
                    'Permissions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            ..._permissionStatuses.entries.map(
              (entry) => _buildPermissionTile(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }
}
