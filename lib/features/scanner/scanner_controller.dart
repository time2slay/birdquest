import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../services/audio/wav_writer.dart';
import '../../services/bird_recognition/bird_recognition_service.dart';
import '../../services/bird_recognition/field_notes.dart';

enum ScannerStatus { idle, starting, listening, paused }

/// All detections of one species during one listening session, which the
/// user can confirm as a single encounter.
class DetectionGroup {
  const DetectionGroup({
    required this.species,
    required this.bestScore,
    required this.lastScore,
    required this.hits,
    required this.firstHeard,
    required this.lastHeard,
    this.bestWindow,
    this.sampleRate = 32000,
    this.clipPath,
    this.pendingPhotos = const [],
    this.savedSightingIds = const [],
  });

  final SpeciesInfo species;
  final double bestScore;
  final double lastScore;

  /// Number of model detections grouped into this suggested encounter.
  final int hits;
  final DateTime firstHeard;
  final DateTime lastHeard;

  /// Audio window that produced [bestScore], kept in memory until saved.
  final Float32List? bestWindow;
  final int sampleRate;

  /// Temporary WAV of [bestWindow], written on demand.
  final String? clipPath;

  /// Photos taken before the encounter was saved (absolute temp paths).
  final List<String> pendingPhotos;

  /// Sightings saved from this group. Usually zero or one; more if the user
  /// explicitly saved separate encounters.
  final List<int> savedSightingIds;

  String get key => species.scientificName;
  bool get isUncertain => bestScore < kUncertainBelow;
  bool get isSaved => savedSightingIds.isNotEmpty;
  bool get hasAudio => bestWindow != null || clipPath != null;

  DetectionGroup copyWith({
    double? bestScore,
    double? lastScore,
    int? hits,
    DateTime? lastHeard,
    Float32List? bestWindow,
    String? clipPath,
    bool clearClip = false,
    List<String>? pendingPhotos,
    List<int>? savedSightingIds,
  }) => DetectionGroup(
    species: species,
    bestScore: bestScore ?? this.bestScore,
    lastScore: lastScore ?? this.lastScore,
    hits: hits ?? this.hits,
    firstHeard: firstHeard,
    lastHeard: lastHeard ?? this.lastHeard,
    bestWindow: bestWindow ?? this.bestWindow,
    sampleRate: sampleRate,
    clipPath: clearClip ? null : (clipPath ?? this.clipPath),
    pendingPhotos: pendingPhotos ?? this.pendingPhotos,
    savedSightingIds: savedSightingIds ?? this.savedSightingIds,
  );
}

class ScannerState {
  const ScannerState({
    this.status = ScannerStatus.idle,
    this.isDemo = false,
    this.sessionId,
    this.groups = const {},
    this.levels = const [],
    this.windowsAnalyzed = 0,
    this.error,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
    this.modelMissing = false,
    this.geoFilter,
  });

  final ScannerStatus status;
  final bool isDemo;
  final int? sessionId;
  final Map<String, DetectionGroup> groups;

  /// Recent input levels (0..1), oldest first, for the waveform.
  final List<double> levels;
  final int windowsAnalyzed;
  final String? error;
  final bool permissionDenied;
  final bool permanentlyDenied;
  final bool modelMissing;

  /// Location filter state reported by the recognizer (null for demo mode).
  final GeoFilterState? geoFilter;

  bool get isListening => status == ScannerStatus.listening;
  bool get isBusy =>
      status == ScannerStatus.listening || status == ScannerStatus.starting;

  /// Groups ordered by confidence, then recency.
  List<DetectionGroup> get sortedGroups => groups.values.toList()
    ..sort((a, b) {
      final c = b.bestScore.compareTo(a.bestScore);
      return c != 0 ? c : b.lastHeard.compareTo(a.lastHeard);
    });

  ScannerState copyWith({
    ScannerStatus? status,
    bool? isDemo,
    int? sessionId,
    bool clearSession = false,
    Map<String, DetectionGroup>? groups,
    List<double>? levels,
    int? windowsAnalyzed,
    String? error,
    bool clearError = false,
    bool? permissionDenied,
    bool? permanentlyDenied,
    bool? modelMissing,
    GeoFilterState? geoFilter,
    bool clearGeoFilter = false,
  }) => ScannerState(
    status: status ?? this.status,
    isDemo: isDemo ?? this.isDemo,
    sessionId: clearSession ? null : (sessionId ?? this.sessionId),
    groups: groups ?? this.groups,
    levels: levels ?? this.levels,
    windowsAnalyzed: windowsAnalyzed ?? this.windowsAnalyzed,
    error: clearError ? null : (error ?? this.error),
    permissionDenied: permissionDenied ?? this.permissionDenied,
    permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
    modelMissing: modelMissing ?? this.modelMissing,
    geoFilter: clearGeoFilter ? null : (geoFilter ?? this.geoFilter),
  );
}

