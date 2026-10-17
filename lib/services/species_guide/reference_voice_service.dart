import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'commons_http.dart';
import 'species_guide.dart';

/// Downloads reference recordings from Wikimedia Commons when asked (a tap
/// on play, or an Encyclopedia download) and caches them on the device.
class ReferenceVoiceService {
  ReferenceVoiceService(this.cacheDir, {this.userAgent, http.Client? client})
    : _client = client ?? http.Client();

  /// Wikimedia requires a User-Agent with contact details; without one the
  /// service only serves already-cached recordings.
  final String? userAgent;
  final Directory cacheDir;
  final http.Client _client;
  final _inFlight = <String, Future<File?>>{};
  final _failed = <String>{};

  /// Lets recordings that failed earlier this session be downloaded again.
  void forgetFailures() => _failed.clear();

  File _cacheFile(GuideVoice voice) {
    final key = sha1.convert(voice.fileName.codeUnits).toString();
    final ext = p.extension(voice.fileName).toLowerCase();
    return File(p.join(cacheDir.path, '$key$ext'));
  }

  /// Cached recording without touching the network.
  Future<File?> cached(GuideVoice voice) async {
    final f = _cacheFile(voice);
    return await f.exists() ? f : null;
  }

  /// Cached recording, downloading it first if needed. Null when offline or
  /// the download fails.
  Future<File?> get(GuideVoice voice) {
    final key = voice.fileName;
    if (_failed.contains(key)) return Future.value(null);
    return _inFlight[key] ??= _fetch(voice).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  static bool _isAudio(String type) =>
      type.startsWith('audio/') ||
      type.startsWith('application/ogg') ||
      type.startsWith('video/ogg');

  Future<File?> _fetch(GuideVoice voice) async {
    final target = _cacheFile(voice);
    if (await target.exists()) return target;
    final ua = userAgent;
    if (ua == null) return null;
    try {
      final res = await wikimediaGet(
        _client,
        voice.downloadUri,
        ua,
      ).timeout(const Duration(minutes: 3));
      final type = res.headers['content-type'] ?? '';
      if (res.statusCode != 200 || !_isAudio(type)) {
        debugPrint(
          'Reference voice ${voice.fileName}: HTTP ${res.statusCode} $type',
        );
        _failed.add(voice.fileName);
        return null;
      }
      await cacheDir.create(recursive: true);
      final tmp = File('${target.path}.part');
      await tmp.writeAsBytes(res.bodyBytes, flush: true);
      return await tmp.rename(target.path);
    } catch (e) {
      debugPrint('Reference voice ${voice.fileName}: $e');
      _failed.add(voice.fileName);
      return null;
    }
  }

  /// Total size of cached recordings in bytes.
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
