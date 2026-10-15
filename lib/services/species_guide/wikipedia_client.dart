import 'dart:convert';

import 'package:http/http.dart' as http;

import 'species_guide.dart';

/// Fetches short article intros from Wikipedia (CC BY-SA 4.0).
class WikipediaClient {
  WikipediaClient({this.userAgent, http.Client? client})
    : _client = client ?? http.Client();

  /// Must include contact details (Wikimedia User-Agent policy); null
  /// disables network access.
  final String? userAgent;

  /// Wikipedia's TextExtracts returns at most 20 intros per request.
  static const batchSize = 20;
  static const maxChars = 520;

  final http.Client _client;

  /// Article title -> trimmed plain-text intro, for up to [batchSize] titles.
  Future<Map<String, String>> intros(
    GuideLanguage lang,
    List<String> titles,
  ) async {
    assert(titles.length <= batchSize);
    if (titles.isEmpty) return const {};
    final uri = Uri.https('${lang.name}.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'prop': 'extracts',
      'exintro': '1',
      'explaintext': '1',
      'exlimit': '$batchSize',
      'redirects': '1',
      'titles': titles.join('|'),
    });
    final ua = userAgent;
    if (ua == null) {
      throw const WikipediaException('online species info is not configured');
    }
    http.Response res;
    var attempt = 0;
    while (true) {
      res = await _client
          .get(uri, headers: {'User-Agent': ua})
          .timeout(const Duration(seconds: 30));
      // Rate limited or briefly unavailable: wait as asked, then retry.
      if ((res.statusCode == 429 || res.statusCode == 503) && attempt < 3) {
        final wait = int.tryParse(res.headers['retry-after'] ?? '') ?? 5;
        await Future<void>.delayed(
          Duration(seconds: wait.clamp(1, 60) * (attempt + 1)),
        );
        attempt++;
        continue;
      }
      break;
    }
    if (res.statusCode != 200) {
      throw WikipediaException('HTTP ${res.statusCode}');
    }
    final query =
        (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['query'] as Map? ??
        const {};
    // Map normalized/redirected titles back to the ones we asked for.
    final back = <String, String>{};
    for (final n in [
      ...(query['normalized'] as List? ?? const []),
      ...(query['redirects'] as List? ?? const []),
    ]) {
      final from = n['from'] as String, to = n['to'] as String;
      back[to] = back[from] ?? from;
    }
    final out = <String, String>{};
    for (final p in (query['pages'] as List? ?? const [])) {
      final page = p as Map;
      if (page['missing'] == true) continue;
      final text = trimIntro(page['extract'] as String? ?? '');
      if (text.isEmpty) continue;
      final title = page['title'] as String;
      out[back[title] ?? title] = text;
    }
    return out;
  }

  /// Collapses whitespace, drops Russian stress marks, and cuts at a sentence
  /// boundary near [maxChars].
  static String trimIntro(String raw) {
    final text = raw.replaceAll('́', '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= maxChars) return text;
    final cut = text.substring(0, maxChars);
    final end = [
      cut.lastIndexOf('. '),
      cut.lastIndexOf('! '),
      cut.lastIndexOf('? '),
    ].reduce((a, b) => a > b ? a : b);
    if (end > 200) return cut.substring(0, end + 1);
    final space = cut.lastIndexOf(' ');
    return '${cut.substring(0, space > 0 ? space : cut.length)}…';
  }

  void dispose() => _client.close();
}

class WikipediaException implements Exception {
  const WikipediaException(this.message);
  final String message;

  @override
  String toString() => 'Wikipedia: $message';
}
