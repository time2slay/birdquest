import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Play/pause control for a recorded bird sound clip.
class ClipPlayer extends StatefulWidget {
  const ClipPlayer({super.key, required this.loadPath, this.label});

  /// Resolves the absolute file path lazily (clips may be written on demand).
  final Future<String?> Function() loadPath;
  final String? label;

  @override
  State<ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends State<ClipPlayer> {
  final _player = AudioPlayer();
  String? _loaded;
  bool _failed = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    try {
      final path = await widget.loadPath();
      if (path == null) return;
      if (path != _loaded) {
        await _player.setFilePath(path);
        _loaded = path;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: context.nature.mossContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snap) {
          final playing =
              (snap.data?.playing ?? false) &&
              snap.data?.processingState != ProcessingState.completed;
          return Row(
            children: [
              IconButton.filled(
                onPressed: _failed ? null : _toggle,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                tooltip: playing ? 'Pause' : 'Play recording',
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label ?? 'Recorded sound',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      _failed
                          ? 'This recording could not be played.'
                          : '3-second clip from your microphone',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, pos) {
                  final d = _player.duration;
                  if (d == null || d.inMilliseconds == 0) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value:
                          (pos.data ?? Duration.zero).inMilliseconds /
                          d.inMilliseconds,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