/// Drives a listening session: starts/stops the recognizer, groups repeated
/// detections per species, and turns a group into a confirmed encounter
/// when the user saves it.
class ScannerController extends Notifier<ScannerState> {
  static const _levelHistory = 48;

  StreamSubscription<RecognitionEvent>? _sub;
  BirdRecognitionService? _service;
  bool _resumeAfterCamera = false;

  @override
  ScannerState build() {
    ref.onDispose(() => _sub?.cancel());
    return ScannerState(isDemo: ref.read(demoModeProvider));
  }

  Future<void> start() async {
    if (state.isBusy) return;
    final isDemo = ref.read(demoModeProvider);
    state = state.copyWith(
      status: ScannerStatus.starting,
      clearError: true,
      permissionDenied: false,
      permanentlyDenied: false,
      modelMissing: false,
      clearGeoFilter: true,
    );
    // Switching between demo and real recognition always begins a new session.
    if (state.sessionId != null && state.isDemo != isDemo) _resetGroups();

    final service = ref.read(recognitionServiceProvider);
    _service = service;
    try {
      final events = await service.start();
      final repo = ref.read(sightingRepositoryProvider);
      final sessionId =
          state.sessionId ??
          await repo.startSession(startedAt: DateTime.now(), isDemo: isDemo);
      state = state.copyWith(
        status: ScannerStatus.listening,
        sessionId: sessionId,
        isDemo: isDemo,
      );
      _sub = events.listen(_onEvent, onDone: _onStreamDone);
    } on MicrophonePermissionException catch (e) {
      state = state.copyWith(
        status: ScannerStatus.idle,
        permissionDenied: true,
        permanentlyDenied: e.permanentlyDenied,
      );
    } on ModelNotInstalledException {
      state = state.copyWith(status: ScannerStatus.idle, modelMissing: true);
    } catch (e) {
      await service.stop();
      state = state.copyWith(
        status: ScannerStatus.idle,
        error: 'Could not start listening. $e',
      );
    }
  }

  Future<void> stop() async {
    await _stopService();
    state = state.copyWith(status: ScannerStatus.idle, levels: const []);
    final id = state.sessionId;
    if (id != null) {
      await ref.read(sightingRepositoryProvider).endSession(id, DateTime.now());
    }
  }

  Future<void> _stopService() async {
    await _sub?.cancel();
    _sub = null;
    await _service?.stop();
  }

  void _onStreamDone() {
    if (state.status == ScannerStatus.listening) {
      state = state.copyWith(status: ScannerStatus.idle, levels: const []);
    }
  }

  /// Releases the microphone while the camera is open.
  Future<void> pauseForCamera() async {
    _resumeAfterCamera = state.isListening;
    if (_resumeAfterCamera) {
      await _stopService();
      state = state.copyWith(status: ScannerStatus.paused, levels: const []);
    }
  }

  Future<void> resumeAfterCamera() async {
    if (!_resumeAfterCamera) return;
    _resumeAfterCamera = false;
    state = state.copyWith(status: ScannerStatus.idle);
    await start();
  }

  /// Clears the current results and starts a fresh session next time.
  Future<void> newSession() async {
    if (state.isBusy || state.status == ScannerStatus.paused) await stop();
    _resetGroups();
  }

  void _resetGroups() {
    state = state.copyWith(
      groups: const {},
      clearSession: true,
      windowsAnalyzed: 0,
      clearError: true,
    );
  }

  void _onEvent(RecognitionEvent event) {
    switch (event) {
      case AudioLevelEvent(:final level):
        final levels = [...state.levels, level];
        state = state.copyWith(
          levels: levels.length > _levelHistory
              ? levels.sublist(levels.length - _levelHistory)
              : levels,
        );
      case PredictionEvent():
        _onPredictions(event);
      case GeoFilterEvent(state: final geo):
        state = state.copyWith(
          geoFilter: geo,
          groups: geo is GeoFilterActive ? _prune(geo.allows) : null,
        );
      case RecognitionErrorEvent(:final message):
        state = state.copyWith(error: message);
    }
  }

