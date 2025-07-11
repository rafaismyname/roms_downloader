class GameDetails {
  final String gameId;
  final String? boxart;

  const GameDetails({
    required this.gameId,
    this.boxart,
  });

  factory GameDetails.fromJson(Map<String, dynamic> json) {
    return GameDetails(
      gameId: json['gameId'],
      boxart: json['boxart'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'boxart': boxart,
    };
  }

  GameDetails copyWith({
    String? gameId,
    String? boxart,
  }) {
    return GameDetails(
      gameId: gameId ?? this.gameId,
      boxart: boxart ?? this.boxart,
    );
  }
}
