import 'package:flutter/material.dart';

/// A slider that follows the finger and reports the value once, on release.
class CommitSlider extends StatefulWidget {
  const CommitSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onCommit,
    this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) label;
  final ValueChanged<double> onCommit;
  final ValueChanged<double>? onChanged;

  @override
  State<CommitSlider> createState() => _CommitSliderState();
}

class _CommitSliderState extends State<CommitSlider> {
  double? _dragging;

  @override
  void didUpdateWidget(CommitSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _dragging = null;
  }

  @override
  Widget build(BuildContext context) {
    final value = _dragging ?? widget.value;
    return Slider(
      value: value.clamp(widget.min, widget.max),
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label(value),
      onChanged: (v) {
        setState(() => _dragging = v);
        widget.onChanged?.call(v);
      },
      onChangeEnd: (v) {
        widget.onCommit(v);
      },
    );
  }
}
