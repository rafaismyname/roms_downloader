enum GameDownloadStatus { ready, queued, downloading, processing, completed, inLibrary, error }

class Game {
  final String title;
  final String url;
  final int size;

  const Game({
    required this.title,
    required this.url,
    required this.size,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: json['title'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'size': size,
    };
  }
}

class Console {
  final String id;
  final String name;
  final String url;
  final String cacheFile;
  final bool filterUsaOnly;
  final bool excludeDemos;

  const Console({
    required this.id,
    required this.name,
    required this.url,
    required this.cacheFile,
    required this.filterUsaOnly,
    required this.excludeDemos,
  });

  Console copyWith({
    String? id,
    String? name,
    String? url,
    String? cacheFile,
    bool? filterUsaOnly,
    bool? excludeDemos,
  }) {
    return Console(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      cacheFile: cacheFile ?? this.cacheFile,
      filterUsaOnly: filterUsaOnly ?? this.filterUsaOnly,
      excludeDemos: excludeDemos ?? this.excludeDemos,
    );
  }

  factory Console.fromJson(Map<String, dynamic> json) {
    return Console(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      cacheFile: json['cache_file'] as String,
      filterUsaOnly: json['filter_usa_only'] as bool,
      excludeDemos: json['exclude_demos'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'cache_file': cacheFile,
      'filter_usa_only': filterUsaOnly,
      'exclude_demos': excludeDemos,
    };
  }
}

class DownloadStats {
  final int totalDownloaded;
  final int totalSize;
  final int downloadSpeed;
  final int activeDownloads;

  const DownloadStats({
    this.totalDownloaded = 0,
    this.totalSize = 0,
    this.downloadSpeed = 0,
    this.activeDownloads = 0,
  });

  DownloadStats copyWith({
    int? totalDownloaded,
    int? totalSize,
    int? downloadSpeed,
    int? activeDownloads,
  }) {
    return DownloadStats(
      totalDownloaded: totalDownloaded ?? this.totalDownloaded,
      totalSize: totalSize ?? this.totalSize,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      activeDownloads: activeDownloads ?? this.activeDownloads,
    );
  }

  factory DownloadStats.fromJson(Map<String, dynamic> json) {
    return DownloadStats(
      totalDownloaded: json['total_downloaded'] as int? ?? 0,
      totalSize: json['total_size'] as int? ?? 0,
      downloadSpeed: json['download_speed'] as int? ?? 0,
      activeDownloads: json['active_downloads'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_downloaded': totalDownloaded,
      'total_size': totalSize,
      'download_speed': downloadSpeed,
      'active_downloads': activeDownloads,
    };
  }
}

class GameDownloadState {
  final GameDownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final int? speed;

  const GameDownloadState({
    this.status = GameDownloadStatus.ready,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speed,
  });

  GameDownloadState copyWith({
    GameDownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    int? speed,
  }) {
    return GameDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speed: speed ?? this.speed,
    );
  }

  factory GameDownloadState.fromJson(Map<String, dynamic> json) {
    return GameDownloadState(
      status: GameDownloadStatus.values[json['status'] as int? ?? 0],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      downloadedBytes: json['downloaded_bytes'] as int? ?? 0,
      totalBytes: json['total_bytes'] as int? ?? 0,
      speed: json['speed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'progress': progress,
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
      'speed': speed,
    };
  }
}

class AppState {
  final List<Game> catalog;
  final List<Console> consoles;
  final Console? selectedConsole;
  final List<int> selectedGames;
  final String downloadDir;
  final String filterText;
  final bool downloading;
  final bool loading;
  final DownloadStats downloadStats;
  final Map<int, GameDownloadState> gameStats;
  final List<bool> gameFileStatus;

  const AppState({
    this.catalog = const [],
    this.consoles = const [],
    this.selectedConsole,
    this.selectedGames = const [],
    this.downloadDir = "",
    this.filterText = "",
    this.downloading = false,
    this.loading = false,
    this.downloadStats = const DownloadStats(),
    this.gameStats = const {},
    this.gameFileStatus = const [],
  });

  AppState copyWith({
    List<Game>? catalog,
    List<Console>? consoles,
    Console? selectedConsole,
    List<int>? selectedGames,
    String? downloadDir,
    String? filterText,
    bool? downloading,
    bool? loading,
    DownloadStats? downloadStats,
    Map<int, GameDownloadState>? gameStats,
    List<bool>? gameFileStatus,
  }) {
    return AppState(
      catalog: catalog ?? this.catalog,
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
      selectedGames: selectedGames ?? this.selectedGames,
      downloadDir: downloadDir ?? this.downloadDir,
      filterText: filterText ?? this.filterText,
      downloading: downloading ?? this.downloading,
      loading: loading ?? this.loading,
      downloadStats: downloadStats ?? this.downloadStats,
      gameStats: gameStats ?? this.gameStats,
      gameFileStatus: gameFileStatus ?? this.gameFileStatus,
    );
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      catalog: (json['catalog'] as List<dynamic>?)?.map((e) => Game.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      consoles: (json['consoles'] as List<dynamic>?)?.map((e) => Console.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      selectedConsole: json['selectedConsole'] != null ? Console.fromJson(json['selectedConsole'] as Map<String, dynamic>) : null,
      selectedGames: (json['selectedGames'] as List<dynamic>?)?.cast<int>() ?? [],
      downloadDir: json['downloadDir'] as String? ?? "",
      filterText: json['filterText'] as String? ?? "",
      downloading: json['downloading'] as bool? ?? false,
      loading: json['loading'] as bool? ?? false,
      downloadStats: json['downloadStats'] != null ? DownloadStats.fromJson(json['downloadStats'] as Map<String, dynamic>) : const DownloadStats(),
      gameStats: (json['gameStats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              int.parse(key),
              GameDownloadState.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      gameFileStatus: (json['gameFileStatus'] as List<dynamic>?)?.cast<bool>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalog': catalog.map((e) => e.toJson()).toList(),
      'consoles': consoles.map((e) => e.toJson()).toList(),
      'selectedConsole': selectedConsole?.toJson(),
      'selectedGames': selectedGames,
      'downloadDir': downloadDir,
      'filterText': filterText,
      'downloading': downloading,
      'loading': loading,
      'downloadStats': downloadStats.toJson(),
      'gameStats': gameStats.map((key, value) => MapEntry(key.toString(), value.toJson())),
      'gameFileStatus': gameFileStatus,
    };
  }
}
