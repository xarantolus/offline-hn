import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_hn/app_name.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/capture/capture_licenses.dart';
import 'package:offline_hn/pages/home_page.dart';
import 'package:offline_hn/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // targetSdk 35+ forces edge-to-edge; opting in keeps API 24-34 identical.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  registerCaptureLicenses();

  final services = await AppServices.open();
  runApp(OfflineHnApp(services: services));
  unawaited(services.start());
}

class OfflineHnApp extends StatefulWidget {
  const OfflineHnApp({required this.services, super.key});

  final AppServices services;

  @override
  State<OfflineHnApp> createState() => _OfflineHnAppState();
}

class _OfflineHnAppState extends State<OfflineHnApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(widget.services.sync.appResumed()),
      onHide: () => unawaited(widget.services.sync.appPaused()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: HomePage(services: widget.services),
    );
  }
}
