import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// A downloadable model file with the checksum its authors published.
class ModelFile {
  const ModelFile({
    required this.name,
    required this.url,
    required this.sizeBytes,
    this.md5,
    this.sha256,
  }) : assert(md5 != null || sha256 != null);

  final String name;
  final String url;
  final int sizeBytes;

  /// Zenodo publishes MD5; GitHub releases publish SHA-256.
  final String? md5;
  final String? sha256;
}

/// BirdNET+ V3.0 developer preview, CC BY-SA 4.0.
/// https://zenodo.org/records/20703646
abstract final class BirdNetModelSpec {
  static const name = 'BirdNET+ V3.0-preview3.1 (Global 11K, FP16 pruned)';
  static const license = 'CC BY-SA 4.0';
  static const recordUrl = 'https://zenodo.org/records/20703646';
  static const _base = 'https://zenodo.org/api/records/20703646/files';

  static const model = ModelFile(
    name: 'BirdNET+_V3.0-preview3.1_Global_11K_FP16_pruned.onnx',
    url: '$_base/BirdNET+_V3.0-preview3.1_Global_11K_FP16_pruned.onnx/content',
    sizeBytes: 71528628,
    md5: '8278be6e7d1a9fc1717cf953e269b2e3',
  );

  static const labels = ModelFile(
    name: 'BirdNET+_V3.0-preview3.1_Global_11K_Labels.csv',
    url: '$_base/BirdNET+_V3.0-preview3.1_Global_11K_Labels.csv/content',
    sizeBytes: 809172,
    md5: '21ccf9e984a955bfc2d5c52faab6a6ea',
  );

  static const files = [labels, model, GeoModelSpec.labels, GeoModelSpec.model];
  static int get totalBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);
}

/// BirdNET+ Geomodel V3.0.4: which species occur at a place and week.
/// Apache-2.0. https://github.com/birdnet-team/geomodel/releases/tag/v3.0.4
abstract final class GeoModelSpec {
  static const name = 'BirdNET+ Geomodel V3.0.4 (Global 14K, FP16)';
  static const license = 'Apache 2.0';
  static const releaseUrl =
      'https://github.com/birdnet-team/geomodel/releases/tag/v3.0.4';
  static const _base =
      'https://github.com/birdnet-team/geomodel/releases/download/v3.0.4';

  static const model = ModelFile(
    name: 'BirdNET+_Geomodel_V3.0.4_Global_14K_FP16.onnx',
    url: '$_base/BirdNET%2B_Geomodel_V3.0.4_Global_14K_FP16.onnx',
    sizeBytes: 7885053,
    sha256: '80e410f811bf4455e6cb1a2d48e394737d3828fe943a444646778495b67e7bab',
  );

  static const labels = ModelFile(
    name: 'BirdNET+_Geomodel_V3.0.4_Global_14K_Labels.txt',
    url: '$_base/BirdNET%2B_Geomodel_V3.0.4_Global_14K_Labels.txt',
    sizeBytes: 671823,
    sha256: '8250b457e45d43fc3e77b5cbd06a1d311baf585ab9c51ed8d42e011d98534835',
  );
}

sealed class ModelStatus {
  const ModelStatus();
}

class ModelChecking extends ModelStatus {
  const ModelChecking();
}

class ModelNotInstalled extends ModelStatus {
  const ModelNotInstalled({this.remainingBytes = 0});

  /// Bytes still to download (files already present are skipped).
  final int remainingBytes;
}

class ModelDownloading extends ModelStatus {
  const ModelDownloading(this.receivedBytes, this.totalBytes);
  final int receivedBytes;
  final int totalBytes;
  double get progress => totalBytes == 0 ? 0 : receivedBytes / totalBytes;
}

class ModelVerifying extends ModelStatus {
  const ModelVerifying();
}

class ModelInstalled extends ModelStatus {
  const ModelInstalled(
    this.modelPath,
    this.labelsPath, {
    required this.geoModelPath,
    required this.geoLabelsPath,
  });
  final String modelPath;
  final String labelsPath;
  final String geoModelPath;
  final String geoLabelsPath;
}

