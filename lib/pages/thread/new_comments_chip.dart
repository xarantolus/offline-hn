import 'package:flutter/material.dart';
import 'package:offline_hn/ui/format.dart';

class NewCommentsChip extends StatelessWidget {
  const NewCommentsChip({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const StadiumBorder(),
      color: Theme.of(context).colorScheme.primary,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${pluralize(count, 'new comment')} · tap to show',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
