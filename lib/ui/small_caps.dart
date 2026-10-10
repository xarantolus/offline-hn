import 'package:flutter/material.dart';
import 'package:offline_hn/ui/tokens.dart';

class SmallCaps extends StatelessWidget {
  const SmallCaps(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.tokens.smallCaps;
    return Text(
      text.toUpperCase(),
      style: color == null ? style : style.copyWith(color: color),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
      child: SmallCaps(title, color: context.tokens.accent),
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.inset = 0});

  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Divider(height: 1, thickness: 1, color: context.tokens.hairline),
    );
  }
}
