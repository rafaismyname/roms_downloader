class Console {
  final String id;
  final String name;
  final String url;

  const Console({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Console.fromJson(Map<String, dynamic> json) {
    return Console(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }

  String get cacheFile => 'catalog_$id.json';
}
