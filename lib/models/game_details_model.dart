class GameDetails {
  final String? boxart;

  const GameDetails({
    this.boxart,
  });

  factory GameDetails.fromJson(Map<String, dynamic> json) {
    return GameDetails(
      boxart: json['boxart'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boxart': boxart,
    };
  }

  GameDetails copyWith({
    String? boxart,
  }) {
    return GameDetails(
      boxart: boxart ?? this.boxart,
    );
  }
}
