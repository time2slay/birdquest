import 'package:http/http.dart' as http;

/// GET from Wikimedia that follows redirects itself: dart:io's automatic
/// redirects drop the custom User-Agent, and Commons answers that hop with
/// HTTP 403. Rate-limited answers (HTTP 429, common for original files on
/// upload.wikimedia.org) are retried after the server's Retry-After.
Future<http.Response> wikimediaGet(
  http.Client client,
  Uri uri,
  String userAgent, {
  int maxRetries = 4,
  Future<void> Function(Duration) wait = Future<void>.delayed,
}) async {
  var url = uri;
  var retries = 0;
  for (var hop = 0; ; hop++) {
    final req = http.Request('GET', url)
      ..followRedirects = false
      ..headers['User-Agent'] = userAgent;
    final res = await http.Response.fromStream(await client.send(req));
    if (res.statusCode == 429 && retries < maxRetries) {
      retries++;
      final after = int.tryParse(res.headers['retry-after'] ?? '') ?? 5;
      await wait(Duration(seconds: after.clamp(1, 30)));
      continue;
    }
    final location = res.headers['location'];
    if (location == null ||
        res.statusCode < 300 ||
        res.statusCode >= 400 ||
        hop >= 5 + retries) {
      return res;
    }
    url = url.resolve(location);
  }
}
