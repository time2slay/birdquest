import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../services/bird_recognition/model_manager.dart';
import '../../../shared/widgets/common.dart';

/// First-run prompt to download the on-device recognition model.
class ModelSetupCard extends ConsumerWidget {
  const ModelSetupCard({super.key, required this.onUseDemo});

  final VoidCallback onUseDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(modelStatusProvider).value;
    final manager = ref.read(modelManagerProvider);
    final sizeMb = (BirdNetModelSpec.totalBytes / 1e6).round();

    return switch (status) {
      null || ModelChecking() || ModelInstalled() => const SizedBox.shrink(),
      ModelDownloading(:final progress, :final receivedBytes) => NoticeCard(
        icon: Icons.downloading_rounded,
        tone: NoticeTone.info,
        title: 'Downloading bird sound model…',
        message:
            '${(receivedBytes / 1e6).toStringAsFixed(1)} of $sizeMb MB. '
            'You can keep using the app.',
        actions: [
          SizedBox(
            width: 280,
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
        ],
      ),
      ModelVerifying() => const NoticeCard(
        icon: Icons.verified_outlined,
        tone: NoticeTone.info,
        title: 'Verifying model…',
        message: 'Checking the download against the published checksum.',
      ),
      ModelFailed(:final message) => NoticeCard(
        icon: Icons.cloud_off_rounded,
        tone: NoticeTone.error,
        title: 'Model download failed',
        message: message,
        actions: [
          FilledButton(
            onPressed: manager.download,
            child: const Text('Try again'),
          ),
        ],
      ),
      ModelNotInstalled(:final remainingBytes)
          when remainingBytes > 0 &&
              remainingBytes < BirdNetModelSpec.totalBytes =>
        NoticeCard(
          icon: Icons.download_for_offline_outlined,
          tone: NoticeTone.info,
          title: 'Model update available',
          message:
              'Download the location filter '
              '(${(remainingBytes / 1e6).toStringAsFixed(1)} MB) to hide '
              'species that do not occur where you are.',
          actions: [
            FilledButton.icon(
              onPressed: manager.download,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download update'),
            ),
          ],
        ),
      ModelNotInstalled() => NoticeCard(
        icon: Icons.download_for_offline_outlined,
        tone: NoticeTone.info,
        title: 'One-time setup: bird sound model',
        message:
            'BirdQuest recognizes birds entirely on your phone. Download the '
            'BirdNET+ models once (about $sizeMb MB, Wi-Fi recommended); after '
            'that, no internet is needed. Your audio never leaves the device.',
        actions: [
          FilledButton.icon(
            onPressed: manager.download,
            icon: const Icon(Icons.download_rounded),
            label: Text('Download ($sizeMb MB)'),
          ),
          TextButton(onPressed: onUseDemo, child: const Text('Try demo mode')),
        ],
      ),
    };
  }
}
