import 'package:flutter/material.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/settings_model.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/widgets/settings/directory_setting.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedConsole == null ? 'General Settings' : '${selectedConsole!.name} Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DirectorySetting(
                settingKey: AppSettings.downloadDir,
                title: 'Download Directory',
                icon: Icons.folder_open,
                console: selectedConsole,
                settingsNotifier: settingsNotifier,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
