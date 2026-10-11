import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/sync/sync_controller.dart';
import 'package:offline_hn/ui/tokens.dart';

class UpdateListsTile extends StatelessWidget {
  const UpdateListsTile({super.key, required this.services});

  final AppServices services;

  Future<void> _update(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await services.sync.requestSync(SyncTrigger.filterLists);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result == SyncRequest.queued
                ? 'Updating filter lists'
                : 'No connection. The lists were not updated.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Update filter lists now', style: context.tokens.label),
      trailing: const Icon(Icons.refresh),
      onTap: () => _update(context),
    );
  }
}
