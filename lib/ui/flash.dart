import 'package:flutter/material.dart';
import 'package:offline_hn/ui/tokens.dart';

const flashDuration = Duration(milliseconds: 1600);

/// Washes its child in the accent colour once, on mount, then fades back: the
/// mark that a link landed on this comment.
class Flash extends StatefulWidget {
  const Flash({super.key, required this.child});

  final Widget child;

  @override
  State<Flash> createState() => _FlashState();
}

class _FlashState extends State<Flash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: flashDuration,
  )..forward();

  /// Held for the first part so it is seen, then faded out.
  late final Animation<double> _fade = CurvedAnimation(
    parent: ReverseAnimation(_controller),
    curve: const Interval(0, 0.6, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wash = context.tokens.accentWash;
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) => ColoredBox(
        color: wash.withValues(alpha: wash.a * _fade.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
