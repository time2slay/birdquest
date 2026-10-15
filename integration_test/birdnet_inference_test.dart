// On-device check of the real recognition pipeline.
//
// Before running, push a 32 kHz mono PCM16 recording of a Common Blackbird
// to the app's external files directory:
//   adb push blackbird.pcm /sdcard/Android/data/com.birdquest.birdquest/files/
// Then: flutter test integration_test/birdnet_inference_test.dart
//
// The test downloads the BirdNET+ model through ModelManager (network
// required) and runs the same classifier + post-processing the app uses.
import 'dart:io';
import 'dart:typed_data';

import 'package:birdquest/services/audio/pcm.dart';
import 'package:birdquest/services/bird_recognition/birdnet_service.dart';
import 'package:birdquest/services/bird_recognition/geo_filter.dart';
import 'package:birdquest/services/bird_recognition/labels.dart';
import 'package:birdquest/services/bird_recognition/model_manager.dart';
import 'package:birdquest/services/bird_recognition/onnx_classifier.dart';
import 'package:birdquest/services/bird_recognition/post_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BirdNET+ identifies a Common Blackbird recording on-device', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final support = await getApplicationSupportDirectory();
      final manager = ModelManager(Directory(p.join(support.path, 'models')));
      if (await manager.refresh() is! ModelInstalled) {
        await manager.download();
      }
      final status = await manager.refresh();
      expect(status, isA<ModelInstalled>(), reason: '${manager.current}');
      status as ModelInstalled;

      final external = await getExternalStorageDirectory();
      final pcmFile = File(p.join(external!.path, 'blackbird.pcm'));
      expect(pcmFile.existsSync(), isTrue, reason: 'push blackbird.pcm first');
      final audio = pcm16ToFloat32(await pcmFile.readAsBytes());

      final labels = parseLabels(await File(status.labelsPath).readAsString());
      final classifier = OnnxClassifier();
      await classifier.load(status.modelPath);

      const window = BirdNetRecognitionService.windowSamples;
      var blackbirdTop = 0, windows = 0;
      final sw = Stopwatch();
      for (var start = 0; start + window <= audio.length; start += window) {
        sw.start();
        final scores = await classifier.classify(
          Float32List.sublistView(audio, start, start + window),
        );
        sw.stop();
        final preds = const PostProcessor().process(scores, labels);
        windows++;
        // ignore: avoid_print
        print(
          'window ${start ~/ 32000}s: '
          '${preds.take(3).map((x) => '${x.species.commonName} ${x.score.toStringAsFixed(3)}').join(', ')}',
        );
        if (preds.isNotEmpty &&
            preds.first.species.scientificName == 'Turdus merula') {
          blackbirdTop++;
        }
      }
      // ignore: avoid_print
      print(
        'avg inference ${sw.elapsedMilliseconds ~/ windows} ms/window; '
        'blackbird top in $blackbirdTop/$windows',
      );
      await classifier.close();
      manager.dispose();

      expect(windows, greaterThan(3));
      expect(blackbirdTop / windows, greaterThanOrEqualTo(0.8));
    });
  });

  testWidgets('geo model keeps the blackbird in Berlin and drops it in India', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final support = await getApplicationSupportDirectory();
      final manager = ModelManager(Directory(p.join(support.path, 'models')));
      if (await manager.refresh() is! ModelInstalled) await manager.download();
      final status = await manager.refresh() as ModelInstalled;
      final labels = parseLabels(await File(status.labelsPath).readAsString());
      final geo = GeoFilter();
      await geo.load(
        status.geoModelPath,
        await File(status.geoLabelsPath).readAsString(),
      );
      final berlin = await geo.rangeFor(
        const GeoContext(latitude: 52.5, longitude: 13.4, week: 40),
        labels,
      );
      final kerala = await geo.rangeFor(
        const GeoContext(latitude: 10.0, longitude: 76.5, week: 40),
        labels,
      );
      // ignore: avoid_print
      print(
        'plausible: Berlin ${berlin.plausibleCount}, Kerala ${kerala.plausibleCount}',
      );
      await geo.close();
      manager.dispose();

      expect(berlin.allows('Turdus merula'), isTrue);
      expect(berlin.allows('Myophonus horsfieldii'), isFalse);
      expect(kerala.allows('Turdus merula'), isFalse);
      expect(kerala.allows('Myophonus horsfieldii'), isTrue);
      expect(berlin.plausibleCount, inInclusiveRange(150, 800));
    });
  });
}
