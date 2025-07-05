import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/settings_model.dart';
import 'package:roms_downloader/services/settings_service.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

final settingProvider = Provider.family<dynamic, ({String key, String? consoleId})>((ref, params) {
  final settings = ref.watch(settingsProvider);
  if (params.consoleId != null) {
    return settings.consoleSettings[params.consoleId]?.getSetting(params.key) ?? settings.generalSettings.getSetting(params.key);
  }
  return settings.generalSettings.getSetting(params.key);
});

final settingWatcherProvider = Provider.family<Map<String, dynamic>, String>((ref, key) {
  final settings = ref.watch(settingsProvider);
  final result = <String, dynamic>{};

  result['general'] = settings.generalSettings.getSetting(key);

  for (final entry in settings.consoleSettings.entries) {
    result[entry.key] = entry.value.getSetting(key);
  }

  return result;
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _settingsService = SettingsService();

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    state = settings;
  }

  Future<void> setGeneralSetting<T>(String key, T value) async {
    final newState = state.copyWith(
      generalSettings: state.generalSettings.setSetting(key, value),
    );
    state = newState;
    await _settingsService.saveSettings(newState);
  }

  Future<void> setConsoleSetting<T>(String consoleId, String key, T? value) async {
    final currentConsoleSettings = state.consoleSettings[consoleId] ?? const BaseSettings();

    final newState = state.copyWith(
      consoleSettings: {
        ...state.consoleSettings,
        consoleId: currentConsoleSettings.setSetting(key, value),
      },
    );

    state = newState;
    await _settingsService.saveSettings(newState);
  }

  Future<void> setSetting<T>(String key, T value, [String? consoleId]) async {
    if (consoleId != null) {
      await setConsoleSetting(consoleId, key, value);
    } else {
      await setGeneralSetting(key, value);
    }
  }

  T? getGeneralSetting<T>(String key) {
    return _settingsService.getGeneralSetting<T>(state, key);
  }

  T? getConsoleSetting<T>(String consoleId, String key) {
    return _settingsService.getConsoleSetting<T>(state, consoleId, key);
  }

  T? getSetting<T>(String key, [String? consoleId]) {
    return _settingsService.getSetting<T>(state, key, consoleId);
  }

  String getDownloadDir(String? consoleId) {
    return getSetting(AppSettings.downloadDir, consoleId) ?? '';
  }

  bool getAutoExtract(String? consoleId) {
    return getSetting(AppSettings.autoExtract, consoleId) ?? true;
  }

  Future<String?> selectDownloadDirectory() async {
    return await _settingsService.selectDownloadDirectory();
  }
}
