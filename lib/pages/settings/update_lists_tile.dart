import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/sync/filter_list_update.dart';
import 'package:offline_hn/ui/tokens.dart';

class UpdateListsTile extends StatelessWidget {
  const UpdateListsTile({super.key, required this.services});

  final AppServices services;

  Future<void> _update(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await services.filterListUpdate.run();
    final text = switch (result) {
      ListUpdateResult.updated => 'Filter lists updated',
      ListUpdateResult.someFailed =>
        'Some lists could not be updated. The older copies are kept.',
      ListUpdateResult.noConnection =>
        'No connection. The lists were not updated.',
      ListUpdateResult.alreadyRunning => null,
    };
    if (text == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: services.filterListUpdate.running,
      builder: (context, running, _) => ListTile(
        title: Text('Update filter lists now', style: context.tokens.label),
        subtitle: running ? const LinearProgressIndicator() : null,
        trailing: const Icon(Icons.refresh),
        enabled: !running,
        onTap: () => _update(context),
      ),
    );
  }
}
