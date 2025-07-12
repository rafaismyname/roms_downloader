import 'package:flutter/material.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/settings_model.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/widgets/settings/directory_setting.dart';
import 'package:roms_downloader/widgets/settings/boolean_setting.dart';
import 'package:roms_downloader/widgets/settings/number_setting.dart';
import 'package:roms_downloader/widgets/settings/permissions_setting.dart';
import 'package:roms_downloader/widgets/settings/tools_setting.dart';

class SettingsContent extends StatelessWidget {
  final Console? selectedConsole;
  final SettingsNotifier settingsNotifier;

  const SettingsContent({
    super.key,
    required this.selectedConsole,
    required this.settingsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(selectedConsole == null ? Icons.settings : Icons.videogame_asset),
                      const SizedBox(width: 12),
                      Text(
                        selectedConsole == null ? 'General Settings' : '${selectedConsole!.name} Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DirectorySetting(
                    settingKey: AppSettings.downloadDir,
                    title: 'Download Directory',
                    icon: Icons.folder_open,
                    console: selectedConsole,
                    settingsNotifier: settingsNotifier,
                  ),
                  const SizedBox(height: 8),
                  BooleanSetting(
                    settingKey: AppSettings.autoExtract,
                    defaultValue: true,
                    title: 'Auto Extract After Download',
                    subtitle: 'Automatically extract archive files after download completes',
                    icon: Icons.archive,
                    console: selectedConsole,
                    settingsNotifier: settingsNotifier,
                  ),
                  if (selectedConsole == null) ...[
                    const SizedBox(height: 8),
                    NumberSetting(
                      settingKey: AppSettings.maxParallelDownloads,
                      defaultValue: 5,
                      title: 'Max Parallel Downloads',
                      subtitle: 'Maximum number of simultaneous downloads',
                      icon: Icons.download,
                      min: 1,
                      max: 20,
                      dropdown: true,
                      settingsNotifier: settingsNotifier,
                    ),
                    const SizedBox(height: 8),
                    NumberSetting(
                      settingKey: AppSettings.maxParallelExtractions,
                      defaultValue: 2,
                      title: 'Max Parallel Extractions',
                      subtitle: 'Maximum number of simultaneous extractions',
                      icon: Icons.archive,
                      min: 1,
                      max: 20,
                      dropdown: true,
                      settingsNotifier: settingsNotifier,
                    ),
                  ],
                ],
              ),
            ),
          ),
           if (selectedConsole == null) ...[
            const SizedBox(height: 8),
            const PermissionsSetting(),
          ],
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build),
                      const SizedBox(width: 12),
                      Text(
                        'Tools',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ToolsSetting(console: selectedConsole),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
