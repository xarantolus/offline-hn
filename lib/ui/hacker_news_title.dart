import 'package:flutter/material.dart';

const _peach = Color(0xFFFFD2B3);

const _style = TextStyle(
  fontFamily: 'serif',
  fontSize: 23,
  fontWeight: FontWeight.w700,
  height: 1.1,
);

class HackerNewsTitle extends StatelessWidget {
  const HackerNewsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hacker News',
      excludeSemantics: true,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hacker ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'News',
                    style: TextStyle(color: _peach),
                  ),
                ],
              ),
              style: _style,
            ),
            SizedBox(width: 3),
            Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: SizedBox(
                width: 9,
                height: 20,
                child: ColoredBox(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
