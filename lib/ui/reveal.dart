import 'package:flutter/material.dart';

const revealDuration = Duration(milliseconds: 220);
const revealCurve = Cubic(0.3, 0, 0, 1);

/// Opens and closes its child: the height closes while the content fades out
/// early, and on opening the content fades in over the later part. A child that
/// starts closed or open stays that way; [animateIn] opens it on mount.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.open,
    this.animateIn = false,
    required this.child,
  });

  final bool open;
  final bool animateIn;
  final Widget child;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: revealDuration,
    value: widget.open && !widget.animateIn ? 1 : 0,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.8, curve: revealCurve),
    reverseCurve: Curves.easeInOutCubic,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: Curves.easeOut),
    reverseCurve: const Interval(0.45, 1, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    if (widget.open && widget.animateIn) _controller.forward();
  }

  @override
  void didUpdateWidget(Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SizeTransition(
        sizeFactor: _size,
        alignment: AlignmentDirectional.topStart,
        child: widget.child,
      ),
    );
  }
}
