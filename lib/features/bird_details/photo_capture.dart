import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../scanner/scanner_controller.dart';

/// Opens the in-app camera and returns the absolute path of the captured
/// photo (in temporary storage), or null if the user backed out.
///
/// Listening is paused while the camera is open so the microphone and
/// camera never compete, and resumed afterwards.
Future<String?> capturePhoto(BuildContext context, WidgetRef ref) async {
  final scanner = ref.read(scannerControllerProvider.notifier);
  await scanner.pauseForCamera();
  try {
    if (!context.mounted) return null;
    return await context.push<String>('/camera');
  } finally {
    await scanner.resumeAfterCamera();
  }
}
