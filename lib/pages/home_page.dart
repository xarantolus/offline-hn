import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offline_hn/app_name.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/debug/design_gallery.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.services, super.key});

  final AppServices services;

  void _openGallery(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const DesignGallery()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: kDebugMode
            ? GestureDetector(
                onLongPress: () => _openGallery(context),
                child: const Text(appName),
              )
            : const Text(appName),
      ),
      body: Center(child: _DebugStatus(services: services)),
      // TEMPORARY: manual sync trigger for emulator testing.
      floatingActionButton: FloatingActionButton(
        onPressed: () => services.sync.requestSync(SyncTrigger.manual),
        child: const Icon(Icons.sync),
      ),
    );
  }
}

// TEMPORARY: shows what the database streams report, for emulator testing.
class _DebugStatus extends StatelessWidget {
  const _DebugStatus({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder(
          stream: services.sync.progress,
          builder: (context, snapshot) {
            final p = snapshot.data;
            return Text(
              p == null
                  ? 'idle'
                  : 'run ${p.runId} ${p.phase.name} ${p.done}/${p.total}',
            );
          },
        ),
        StreamBuilder(
          stream: services.sync.lastSync,
          builder: (context, snapshot) => Text('last sync ${snapshot.data}'),
        ),
        StreamBuilder(
          stream: services.pages.watchTotalBytes(),
          builder: (context, snapshot) => Text('pages ${snapshot.data} bytes'),
        ),
      ],
    );
  }
}
