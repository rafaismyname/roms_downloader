import 'package:roms_downloader/models/game_metadata_model.dart';
import 'package:roms_downloader/models/game_details_model.dart';

class Game {
  final String title;
  final String url;
  final int size;
  final String consoleId;
  final GameMetadata? metadata;
  final GameDetails? details;

  const Game({
    required this.title,
    required this.url,
    required this.size,
    required this.consoleId,
    this.metadata,
    this.details,
  });

  Game copyWith({
    String? title,
    String? url,
    int? size,
    String? consoleId,
    GameMetadata? metadata,
    GameDetails? details,
  }) {
    return Game(
      title: title ?? this.title,
      url: url ?? this.url,
      size: size ?? this.size,
      consoleId: consoleId ?? this.consoleId,
      metadata: metadata ?? this.metadata,
      details: details ?? this.details,
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: json['title'],
      url: json['url'],
      size: json['size'],
      consoleId: json['consoleId'],
      metadata: json['metadata'] != null ? GameMetadata.fromJson(json['metadata']) : null,
      details: json['details'] != null ? GameDetails.fromJson(json['details']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'size': size,
      'consoleId': consoleId,
      'metadata': metadata?.toJson(),
      'details': details?.toJson(),
    };
  }

  String get filename {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }

  String get taskId => '$consoleId/$filename';

  String get displayTitle => metadata?.displayTitle ?? title;

  String get region => metadata?.regions.firstOrNull ?? '';

  String get language => metadata?.languages.firstOrNull ?? '';

  String? get boxart => details?.boxart;
}
