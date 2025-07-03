import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/settings_provider.dart';

class BooleanSetting extends ConsumerWidget {
  final String settingKey;
  final bool? defaultValue;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Console? console;
  final SettingsNotifier settingsNotifier;

  const BooleanSetting({
    super.key,
    required this.settingKey,
    this.defaultValue,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.console,
    required this.settingsNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingValue = ref.watch(settingProvider((key: settingKey, consoleId: console?.id))) ?? defaultValue;
    debugPrint('BooleanSetting: $settingKey = $settingValue');
    final isEnabled = settingValue ?? false;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(
        value: isEnabled,
        onChanged: (value) {
          settingsNotifier.setSetting(settingKey, value, console?.id);
        },
      ),
    );
  }
}
