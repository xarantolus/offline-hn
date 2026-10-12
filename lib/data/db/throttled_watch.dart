import 'dart:async';

/// [fetch]'s result now, and again after [changes], but never more than once
/// per [interval]: changes inside the interval are answered together at its
/// end. A sync writes many times a second, and each answer is a query, a copy
/// across isolates and a rebuild of whatever shows it.
Stream<T> throttledWatch<T>(
  Stream<Object?> changes,
  Future<T> Function() fetch, {
  required Duration interval,
}) {
  late final StreamController<T> out;
  StreamSubscription<Object?>? subscription;
  Timer? cooldown;
  var dirty = false;
  var running = false;
  var closed = false;

  Future<void> run() async {
    dirty = false;
    running = true;
    cooldown = Timer(interval, () {
      cooldown = null;
      if (dirty && !running) unawaited(run());
    });
    try {
      final value = await fetch();
      if (!closed) out.add(value);
    } on Object catch (error, stack) {
      if (!closed) out.addError(error, stack);
    }
    running = false;
    if (dirty && cooldown == null && !closed) unawaited(run());
  }

  out = StreamController<T>(
    onListen: () {
      subscription = changes.listen((_) {
        dirty = true;
        if (cooldown == null && !running) unawaited(run());
      }, onError: out.addError);
      unawaited(run());
    },
    onCancel: () async {
      closed = true;
      cooldown?.cancel();
      await subscription?.cancel();
    },
  );
  return out.stream;
}
