import 'package:flutter/material.dart';

/// Large circular start/stop control with pulsing rings while listening.
class ListenButton extends StatefulWidget {
  const ListenButton({
    super.key,
    required this.listening,
    required this.busy,
    required this.onPressed,
    this.level = 0,
  });

  final bool listening;
  final bool busy;
  final VoidCallback? onPressed;

  /// Current input level 0..1, used to swell the core slightly.
  final double level;

  @override
  State<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<ListenButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat();
  }

  @override
  void didUpdateWidget(ListenButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 168.0;
    final label = widget.listening ? 'Stop listening' : 'Start listening';
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: size + 56,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.listening)
                  for (final offset in const [0.0, 0.33, 0.66])
                    _Ring(t: (_pulse.value + offset) % 1, size: size),
                child!,
              ],
            );
          },
          child: AnimatedScale(
            scale: widget.listening ? 1 + widget.level * 0.06 : 1,
            duration: const Duration(milliseconds: 90),
            child: Material(
              shape: const CircleBorder(),
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black38,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.busy && !widget.listening
                    ? null
                    : widget.onPressed,
                child: SizedBox.square(
                  dimension: size,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: widget.busy && !widget.listening
                          ? const SizedBox.square(
                              key: ValueKey('busy'),
                              dimension: 40,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Column(
                              key: ValueKey(widget.listening),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.listening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  size: 56,
                                  color: widget.listening
                                      ? const Color(0xFFB4673F)
                                      : const Color(0xFF2F5D3A),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.listening
                                      ? 'Stop'
                                      : 'Start\nlistening',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: const Color(0xFF1E3F27),
                                        height: 1.1,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.t, required this.size});
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final d = size * (1 + 0.32 * Curves.easeOut.transform(t));
    return IgnorePointer(
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45 * (1 - t)),
            width: 2,
          ),
        ),
      ),
    );
  }
}
