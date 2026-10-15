import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'species_guide.dart';

/// Downloads species reference photos from Wikimedia Commons on demand and
/// caches them on the device, so each photo is fetched at most once.
class ReferencePhotoService {
  ReferencePhotoService(this.cacheDir, {this.userAgent, http.Client? client})
    : _client = client ?? http.Client();

  /// Wikimedia requires a User-Agent with contact details; without one the
  /// service only serves already-cached photos.
  final String? userAgent;
  static const width = 800;

  final Directory cacheDir;
  final http.Client _client;
  final _inFlight = <String, Future<File?>>{};

  /// Files that failed this session; not retried until the app restarts.
  final _failed = <String>{};

  File _cacheFile(GuidePhoto photo) {
    final key = sha1.convert(photo.fileName.codeUnits).toString();
    return File(p.join(cacheDir.path, '$key.jpg'));
  }

  /// Cached photo without touching the network.
  Future<File?> cached(GuidePhoto photo) async {
    final f = _cacheFile(photo);
    return await f.exists() ? f : null;
  }

  /// Cached photo, downloading it first if needed. Null when offline or the
  /// download fails.
  Future<File?> get(GuidePhoto photo) {
    final key = photo.fileName;
    if (_failed.contains(key)) return Future.value(null);
    return _inFlight[key] ??= _fetch(photo)
        // Block body: returning the removed future would make whenComplete
        // wait on itself and deadlock.
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }

  Future<File?> _fetch(GuidePhoto photo) async {
    final target = _cacheFile(photo);
    if (await target.exists()) return target;
    final ua = userAgent;
    if (ua == null) return null;
    try {
      final res = await _getFollowingRedirects(
        photo.thumbnailUri(width),
        ua,
      ).timeout(const Duration(seconds: 20));
      final type = res.headers['content-type'] ?? '';
      if (res.statusCode != 200 || !type.startsWith('image/')) {
        debugPrint(
          'Reference photo ${photo.fileName}: HTTP ${res.statusCode} $type',
        );
        _failed.add(photo.fileName);
        return null;
      }
      await cacheDir.create(recursive: true);
      final tmp = File('${target.path}.part');
      await tmp.writeAsBytes(res.bodyBytes, flush: true);
      return await tmp.rename(target.path);
    } catch (e) {
      debugPrint('Reference photo ${photo.fileName}: $e');
      _failed.add(photo.fileName);
      return null;
    }
  }

  /// GET that follows redirects itself: dart:io's automatic redirects drop
  /// the custom User-Agent, and Commons answers that hop with HTTP 403.
  Future<http.Response> _getFollowingRedirects(Uri uri, String ua) async {
    var url = uri;
    for (var hop = 0; ; hop++) {
      final req = http.Request('GET', url)
        ..followRedirects = false
        ..headers['User-Agent'] = ua;
      final res = await http.Response.fromStream(await _client.send(req));
      final location = res.headers['location'];
      if (location == null ||
          res.statusCode < 300 ||
          res.statusCode >= 400 ||
          hop == 5) {
        return res;
      }
      url = url.resolve(location);
    }
  }

  /// Total size of cached photos in bytes.
  Future<int> cacheSize() async {
    if (!await cacheDir.exists()) return 0;
    var total = 0;
    await for (final e in cacheDir.list()) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<void> clearCache() async {
    if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
    _failed.clear();
  }

  void dispose() => _client.close();
}
