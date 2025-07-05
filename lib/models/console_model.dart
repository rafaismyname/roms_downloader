class Console {
  final String id;
  final String name;
  final String url;
  final String? regex;

  const Console({required this.id, required this.name, required this.url, this.regex});

  factory Console.fromJson(Map<String, dynamic> json) {
    return Console(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      regex: json['regex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'regex': regex,
    };
  }

  // Regex groups: url, title, text, size
  // Defautl Format: <tr><td class="link"><a href="URL" title="TITLE">TEXT</a></td><td class="size">SIZE</td>...
  String get defaultRegex =>
      '<tr><td class="link"><a href="(?<href>[^"]+)" title="(?<title>[^"]+)">(?<text>[^<]+)</a></td><td class="size">(?<size>[^<]+)</td><td class="date">[^<]*</td></tr>';

  String get cacheFile => 'catalog_$id.json';
}
