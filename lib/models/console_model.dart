class Console {
  final String id;
  final String name;
  final String url;
  final String cacheFile;

  const Console({
    required this.id,
    required this.name,
    required this.url,
    required this.cacheFile,
  });

  factory Console.fromJson(Map<String, dynamic> json) {
    return Console(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      cacheFile: json['cacheFile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'cacheFile': cacheFile,
    };
  }
}
