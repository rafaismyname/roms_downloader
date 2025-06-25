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
