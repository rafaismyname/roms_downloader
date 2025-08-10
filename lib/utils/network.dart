import 'dart:math';

Map<String, String> buildDownloadHeaders(String url, [Map<String, String>? extra]) {
  final rand = Random();
  final Map<String, String> uaPerHost = {};
  const languages = [
    'en-US,en;q=0.9',
    'en-GB,en;q=0.9',
    'en-US,en;q=0.8,es;q=0.6',
    'en-US,en;q=0.9,de;q=0.7',
    'en-US,en;q=0.9,pt;q=0.8,gl;q=0.7,es;q=0.6',
  ];
  const platforms = ['"Windows"', '"macOS"', '"Linux"'];
  String randomChromeUA() {
    final major = 135 + rand.nextInt(5);
    final build = 0 + rand.nextInt(10);
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/'
        '$major.0.$build.0 Safari/537.36';
  }

  String randomFirefoxUA() {
    final major = 125 + rand.nextInt(4);
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:$major.0) Gecko/20100101 Firefox/$major.0';
  }

  String randomSafariUA() {
    final major = 17;
    final minor = 0 + rand.nextInt(6);
    return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/'
        '$major.$minor Safari/605.1.15';
  }

  String uaForHost(String host) => uaPerHost.putIfAbsent(host, () {
        final pick = rand.nextInt(100);
        if (pick < 55) return randomChromeUA();
        if (pick < 80) return randomFirefoxUA();
        return randomSafariUA();
      });
  String randomSecChUa() {
    final chromeVer = 135 + rand.nextInt(5);
    return '"Not)A;Brand";v="8", "Chromium";v="$chromeVer", "Google Chrome";v="$chromeVer"';
  }

  String randomSecChUaMobile() => rand.nextBool() ? '?0' : '?1';
  String randomSecChUaPlatform() => platforms[rand.nextInt(platforms.length)];
  String randomSecFetchSite() => rand.nextInt(10) < 8 ? 'same-origin' : 'none';
  final host = Uri.tryParse(url)?.host ?? 'localhost';

  return {
    'User-Agent': uaForHost(host),
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': languages[rand.nextInt(languages.length)],
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Connection': 'keep-alive',
    'Pragma': 'no-cache',
    'Cache-Control': 'no-cache',
    'Host': host,
    'Referer': 'https://$host/',
    'sec-ch-ua': randomSecChUa(),
    'sec-ch-ua-mobile': randomSecChUaMobile(),
    'sec-ch-ua-platform': randomSecChUaPlatform(),
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': randomSecFetchSite(),
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    if (extra != null) ...extra,
  };
}
