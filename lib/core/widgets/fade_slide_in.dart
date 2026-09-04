import 'package:flutter/material.dart';

/// Entrance animation: fades in while easing up a few pixels. This is the
/// app's one animation primitive — sections, list rows, and grid cards all
/// use it with a small per-item delay so a screen feels like it arrives
/// rather than simply appears, without leaning on colour to read as
/// "creative".
///
/// Runs once, the moment this widget is first built — not on every rebuild —
/// so an unrelated state change (a provider tick, a filter change reusing the
/// same list slot) won't replay it.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting vertical offset in logical pixels; animates to 0.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
