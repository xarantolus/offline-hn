import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offline_hn/app_name.dart';
import 'package:offline_hn/debug/design_gallery.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: const Center(child: Text('Nothing downloaded yet')),
    );
  }
}
