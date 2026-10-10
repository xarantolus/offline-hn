import 'package:flutter/material.dart';
import 'package:offline_hn/app_name.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: const Center(child: Text('Nothing downloaded yet')),
    );
  }
}
