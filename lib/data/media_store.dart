import 'dart:io';

import 'package:path/path.dart' as p;

/// App-managed storage for user photos and sound clips.
///
/// The database stores paths relative to [root] so the media survives app
/// updates that move the documents directory.
class MediaStore {
  MediaStore(this.root);

  final Directory root;

  String absolute(String relativePath) => p.join(root.path, relativePath);

  File file(String relativePath) => File(absolute(relativePath));

  String _sightingDir(int sightingId) => p.join('sightings', '$sightingId');

  /// Copies a captured photo into the sighting's folder and returns the
  /// relative path to store in the database.
  Future<String> importPhoto(String sourcePath, int sightingId) {
    final ext = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final name = 'photo_${DateTime.now().microsecondsSinceEpoch}$ext';
    return _import(sourcePath, p.join(_sightingDir(sightingId), name));
  }

  /// Copies a recorded clip into the sighting's folder.
  Future<String> importClip(String sourcePath, int sightingId) =>
      _import(sourcePath, p.join(_sightingDir(sightingId), 'clip.wav'));

  Future<String> _import(String sourcePath, String relative) async {
    final target = File(absolute(relative));
    await target.parent.create(recursive: true);
    await File(sourcePath).copy(target.path);
    return relative;
  }

  Future<void> deleteFile(String relativePath) async {
    final f = file(relativePath);
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteSightingMedia(int sightingId) async {
    final dir = Directory(absolute(_sightingDir(sightingId)));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