class ModelFailed extends ModelStatus {
  const ModelFailed(this.message);
  final String message;
}

/// Downloads, verifies and locates the recognition model files.
///
/// Downloads resume from a `.part` file, and each file is checked against
/// its published size and checksum before it is moved into place.
class ModelManager {
  ModelManager(this.directory, {http.Client? client})
    : _client = client ?? http.Client();

  final Directory directory;
  final http.Client _client;
  final _status = StreamController<ModelStatus>.broadcast();
  ModelStatus _current = const ModelChecking();
  bool _busy = false;

  ModelStatus get current => _current;
  Stream<ModelStatus> get statusStream => _status.stream;

  String _path(ModelFile f) => p.join(directory.path, f.name);

  void _emit(ModelStatus s) {
    _current = s;
    _status.add(s);
  }

  /// Checks whether the files are already installed.
  Future<ModelStatus> refresh() async {
    var remaining = 0;
    for (final f in BirdNetModelSpec.files) {
      final file = File(_path(f));
      if (!await file.exists() || await file.length() != f.sizeBytes) {
        remaining += f.sizeBytes;
      }
    }
    _emit(
      remaining > 0
          ? ModelNotInstalled(remainingBytes: remaining)
          : ModelInstalled(
              _path(BirdNetModelSpec.model),
              _path(BirdNetModelSpec.labels),
              geoModelPath: _path(GeoModelSpec.model),
              geoLabelsPath: _path(GeoModelSpec.labels),
            ),
    );
    return _current;
  }

  Future<void> download() async {
    if (_busy) return;
    _busy = true;
    try {
      await directory.create(recursive: true);
      final total = BirdNetModelSpec.totalBytes;
      var doneBefore = 0;
      for (final f in BirdNetModelSpec.files) {
        final target = File(_path(f));
        if (!(await target.exists() && await target.length() == f.sizeBytes)) {
          await _downloadFile(f, (received) {
            _emit(ModelDownloading(doneBefore + received, total));
          });
        }
        doneBefore += f.sizeBytes;
      }
      await refresh();
    } catch (e) {
      _emit(ModelFailed(_describe(e)));
    } finally {
      _busy = false;
    }
  }

  Future<void> _downloadFile(ModelFile f, void Function(int) onProgress) async {
    final part = File('${_path(f)}.part');
    var existing = await part.exists() ? await part.length() : 0;
    if (existing > f.sizeBytes) {
      await part.delete();
      existing = 0;
    }

    if (existing < f.sizeBytes) {
      final request = http.Request('GET', Uri.parse(f.url));
      if (existing > 0) request.headers['Range'] = 'bytes=$existing-';
      final response = await _client.send(request);
      if (response.statusCode == 200) {
        existing = 0; // Server ignored the range; start over.
      } else if (response.statusCode != 206) {
        throw HttpException('Download failed (HTTP ${response.statusCode})');
      }
      final sink = part.openWrite(
        mode: existing == 0 ? FileMode.write : FileMode.append,
      );
      var received = existing;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(received);
        }
      } finally {
        await sink.close();
      }
    }

    _emit(const ModelVerifying());
    final expected = f.sha256 ?? f.md5!;
    final digest = await (f.sha256 != null ? sha256 : md5)
        .bind(part.openRead())
        .first;
    if (await part.length() != f.sizeBytes || digest.toString() != expected) {
      await part.delete();
      throw const FormatException('Downloaded file failed verification');
    }
    await part.rename(_path(f));
  }

  /// Deletes installed model files, e.g. to free space.
  Future<void> remove() async {
    for (final f in BirdNetModelSpec.files) {
      for (final path in [_path(f), '${_path(f)}.part']) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    await refresh();
  }

  static String _describe(Object e) => switch (e) {
    SocketException() || http.ClientException() =>
      'No internet connection. Connect once to download the model.',
    FormatException() => 'The download was corrupted. Please try again.',
    HttpException(:final message) => message,
    FileSystemException() => 'Not enough storage space for the model.',
    _ => 'Download failed: $e',
  };

  void dispose() {
    _status.close();
    _client.close();
  }
}
