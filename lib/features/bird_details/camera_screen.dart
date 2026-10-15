import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../app/providers.dart';
import '../../shared/theme/tokens.dart';

/// Full-screen camera. Pops with the absolute path of the captured photo.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  String? _error;
  bool _permanentlyDenied = false;
  bool _capturing = false;
  FlashMode _flash = FlashMode.off;
  double _minZoom = 1, _maxZoom = 1, _zoom = 1, _pinchStartZoom = 1;

  /// Quick zoom presets; only those the lens supports are shown.
  static const _zoomPresets = [1.0, 2.0, 5.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      c.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _open(_cameraIndex);
    }
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _permanentlyDenied = status.isPermanentlyDenied;
        _error = 'Camera access is needed to photograph birds.';
      });
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final back = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      await _open(back < 0 ? 0 : back);
    } on CameraException catch (e) {
      setState(() => _error = 'Camera unavailable: ${e.description ?? e.code}');
    }
  }

  Future<void> _open(int index) async {
    final old = _controller;
    _controller = null;
    await old?.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      await controller.setFlashMode(_flash);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraIndex = index;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoom = 1.0.clamp(minZoom, maxZoom);
        _error = null;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(
          () => _error = 'Camera unavailable: ${e.description ?? e.code}',
        );
      }
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _capturing || !c.value.isInitialized) return;
    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();
    try {
      final shot = await c.takePicture();
      final dir = Directory(
        p.join(ref.read(appPathsProvider).tempDir.path, 'photos'),
      );
      await dir.create(recursive: true);
      final target = p.join(
        dir.path,
        'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(shot.path).copy(target);
      await File(shot.path).delete().catchError((_) => File(shot.path));
      if (mounted) Navigator.of(context).pop(target);
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not take photo: ${e.description}')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _setZoom(double value) async {
    final c = _controller;
    if (c == null) return;
    final z = value.clamp(_minZoom, _maxZoom);
    setState(() => _zoom = z);
    try {
      await c.setZoomLevel(z);
    } on CameraException {
      // Ignore; the preview keeps its previous zoom.
    }
  }

  Future<void> _toggleFlash() async {
    final next = _flash == FlashMode.off ? FlashMode.auto : FlashMode.off;
    await _controller?.setFlashMode(next);
    setState(() => _flash = next);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && c.value.isInitialized)
            GestureDetector(
              onScaleStart: (_) => _pinchStartZoom = _zoom,
              onScaleUpdate: (d) {
                if (d.pointerCount > 1) _setZoom(_pinchStartZoom * d.scale);
              },
              child: Center(child: CameraPreview(c)),
            )
          else if (_error != null)
            _CameraError(
              message: _error!,
              permanentlyDenied: _permanentlyDenied,
              onRetry: _init,
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close camera',
                    ),
                    if (c != null)
                      IconButton.filledTonal(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          _flash == FlashMode.off
                              ? Icons.flash_off_rounded
                              : Icons.flash_auto_rounded,
                        ),
                        tooltip: 'Flash',
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (c != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ZoomSelector(
                        presets: [
                          for (final z in _zoomPresets)
                            if (z >= _minZoom && z <= _maxZoom) z,
                        ],
                        current: _zoom,
                        onSelected: _setZoom,
                      ),
                      const SizedBox(height: Space.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 48),
                          GestureDetector(
                            onTap: _capture,
                            child: Semantics(
                              button: true,
                              label: 'Take photo',
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(5),
                                child: AnimatedContainer(
                                  duration: Motion.fast,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _capturing
                                        ? Colors.white54
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: _cameras.length > 1
                                ? IconButton.filledTonal(
                                    onPressed: () => _open(
                                      (_cameraIndex + 1) % _cameras.length,
                                    ),
                                    icon: const Icon(
                                      Icons.cameraswitch_rounded,
                                    ),
                                    tooltip: 'Switch camera',
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({
    required this.message,
    required this.permanentlyDenied,
    required this.onRetry,
  });

  final String message;
  final bool permanentlyDenied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: Space.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: permanentlyDenied ? openAppSettings : onRetry,
              child: Text(permanentlyDenied ? 'Open settings' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// x1 / x2 / x5 quick zoom chips, like the system camera.
class _ZoomSelector extends StatelessWidget {
  const _ZoomSelector({
    required this.presets,
    required this.current,
    required this.onSelected,
  });

  final List<double> presets;
  final double current;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    if (presets.length < 2) return const SizedBox.shrink();
    // Highlight the largest preset not above the current zoom.
    final active = presets.lastWhere(
      (z) => z <= current + 0.05,
      orElse: () => presets.first,
    );
    final exact = (current - active).abs() < 0.05;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final z in presets)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                button: true,
                selected: z == active,
                label: 'Zoom ${z.toStringAsFixed(0)} times',
                child: GestureDetector(
                  onTap: () => onSelected(z),
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    width: z == active ? 48 : 40,
                    height: z == active ? 48 : 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: z == active ? Colors.white24 : Colors.transparent,
                    ),
                    child: Text(
                      z == active && !exact
                          ? '${current.toStringAsFixed(1)}×'
                          : '${z.toStringAsFixed(0)}×',
                      style: TextStyle(
                        color: z == active
                            ? const Color(0xFFF5E7C4)
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: z == active ? 14 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
