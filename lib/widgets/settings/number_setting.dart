import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/settings_provider.dart';

class NumberSetting extends ConsumerWidget {
  final String settingKey;
  final int defaultValue;
  final String title;
  final String? subtitle;
  final IconData icon;
  final int min;
  final int max;
  final Console? console;
  final SettingsNotifier settingsNotifier;

  const NumberSetting({
    super.key,
    required this.settingKey,
    required this.defaultValue,
    required this.title,
    this.subtitle,
    required this.icon,
    this.min = 1,
    this.max = 100,
    this.console,
    required this.settingsNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentValue = ref.watch(settingProvider((key: settingKey, consoleId: console?.id))) ?? defaultValue;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: SizedBox(
        width: 80,
        child: TextFormField(
          initialValue: currentValue.toString(),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null && intValue >= min && intValue <= max) {
              settingsNotifier.setSetting(settingKey, intValue, console?.id);
            }
          },
        ),
      ),
    );
  }
}
