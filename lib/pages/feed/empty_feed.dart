import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/ui/tokens.dart';

/// "Wi-Fi", "a charger" or both, for what automatic updates wait for.
String waitingFor(Set<AutomaticHold> holds) => [
  if (holds.contains(AutomaticHold.connection)) 'Wi-Fi',
  if (holds.contains(AutomaticHold.charger)) 'a charger',
].join(' and ');

/// What a feed shows when it has no stories. Nothing stored at all is an
/// ordinary state: the first update starts by itself, so the screen says it is
/// coming. When it waits for Wi-Fi or a charger there is a button.
class EmptyFeed extends StatefulWidget {
  const EmptyFeed({
    super.key,
    required this.services,
    required this.storeEmpty,
    required this.onFetch,
  });

  final AppServices services;
  final bool storeEmpty;
  final VoidCallback onFetch;

  @override
  State<EmptyFeed> createState() => _EmptyFeedState();
}

class _EmptyFeedState extends State<EmptyFeed> {
  late final Stream<SyncProgress?> _progress = widget.services.sync.progress;
  late final Stream<ConnectionKind> _connection =
      widget.services.sync.connection;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (!widget.storeEmpty) {
      return EmptyMessage(
        title: 'Nothing here for this day',
        hint: 'Pick another day, or another feed.',
        tokens: t,
      );
    }
    return StreamBuilder<SyncProgress?>(
      stream: _progress,
      builder: (context, progress) {
        if (progress.data != null) {
          return EmptyMessage(
            title: 'Fetching the first stories',
            hint: 'They appear here as they arrive.',
            tokens: t,
          );
        }
        return StreamBuilder<ConnectionKind>(
          stream: _connection,
          builder: (context, _) => FutureBuilder<Set<AutomaticHold>>(
            future: widget.services.sync.automaticHoldsNow(),
            builder: (context, holds) {
              final waiting = holds.data ?? const {};
              if (waiting.isEmpty) {
                return EmptyMessage(
                  title: 'Nothing downloaded yet',
                  hint: 'The first update starts by itself.',
                  tokens: t,
                );
              }
              return EmptyMessage(
                title: 'Nothing downloaded yet',
                hint:
                    'Automatic updates wait for ${waitingFor(waiting)}. You '
                    'can fetch the stories now.',
                tokens: t,
                action: FilledButton.tonal(
                  onPressed: widget.onFetch,
                  child: const Text('Fetch now'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.hint,
    required this.tokens,
    this.action,
  });

  final String title;
  final String hint;
  final AppTokens tokens;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: tokens.storyTitle, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.sm),
            Text(hint, style: tokens.hint, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: Spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
