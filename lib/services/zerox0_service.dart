import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ZeroX0 {
  static const _host = 'https://0x0.st';

  static Future<String> upload<T>(T data, {String? previousRecord, String? filename, bool compress = true}) async {
    try {
      if (previousRecord != null) {
        final parts = previousRecord.split(':');
        if (parts.length == 2) await _deleteInternal(parts[0], parts[1]);
      }

      final payload = compress ? _compress(jsonEncode(data)) : jsonEncode(data);
      final boundary = '----dart_${Random().nextInt(1 << 32)}';
      final actualFilename = filename ?? (compress ? 'data.txt' : 'data.json');

      final bodyData = <int>[];
      final boundaryBytes = utf8.encode('--$boundary\r\n');
      final dispositionBytes = utf8.encode('Content-Disposition: form-data; name="file"; filename="$actualFilename"\r\n');
      final contentTypeBytes = utf8.encode('Content-Type: text/plain\r\n\r\n');
      final payloadBytes = utf8.encode(payload);
      final endBoundaryBytes = utf8.encode('\r\n--$boundary--\r\n');

      bodyData.addAll(boundaryBytes);
      bodyData.addAll(dispositionBytes);
      bodyData.addAll(contentTypeBytes);
      bodyData.addAll(payloadBytes);
      bodyData.addAll(endBoundaryBytes);

      final ua = await buildUserAgent();
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse(_host));
      req.headers
        ..set(HttpHeaders.userAgentHeader, ua)
        ..set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary')
        ..set(HttpHeaders.contentLengthHeader, bodyData.length.toString());
      req.add(bodyData);

      final res = await req.close();

      final responseBody = await utf8.decoder.bind(res).join();
      final loc = res.headers.value('location') ?? responseBody;
      final token = res.headers.value('x-token');
      client.close();

      if (token == null) throw Exception('0x0 upload failed - no token received');

      final slug = Uri.parse(loc.trim()).path.substring(1);
      return '$slug:$token';
    } catch (e) {
      debugPrint('Error uploading to 0x0: $e');
      rethrow;
    }
  }

  static Future<T> download<T>(String record, {bool decompress = true}) async {
    try {
      final slug = record.split(':').first;
      final ua = await buildUserAgent();
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('$_host/$slug'));
      req.headers.set(HttpHeaders.userAgentHeader, ua);
      final res = await req.close();
      if (res.statusCode != 200) throw Exception('0x0 fetch failed');

      final raw = await utf8.decoder.bind(res).join();
      client.close();
      final content = decompress ? _decompress(raw) : raw;
      return jsonDecode(content) as T;
    } catch (e) {
      debugPrint('Error downloading from 0x0: $e');
      rethrow;
    }
  }

  static Future<void> delete(String record) async {
    final parts = record.split(':');
    if (parts.length != 2) throw ArgumentError('record missing token');
    await _deleteInternal(parts[0], parts[1]);
  }

  static Future<void> _deleteInternal(String slug, String token) async {
    final ua = await buildUserAgent();
    final client = HttpClient();
    final url = '$_host/$slug';

    final boundary = '----dart_${Random().nextInt(1 << 32)}';
    final bodyData = <int>[];

    bodyData.addAll(utf8.encode('--$boundary\r\n'));
    bodyData.addAll(utf8.encode('Content-Disposition: form-data; name="token"\r\n\r\n'));
    bodyData.addAll(utf8.encode(token));
    bodyData.addAll(utf8.encode('\r\n--$boundary\r\n'));
    bodyData.addAll(utf8.encode('Content-Disposition: form-data; name="delete"\r\n\r\n'));
    bodyData.addAll(utf8.encode('\r\n--$boundary--\r\n'));

    final req = await client.postUrl(Uri.parse(url));
    req.headers
      ..set(HttpHeaders.userAgentHeader, ua)
      ..set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary')
      ..set(HttpHeaders.contentLengthHeader, bodyData.length.toString());
    req.add(bodyData);

    final res = await req.close();
    final responseBody = await utf8.decoder.bind(res).join();

    client.close();

    if (res.statusCode != 200) {
      throw Exception('0x0 delete failed (${res.statusCode}): $responseBody');
    }
  }

  static String _compress(String json) {
    final gzip = GZipCodec(level: 9);
    return base64UrlEncode(gzip.encode(utf8.encode(json)));
  }

  static String _decompress(String b64) {
    final gzip = GZipCodec();
    return utf8.decode(gzip.decode(base64Url.decode(b64.trim())));
  }

  static Future<String> buildUserAgent() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.appName}/${info.version} (${info.packageName})';
  }
}
