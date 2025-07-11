import 'package:roms_downloader/models/game_model.dart';

enum GameStatus {
  init,
  loading,
  ready,
  downloadQueued,
  downloading,
  downloadPaused,
  downloaded,
  extractionQueued,
  extracting,
  extracted,
  downloadFailed,
  extractionFailed,
  processing,
  error,
}

enum GameAction {
  download,
  pause,
  resume,
  cancel,
  extract,
  retryDownload,
  retryExtraction,
  loading,
  none,
}

class GameState {
  final Game game;
  final GameStatus status;
  final double downloadProgress;
  final double extractionProgress;
  final double networkSpeed;
  final Duration timeRemaining;
  final bool isSelected;
  final bool isInteractable;
  final Set<GameAction> availableActions;
  final bool showProgressBar;
  final double currentProgress;
  final String? errorMessage;
  final bool fileExists;
  final bool extractedContentExists;

  const GameState({
    required this.game,
    this.status = GameStatus.init,
    this.downloadProgress = 0.0,
    this.extractionProgress = 0.0,
    this.networkSpeed = 0.0,
    this.timeRemaining = Duration.zero,
    this.isSelected = false,
    this.isInteractable = true,
    this.availableActions = const {GameAction.loading},
    this.showProgressBar = false,
    this.currentProgress = 0.0,
    this.errorMessage,
    this.fileExists = false,
    this.extractedContentExists = false,
  });

  GameState copyWith({
    GameStatus? status,
    double? downloadProgress,
    double? extractionProgress,
    double? networkSpeed,
    Duration? timeRemaining,
    bool? isSelected,
    bool? isInteractable,
    Set<GameAction>? availableActions,
    bool? showProgressBar,
    double? currentProgress,
    String? errorMessage,
    bool? fileExists,
    bool? extractedContentExists,
  }) {
    return GameState(
      game: game,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isSelected: isSelected ?? this.isSelected,
      isInteractable: isInteractable ?? this.isInteractable,
      availableActions: availableActions ?? this.availableActions,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      currentProgress: currentProgress ?? this.currentProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      fileExists: fileExists ?? this.fileExists,
      extractedContentExists: extractedContentExists ?? this.extractedContentExists,
    );
  }

  String get statusText {
    switch (status) {
      case GameStatus.init:
      case GameStatus.loading:
        return 'Loading';
      case GameStatus.ready:
        return 'Ready';
      case GameStatus.downloadQueued:
        return 'Dl. Queued';
      case GameStatus.downloading:
        return 'Downloading';
      case GameStatus.downloadPaused:
        return 'Paused';
      case GameStatus.downloaded:
        return 'Downloaded';
      case GameStatus.extractionQueued:
        return 'Ex. Queued';
      case GameStatus.extracting:
        return 'Extracting';
      case GameStatus.extracted:
        return 'Extracted';
      case GameStatus.downloadFailed:
        return 'Download Failed';
      case GameStatus.extractionFailed:
        return 'Extraction Failed';
      case GameStatus.processing:
        return 'Processing';
      case GameStatus.error:
        return 'Error';
    }
  }

  bool get isActive {
    return status == GameStatus.downloading ||
        status == GameStatus.extracting ||
        status == GameStatus.downloadQueued ||
        status == GameStatus.extractionQueued ||
        status == GameStatus.processing;
  }

  bool get hasError {
    return status == GameStatus.downloadFailed || status == GameStatus.extractionFailed;
  }
}
