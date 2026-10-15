# BirdQuest

Identify birds by their song, on-device, and keep a personal collection of your encounters.

Flutter · Riverpod · Drift (SQLite) · ONNX Runtime · BirdNET+ V3.0 · Material 3

## Status

| Area | State |
| --- | --- |
| On-device recognition (BirdNET+ V3.0, ONNX) | **Working.** Verified on an arm64 Android 15 phone: real microphone input, about 370 ms per 3 s window |
| First-run model download (81 MB: Zenodo + GitHub; MD5/SHA-256 verified, resumable) | **Working.** Verified on the phone |
| Scanner, grouping, uncertainty labels, permissions | Working |
| Bird details, clip playback, Take Photo (x1/x2/x5 + pinch zoom), Save Discovery | Working |
| Collection, stats, cover photo, history, encounter detail and delete | Working |
| Demo mode | Simulated results, clearly labeled DEMO everywhere |
| Location and season filter (BirdNET+ Geomodel V3.0.4) | **Working.** Verified on the phone: limits results to species plausible at your approximate location this week; toggle under ⋮ or About |
| Day / Night theme | **Working.** Follows the phone by default; sun/moon button in the top bar cycles System → Day → Night (persisted) |
| App icon, splash, empty-state art | Done: adaptive launcher icon, night-aware splash, and day/night illustration sets |
| Licensed reference bird photos | **Not yet.** Labeled placeholder illustrations are used |

## Run

Requires the Flutter SDK (≥ 3.47) and the Android SDK (compileSdk 37). On this machine:

```bash
D:/flutter/bin/flutter pub get
D:/flutter/bin/dart run build_runner build      # Drift codegen
D:/flutter/bin/flutter run                      # connected device
```

On first launch, tap **Download (81 MB)** to install the models, or use **Try demo mode**.

## Tests

```bash
D:/flutter/bin/flutter test                     # 41 unit and widget tests
```

`integration_test/birdnet_inference_test.dart` runs the real model on a device. Before running it, push a 32 kHz mono PCM16 recording, as described in the file header.

## Architecture

```
lib/
  app/            router, providers (Riverpod), app shell
  data/           Drift schema, repositories, media storage, domain models
  services/
    audio/        mic capture (record, unprocessed source), ring buffer, PCM/WAV
    bird_recognition/  BirdRecognitionService boundary, BirdNET (ONNX), demo,
                  model download manager, labels, post-processing
  features/       scanner, bird_details (+ camera), collection, sightings, about
  shared/         theme tokens, Material 3 theme, widgets
```

**Detection vs. encounter vs. species.**
- A *detection* is one model prediction. Detections are logged in `detections` and never counted.
- On the scanner, detections are grouped per species per session into one suggested encounter.
- **Save discovery** writes one row in `sightings`. Saving again in the same session is a no-op unless the user picks *Save as a separate encounter*.
- All collection counts are `COUNT`s over `sightings` and `sighting_photos`, so deleting an encounter corrects the totals immediately.

Photos and clips are stored under the app documents directory (`media/sightings/<id>/`). The database stores only relative paths.

## Licenses

- **Model:** BirdNET+ V3.0 developer preview, **CC BY-SA 4.0**. Commercial use is allowed with attribution and share-alike, but poaching and military use are prohibited (see the Zenodo record 20703646 terms). Attribution is shown in *About & licenses*.
- **Geo model:** BirdNET+ Geomodel V3.0.4, **Apache 2.0** (github.com/birdnet-team/geomodel). It's used only on-device, with an approximate location that is never stored. Species are matched to the audio model by scientific name; birds the geo model does not know are never filtered.
- **Pipeline design:** follows BirdNET Live (MIT).
- **Do not** switch to BirdNET V2.4: its weights are CC BY-NC, which rules out commercial use, including ads.
- **Reference photos:** Cornell / Macaulay species images are mostly NC or ©, so none are bundled.
- **UI artwork:** the app icon, empty-state illustrations (day and night) and the topographic texture in `assets/` were generated for BirdQuest with Google Flow (Nano Banana 2.1). They are decorative and never depict a specific species.
