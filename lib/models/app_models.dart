import 'package:background_downloader/background_downloader.dart';

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

  factory Console.fromJson(Map<String, dynamic> json) {
    return Console(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      cacheFile: json['cacheFile'],
      filterUsaOnly: json['filterUsaOnly'],
      excludeDemos: json['excludeDemos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'cacheFile': cacheFile,
      'filterUsaOnly': filterUsaOnly,
      'excludeDemos': excludeDemos,
    };
  }
}

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
      title: json['title'],
      url: json['url'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'size': size,
    };
  }

  String get filename {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }

  String taskId(String consoleId) => '$consoleId/$filename';
}

class AppState {
  final List<Console> consoles;
  final Console? selectedConsole;
  final List<Game> catalog;
  final String filterText;
  final bool loading;
  final bool downloading;
  final String downloadDir;
  final Map<String, TaskStatus> taskStatus;
  final Map<String, double> taskProgress;
  final Set<String> selectedTasks;
  final Set<String> completedTasks;

  const AppState({
    this.consoles = const [],
    this.selectedConsole,
    this.catalog = const [],
    this.filterText = '',
    this.loading = false,
    this.downloading = false,
    this.downloadDir = '',
    this.taskStatus = const {},
    this.taskProgress = const {},
    this.selectedTasks = const {},
    this.completedTasks = const {},
  });

  AppState copyWith({
    List<Console>? consoles,
    Console? selectedConsole,
    List<Game>? catalog,
    String? filterText,
    bool? loading,
    bool? downloading,
    String? downloadDir,
    Map<String, TaskStatus>? taskStatus,
    Map<String, double>? taskProgress,
    Set<String>? selectedTasks,
    Set<String>? completedTasks,
  }) {
    return AppState(
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
      catalog: catalog ?? this.catalog,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      downloading: downloading ?? this.downloading,
      downloadDir: downloadDir ?? this.downloadDir,
      taskStatus: taskStatus ?? this.taskStatus,
      taskProgress: taskProgress ?? this.taskProgress,
      selectedTasks: selectedTasks ?? this.selectedTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  List<Game> get filteredCatalog {
    if (filterText.isEmpty) return catalog;
    return catalog.where((game) => game.title.toLowerCase().contains(filterText.toLowerCase())).toList();
  }

  List<int> get selectedGames {
    return selectedTasks
        .map((taskId) {
          final filename = taskId.split('/').last;
          return catalog.indexWhere((game) => game.filename == filename);
        })
        .where((index) => index != -1)
        .toList();
  }

  List<bool> get gameFileStatus {
    return catalog.map((game) => completedTasks.contains(game.taskId(selectedConsole?.id ?? ''))).toList();
  }
}
