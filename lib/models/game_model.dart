import 'package:roms_downloader/models/game_metadata_model.dart';

class Game {
  final String title;
  final String url;
  final int size;
  final String consoleId;
  final GameMetadata? metadata;

  const Game({
    required this.title,
    required this.url,
    required this.size,
    required this.consoleId,
    this.metadata,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: json['title'],
      url: json['url'],
      size: json['size'],
      consoleId: json['consoleId'],
      metadata: json['metadata'] != null ? GameMetadata.fromJson(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'size': size,
      'consoleId': consoleId,
      'metadata': metadata?.toJson(),
    };
  }

  String get filename {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }

  String get taskId => '$consoleId/$filename';

  String get displayTitle => metadata?.normalizedTitle ?? title;

  String get region => metadata?.region ?? metadata?.regions.firstOrNull ?? '';

  String get language => metadata?.language ?? metadata?.languages.firstOrNull ?? '';
}
