import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_hn/app_name.dart';
import 'package:offline_hn/capture/capture_licenses.dart';
import 'package:offline_hn/pages/home_page.dart';
import 'package:offline_hn/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // targetSdk 35+ forces edge-to-edge; opting in keeps API 24-34 identical.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  registerCaptureLicenses();

  runApp(const OfflineHnApp());
}

class OfflineHnApp extends StatelessWidget {
  const OfflineHnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomePage(),
    );
  }
}
