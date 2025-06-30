class AppSettings {
  static const String downloadDir = 'downloadDir';

  static const Map<String, Type> settingsSchema = {
    downloadDir: String,
  };

  final Map<String, BaseSettings> consoleSettings;
  final BaseSettings generalSettings;

  const AppSettings({
    this.consoleSettings = const {},
    this.generalSettings = const BaseSettings(),
  });

  AppSettings copyWith({
    Map<String, BaseSettings>? consoleSettings,
    BaseSettings? generalSettings,
  }) {
    return AppSettings(
      consoleSettings: consoleSettings ?? this.consoleSettings,
      generalSettings: generalSettings ?? this.generalSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consoleSettings': consoleSettings.map((key, value) => MapEntry(key, value.toJson())),
      'generalSettings': generalSettings.toJson(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      consoleSettings: (json['consoleSettings'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, BaseSettings.fromJson(value))) ?? {},
      generalSettings: BaseSettings.fromJson(json['generalSettings'] ?? {}),
    );
  }
}

class BaseSettings {
  final String? downloadDir;

  const BaseSettings({this.downloadDir});

  BaseSettings copyWith({String? downloadDir}) {
    return BaseSettings(
      downloadDir: downloadDir == '' ? null : downloadDir ?? this.downloadDir,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppSettings.downloadDir: downloadDir,
    };
  }

  T? getSetting<T>(String key) {
    switch (key) {
      case AppSettings.downloadDir:
        return downloadDir as T?;
      default:
        throw ArgumentError('Unknown setting key: $key');
    }
  }

  BaseSettings setSetting<T>(String key, T? value) {
    switch (key) {
      case AppSettings.downloadDir:
        return copyWith(downloadDir: value as String?);
      default:
        throw ArgumentError('Unknown setting key: $key');
    }
  }

  factory BaseSettings.fromJson(Map<String, dynamic> json) {
    return BaseSettings(
      downloadDir: json[AppSettings.downloadDir] as String?,
    );
  }
}
