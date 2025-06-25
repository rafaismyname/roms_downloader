class Game {
  final String title;
  final String url;
  final int size;
  final String consoleId;

  const Game({
    required this.title,
    required this.url,
    required this.size,
    required this.consoleId,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: json['title'],
      url: json['url'],
      size: json['size'],
      consoleId: json['consoleId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'size': size,
      'consoleId': consoleId,
    };
  }

  String get filename {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }

  String get taskId => '$consoleId/$filename';
}
