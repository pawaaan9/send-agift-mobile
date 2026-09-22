import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds once a second with the time left until [target].
///
/// The server clock decides when a competition actually opens and closes;
/// this only shows the player how long is left. [onDone] fires once when the
/// countdown reaches zero, so the screen can ask the server for the new state.
class Countdown extends StatefulWidget {
  const Countdown({
    required this.target,
    required this.builder,
    this.onDone,
    super.key,
  });

  final DateTime target;
  final Widget Function(BuildContext context, Duration left) builder;
  final VoidCallback? onDone;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;
  bool _done = false;

  Duration get _left {
    final left = widget.target.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (_left == Duration.zero && !_done) {
      _done = true;
      widget.onDone?.call();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _left);
}
