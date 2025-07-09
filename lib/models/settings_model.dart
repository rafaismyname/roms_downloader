class AppSettings {
  static const String downloadDir = 'downloadDir';
  static const String autoExtract = 'autoExtract';
  static const String maxParallelDownloads = 'maxParallelDownloads';
  static const String maxParallelExtractions = 'maxParallelExtractions';

  static const Map<String, Type> settingsSchema = {
    downloadDir: String,
    autoExtract: bool,
    maxParallelDownloads: int,
    maxParallelExtractions: int,
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
  final bool? autoExtract;
  final int? maxParallelDownloads;
  final int? maxParallelExtractions;

  const BaseSettings({
    this.downloadDir, 
    this.autoExtract,
    this.maxParallelDownloads,
    this.maxParallelExtractions,
  });

  BaseSettings copyWith({
    String? downloadDir, 
    bool? autoExtract,
    int? maxParallelDownloads,
    int? maxParallelExtractions,
  }) {
    return BaseSettings(
      downloadDir: downloadDir == '' ? null : downloadDir ?? this.downloadDir,
      autoExtract: autoExtract ?? this.autoExtract ?? true,
      maxParallelDownloads: maxParallelDownloads ?? this.maxParallelDownloads ?? 5,
      maxParallelExtractions: maxParallelExtractions ?? this.maxParallelExtractions ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppSettings.downloadDir: downloadDir,
      AppSettings.autoExtract: autoExtract,
      AppSettings.maxParallelDownloads: maxParallelDownloads,
      AppSettings.maxParallelExtractions: maxParallelExtractions,
    };
  }

  T? getSetting<T>(String key) {
    switch (key) {
      case AppSettings.downloadDir:
        return downloadDir as T?;
      case AppSettings.autoExtract:
        return autoExtract as T?;
      case AppSettings.maxParallelDownloads:
        return maxParallelDownloads as T?;
      case AppSettings.maxParallelExtractions:
        return maxParallelExtractions as T?;
      default:
        throw ArgumentError('Unknown setting key: $key');
    }
  }

  BaseSettings setSetting<T>(String key, T? value) {
    switch (key) {
      case AppSettings.downloadDir:
        return copyWith(downloadDir: value as String?);
      case AppSettings.autoExtract:
        return copyWith(autoExtract: value as bool?);
      case AppSettings.maxParallelDownloads:
        return copyWith(maxParallelDownloads: value as int?);
      case AppSettings.maxParallelExtractions:
        return copyWith(maxParallelExtractions: value as int?);
      default:
        throw ArgumentError('Unknown setting key: $key');
    }
  }

  factory BaseSettings.fromJson(Map<String, dynamic> json) {
    return BaseSettings(
      downloadDir: json[AppSettings.downloadDir] as String?,
      autoExtract: json[AppSettings.autoExtract] as bool?,
      maxParallelDownloads: json[AppSettings.maxParallelDownloads] as int?,
      maxParallelExtractions: json[AppSettings.maxParallelExtractions] as int?,
    );
  }
}
