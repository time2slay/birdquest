import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Play/pause control for a recorded bird sound clip.
class ClipPlayer extends StatefulWidget {
  const ClipPlayer({
    super.key,
    required this.loadPath,
    this.label,
    this.subtitle,
    this.onInfo,
  });

  /// Resolves the absolute file path lazily (clips may be written or
  /// downloaded on demand).
  final Future<String?> Function() loadPath;
  final String? label;

  /// Second line; defaults to the microphone-clip description.
  final String? subtitle;

  /// Shows an info button (e.g. attribution) when set.
  final VoidCallback? onInfo;

  @override
  State<ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends State<ClipPlayer> {
  final _player = AudioPlayer();
  String? _loaded;
  bool _failed = false;
  bool _loading = false;

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
      setState(() => _loading = true);
      final path = await widget.loadPath();
      if (mounted) setState(() => _loading = false);
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
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
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
                onPressed: _failed || _loading ? null : _toggle,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
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
                          : widget.subtitle ??
                                '3-second clip from your microphone',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              if (widget.onInfo != null)
                IconButton(
                  onPressed: widget.onInfo,
                  icon: const Icon(Icons.info_outline_rounded),
                  tooltip: 'About this recording',
                ),
            ],
          );
        },
      ),
    );
  }
}
