class Favorites {
  final Set<String> gameIds;
  final DateTime lastUpdated;
  final String? exportSlug;
  final DateTime? lastExported;

  const Favorites({
    this.gameIds = const {},
    required this.lastUpdated,
    this.exportSlug,
    this.lastExported,
  });

  Favorites copyWith({
    Set<String>? gameIds,
    DateTime? lastUpdated,
    String? exportSlug,
    DateTime? lastExported,
    bool clearExportSlug = false,
    bool clearLastExported = false,
  }) {
    return Favorites(
      gameIds: gameIds ?? this.gameIds,
      lastUpdated: lastUpdated ?? DateTime.now(),
      exportSlug: clearExportSlug ? null : (exportSlug ?? this.exportSlug),
      lastExported: clearLastExported ? null : (lastExported ?? this.lastExported),
    );
  }

  factory Favorites.fromJson(Map<String, dynamic> json) {
    return Favorites(
      gameIds: Set<String>.from(json['gameIds'] ?? []),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      exportSlug: json['exportSlug'],
      lastExported: json['lastExported'] != null ? DateTime.tryParse(json['lastExported']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameIds': gameIds.toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      if (exportSlug != null) 'exportSlug': exportSlug,
      if (lastExported != null) 'lastExported': lastExported!.toIso8601String(),
    };
  }

  bool isFavorite(String gameId) => gameIds.contains(gameId);
  
  bool get isEmpty => gameIds.isEmpty;
  bool get isNotEmpty => gameIds.isNotEmpty;
  int get count => gameIds.length;
}
