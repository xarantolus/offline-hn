import 'package:flutter/material.dart';

const revealDuration = Duration(milliseconds: 200);

/// Opens and closes its child with a size and fade transition. A child that
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
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
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
      opacity: _curve,
      child: SizeTransition(
        sizeFactor: _curve,
        alignment: AlignmentDirectional.topStart,
        child: widget.child,
      ),
    );
  }
}