  /// Drops suggestions the location filter rules out. Groups the user has
  /// saved or photographed are kept.
  Map<String, DetectionGroup> _prune(bool Function(String) allows) => {
    for (final e in state.groups.entries)
      if (allows(e.key) || e.value.isSaved || e.value.pendingPhotos.isNotEmpty)
        e.key: e.value,
  };

  void _onPredictions(PredictionEvent event) {
    final groups = Map.of(state.groups);
    for (final pr in event.predictions) {
      final existing = groups[pr.species.scientificName];
      if (existing == null) {
        groups[pr.species.scientificName] = DetectionGroup(
          species: pr.species,
          bestScore: pr.score,
          lastScore: pr.score,
          hits: 1,
          firstHeard: event.at,
          lastHeard: event.at,
          bestWindow: event.window,
          sampleRate: event.sampleRate,
        );
      } else {
        final better = pr.score > existing.bestScore;
        groups[existing.key] = existing.copyWith(
          hits: existing.hits + 1,
          lastScore: pr.score,
          lastHeard: event.at,
          bestScore: better ? pr.score : null,
          bestWindow: better ? event.window : null,
          clearClip: better && event.window != null,
        );
      }
    }
    state = state.copyWith(
      groups: groups,
      windowsAnalyzed: state.windowsAnalyzed + 1,
    );

    final sessionId = state.sessionId;
    if (sessionId != null && event.predictions.isNotEmpty) {
      unawaited(
        ref
            .read(sightingRepositoryProvider)
            .recordDetections(sessionId, [
              for (final pr in event.predictions)
                (species: pr.species, at: event.at, score: pr.score),
            ])
            .catchError((Object _) {}),
      );
    }
  }

  void _updateGroup(String key, DetectionGroup Function(DetectionGroup) f) {
    final g = state.groups[key];
    if (g == null) return;
    state = state.copyWith(groups: {...state.groups, key: f(g)});
  }

  /// Writes the best audio window of a group to a temporary WAV file.
  Future<String?> ensureClip(String key) async {
    final g = state.groups[key];
    if (g == null) return null;
    if (g.clipPath != null) return g.clipPath;
    final window = g.bestWindow;
    if (window == null) return null;
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    final path = p.join(
      ref.read(appPathsProvider).tempDir.path,
      'clips',
      'session_${state.sessionId}_${safe}_${g.hits}.wav',
    );
    await writeWav(
      path,
      normalizeForPlayback(window),
      sampleRate: g.sampleRate,
    );
    _updateGroup(key, (g) => g.copyWith(clipPath: path));
    return path;
  }

  void addPendingPhoto(String key, String path) => _updateGroup(
    key,
    (g) => g.copyWith(pendingPhotos: [...g.pendingPhotos, path]),
  );

  void removePendingPhoto(String key, String path) => _updateGroup(
    key,
    (g) => g.copyWith(
      pendingPhotos: g.pendingPhotos.where((x) => x != path).toList(),
    ),
  );

  /// Confirms a group as an encounter. Returns the new sighting id.
  ///
  /// By default each species is saved at most once per session; pass
  /// [separate] to deliberately record an additional encounter.
  Future<int> saveEncounter(
    String key, {
    bool separate = false,
    double? latitude,
    double? longitude,
    String? notes,
    String? rarity,
  }) async {
    final g = state.groups[key];
    if (g == null) throw StateError('Unknown detection group $key');
    if (g.isSaved && !separate) return g.savedSightingIds.last;

    final clip = await ensureClip(key);
    final species = SpeciesInfo(
      scientificName: g.species.scientificName,
      commonName: g.species.commonName,
      taxonOrder: g.species.taxonOrder,
      modelLabelId: g.species.modelLabelId,
      description:
          g.species.description ?? fieldNoteFor(g.species.scientificName),
    );
    final id = await ref
        .read(sightingRepositoryProvider)
        .saveEncounter(
          EncounterDraft(
            species: species,
            confirmedAt: DateTime.now(),
            sessionId: state.sessionId,
            modelScore: g.bestScore,
            clipPath: clip,
            photoPaths: g.pendingPhotos,
            latitude: latitude,
            longitude: longitude,
            notes: notes,
            isDemo: state.isDemo,
            rarity: rarity,
          ),
        );
    _updateGroup(
      key,
      (g) => g.copyWith(
        pendingPhotos: const [],
        savedSightingIds: [...g.savedSightingIds, id],
      ),
    );
    return id;
  }
}

final scannerControllerProvider =
    NotifierProvider<ScannerController, ScannerState>(ScannerController.new);
